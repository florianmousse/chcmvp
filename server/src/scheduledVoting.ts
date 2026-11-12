import { getFirestore } from "./database";
import { auditChange } from "./audit";
import { matchReference } from "./matchReference";
import { Timestamp } from "firebase-admin/firestore";
import { getClubSettings, notifyMembers, notifyAdmins } from "./notify";
import { closeExpiredVoting, remindReopenedVoting } from "./votingLifecycle";

import { matchDateTime } from './matchTime';
import { reconcileMatches } from './matchRecovery';
import { logEvent } from './logger';

/**
 * Traitement périodique (cron toutes les 10 min) qui gère le cycle de vie
 * automatique des votes :
 *
 * 1. **Rappel admin** - si un match `upcoming` est dans moins de Xh et que
 *    la feuille de présence est vide → notification aux admins.
 * 2. **Auto-ouverture** - si un match `upcoming` a commencé depuis ≥ 2h et
 *    que la feuille de présence est remplie → passe à `voting_open`.
 * 3. **Rappel joueurs** - si un vote est ouvert et qu'il reste ≤ 24h avant
 *    la clôture → rappel aux joueurs qui n'ont pas encore voté.
 * 4. **Auto-clôture** - si `votingClosesAt` est passé → passe à `voting_closed`.
 */
export async function processScheduledVoting(): Promise<void> {
  const firestore = getFirestore();
  const settings = await getClubSettings();
  await reconcileMatches(settings.voteDurationHours, firestore);
  const now = Timestamp.now();
  const nowMs = now.toMillis();

  for (const collection of ["matches", "test_matches"]) {
    // ────────────────────────────────────────────────────────────────────────
    // Phase 1 & 2 : matchs « upcoming » → rappel admin + auto-ouverture
    // ────────────────────────────────────────────────────────────────────────
    const upcomingSnap = await firestore
      .collection(collection)
      .where("status", "==", "upcoming")
      .get();

    for (const doc of upcomingSnap.docs) {
      const match = doc.data();
      const dateTs: Timestamp | undefined = match.date;
      const time: string | undefined = match.time;
      if (!dateTs || !time) continue;

      let matchMs: number;
      try { matchMs = matchDateTime(dateTs, time, match.civilDate); }
      catch {
        logEvent('error', 'vote.calendrier', 'Date ou heure invalide ; corriger le match avant ouverture.', { matchId: doc.id });
        continue;
      }
      const presentIds: string[] = match.presentPlayerIds ?? [];

      // ── Phase 1 : Rappel admin si feuille de présence vide ──
      // Envoyé quand on est à moins de adminReminderBeforeHours du match
      // ET que les joueurs présents n'ont pas encore été saisis.
      const reminderThresholdMs =
        matchMs - settings.adminReminderBeforeHours * 3600 * 1000;
      if (
        presentIds.length === 0 &&
        nowMs >= reminderThresholdMs &&
        nowMs < matchMs + settings.voteOpenDelayHours * 3600 * 1000 &&
        !match.adminReminderSentAt
      ) {
        await notifyAdmins({
          title: `${collection === "test_matches" ? "[TEST] " : ""}📋 Feuille de présence à remplir !`,
          body: `Le match contre ${match.opponent ?? "l'adversaire"} approche. Remplis la feuille de présence pour que le vote puisse s'ouvrir automatiquement.`,
          data: { type: "admin_presence_reminder", matchId: doc.id },
        });
        await doc.ref.update({ adminReminderSentAt: now });
        logEvent('info', 'vote.presences', 'Rappel de feuille de présence traité.', { matchId: doc.id });
        continue; // pas d'ouverture de vote si pas de présence
      }

      // ── Phase 2 : Auto-ouverture du vote ──
      // Le match a commencé depuis au moins voteOpenDelayHours ET la feuille
      // de présence est renseignée → on passe le statut à voting_open.
      // Le listener matchListeners.ts détecte la transition et envoie la notif.
      const voteOpenThresholdMs =
        matchMs + settings.voteOpenDelayHours * 3600 * 1000;
      if (presentIds.length >= 3 && nowMs >= voteOpenThresholdMs) {
        await firestore.runTransaction(async (tx) => {
          const current = (await tx.get(doc.ref)).data();
          if (!current || current.status !== "upcoming" || current.manualCloseRequired) return;
          if (!Array.isArray(current.presentPlayerIds) || new Set(current.presentPlayerIds).size < 3) return;
          const currentOpenMs = matchDateTime(current.date, current.time, current.civilDate) + settings.voteOpenDelayHours * 3600000;
          if (nowMs < currentOpenMs) return;
          auditChange(tx, firestore, 'system', { firstName: 'Cycle automatique' }, 'open_voting', doc.ref.path,
            { status: current.status }, { status: 'voting_open' });
          tx.update(doc.ref, {
            status: "voting_open",
            votingOpensAt: Timestamp.fromMillis(currentOpenMs),
            votingClosesAt: Timestamp.fromMillis(currentOpenMs + settings.voteDurationHours * 3600000),
            reminderSentAt: null,
          });
        });
        logEvent('info', 'vote.cycle', "Traitement automatique de l'ouverture terminé.", { matchId: doc.id });
      }
    }

    // ────────────────────────────────────────────────────────────────────────
    // Phase 3 & 4 : matchs « voting_open » → rappel joueurs + auto-clôture
    // ────────────────────────────────────────────────────────────────────────
    const openMatchesSnap = await firestore
      .collection(collection)
      .where("status", "==", "voting_open")
      .get();

    for (const doc of openMatchesSnap.docs) {
      const match = doc.data();
      if (match.manualCloseRequired === true) {
        await remindReopenedVoting(doc.id, now, notifyAdmins, firestore);
        continue;
      }
      const closesAt: Timestamp | undefined = match.votingClosesAt;
      if (!closesAt) continue;

      // ── Phase 4 : Auto-clôture ──
      if (closesAt.toMillis() <= nowMs) {
        // Ce write déclenche le listener de matchListeners.ts (transition vers
        // "voting_closed"), qui calcule les résultats et envoie la notification
        // de clôture - pas besoin de dupliquer cette logique ici.
        if (await closeExpiredVoting(doc.id, now, firestore)) {
          logEvent('info', 'vote.cloture', 'Échéance atteinte ; vote clôturé.', { matchId: doc.id });
        }
        continue;
      }

      // ── Phase 3 : Rappel aux non-votants ──
      const reminderThreshold =
        closesAt.toMillis() - settings.reminderBeforeHours * 3600 * 1000;
      const reminderAlreadySent = !!match.reminderSentAt;
      if (!reminderAlreadySent && nowMs >= reminderThreshold) {
        await sendReminderToNonVoters(doc.id, match);
        await doc.ref.update({ reminderSentAt: now });
      }
    }
  }
}

export async function sendReminderToNonVoters(
  matchId: string,
  match: FirebaseFirestore.DocumentData,
): Promise<void> {
  const presentPlayerIds: string[] = match.presentPlayerIds ?? [];
  if (presentPlayerIds.length === 0) return;
  const firestore = getFirestore();
  const votesSnap = await matchReference(matchId, firestore).collection("votes").get();
  const votedUids = votesSnap.docs.map((d) => d.id);

  await notifyMembers({
    adminsOnly: matchId.startsWith("test:"),
    title: "N'oublie pas de voter ! ⏰",
    body: `Il te reste moins de 24h pour voter pour les 3 meilleurs joueurs contre ${match.opponent ?? "l'adversaire"}.`,
    team: match.team,
    excludeUids: votedUids,
    onlyUids: presentPlayerIds,
    data: { type: "voting_reminder", matchId },
  });

  logEvent('info', 'vote.rappel', 'Rappel aux non-votants traité.', { matchId, count: votedUids.length });
}
