import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { getClubSettings, notifyMembers, notifyAdmins } from "./notify";

/**
 * Combine un Timestamp Firestore (date du match, ex: 2026-09-15 00:00:00) et
 * une chaîne d'heure au format "HH:mm" pour obtenir le timestamp exact du
 * début du match. La date Firestore est stockée à minuit UTC ; l'heure est
 * en heure locale (Europe/Paris). On la combine directement.
 */
function matchDateTime(dateTs: Timestamp, time: string): number {
  const d = dateTs.toDate();
  const [h, m] = time.split(":").map(Number);
  d.setHours(h, m, 0, 0);
  return d.getTime();
}

/**
 * Traitement périodique (cron toutes les 10 min) qui gère le cycle de vie
 * automatique des votes :
 *
 * 1. **Rappel admin** — si un match `upcoming` est dans moins de Xh et que
 *    la feuille de présence est vide → notification aux admins.
 * 2. **Auto-ouverture** — si un match `upcoming` a commencé depuis ≥ 2h et
 *    que la feuille de présence est remplie → passe à `voting_open`.
 * 3. **Rappel joueurs** — si un vote est ouvert et qu'il reste ≤ 24h avant
 *    la clôture → rappel aux joueurs qui n'ont pas encore voté.
 * 4. **Auto-clôture** — si `votingClosesAt` est passé → passe à `voting_closed`.
 */
export async function processScheduledVoting(): Promise<void> {
  const firestore = getFirestore();
  const settings = await getClubSettings();
  const now = Timestamp.now();
  const nowMs = now.toMillis();

  // ────────────────────────────────────────────────────────────────────────
  // Phase 1 & 2 : matchs « upcoming » → rappel admin + auto-ouverture
  // ────────────────────────────────────────────────────────────────────────
  const upcomingSnap = await firestore
    .collection("matches")
    .where("status", "==", "upcoming")
    .get();

  for (const doc of upcomingSnap.docs) {
    const match = doc.data();
    const dateTs: Timestamp | undefined = match.date;
    const time: string | undefined = match.time;
    if (!dateTs || !time) continue;

    const matchMs = matchDateTime(dateTs, time);
    const presentIds: string[] = match.presentPlayerIds ?? [];

    // ── Phase 1 : Rappel admin si feuille de présence vide ──
    // Envoyé quand on est à moins de adminReminderBeforeHours du match
    // ET que les joueurs présents n'ont pas encore été saisis.
    const reminderThresholdMs = matchMs - settings.adminReminderBeforeHours * 3600 * 1000;
    if (
      presentIds.length === 0 &&
      nowMs >= reminderThresholdMs &&
      nowMs < matchMs + settings.voteOpenDelayHours * 3600 * 1000 &&
      !match.adminReminderSentAt
    ) {
      await notifyAdmins({
        title: "📋 Feuille de présence à remplir !",
        body: `Le match contre ${match.opponent ?? "l'adversaire"} approche. Remplis la feuille de présence pour que le vote puisse s'ouvrir automatiquement.`,
        data: { type: "admin_presence_reminder", matchId: doc.id },
      });
      await doc.ref.update({ adminReminderSentAt: now });
      console.log(`Rappel admin envoyé pour le match ${doc.id} (feuille de présence vide)`);
      continue; // pas d'ouverture de vote si pas de présence
    }

    // ── Phase 2 : Auto-ouverture du vote ──
    // Le match a commencé depuis au moins voteOpenDelayHours ET la feuille
    // de présence est renseignée → on passe le statut à voting_open.
    // Le listener matchListeners.ts détecte la transition et envoie la notif.
    const voteOpenThresholdMs = matchMs + settings.voteOpenDelayHours * 3600 * 1000;
    if (presentIds.length > 0 && nowMs >= voteOpenThresholdMs) {
      const closesAt = Timestamp.fromMillis(
        voteOpenThresholdMs + settings.voteDurationHours * 3600 * 1000,
      );
      await doc.ref.update({
        status: "voting_open",
        votingOpensAt: Timestamp.fromMillis(voteOpenThresholdMs),
        votingClosesAt: closesAt,
        reminderSentAt: null,
      });
      console.log(`Vote ouvert automatiquement pour le match ${doc.id}`);
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // Phase 3 & 4 : matchs « voting_open » → rappel joueurs + auto-clôture
  // ────────────────────────────────────────────────────────────────────────
  const openMatchesSnap = await firestore
    .collection("matches")
    .where("status", "==", "voting_open")
    .get();

  for (const doc of openMatchesSnap.docs) {
    const match = doc.data();
    const closesAt: Timestamp | undefined = match.votingClosesAt;
    if (!closesAt) continue;

    // ── Phase 4 : Auto-clôture ──
    if (closesAt.toMillis() <= nowMs) {
      // Ce write déclenche le listener de matchListeners.ts (transition vers
      // "voting_closed"), qui calcule les résultats et envoie la notification
      // de clôture — pas besoin de dupliquer cette logique ici.
      await doc.ref.update({ status: "voting_closed" });
      console.log(`Vote clôturé automatiquement pour le match ${doc.id}`);
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

async function sendReminderToNonVoters(
  matchId: string,
  match: FirebaseFirestore.DocumentData,
): Promise<void> {
  const firestore = getFirestore();
  const votesSnap = await firestore
    .collection(`matches/${matchId}/votes`)
    .get();
  const votedUids = votesSnap.docs.map((d) => d.id);
  const presentPlayerIds: string[] = match.presentPlayerIds ?? [];

  await notifyMembers({
    title: "N'oublie pas de voter ! ⏰",
    body: `Il te reste moins de 24h pour voter pour les 3 meilleurs joueurs contre ${match.opponent ?? "l'adversaire"}.`,
    team: match.team,
    excludeUids: votedUids,
    onlyUids: presentPlayerIds.length > 0 ? presentPlayerIds : undefined,
    data: { type: "voting_reminder", matchId },
  });

  console.log(
    `Rappel envoyé pour le match ${matchId} (${votedUids.length} ont déjà voté)`,
  );
}
