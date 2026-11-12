import { reconcileMatches } from './matchRecovery';
import { logEvent } from './logger';
import { getFirestore } from "./database";
import { votingOpenedNotification, votingClosedNotification } from "./matchNotifications";

import { initializeVotingWindow } from "./votingLifecycle";
import { getClubSettings, notifyMembers } from "./notify";
import { rebuildRankingsAndStats, recomputeClosedMatch } from "./rebuildRankings";

/** Notifications only follow live transitions. Durable fingerprints and the
 * periodic reconciliation repair data independently, without replaying alerts. */
export function startMatchListeners(): void {
  const firestore = getFirestore();
  void getClubSettings().then(settings => reconcileMatches(settings.voteDurationHours, firestore))
    .catch(() => logEvent('error', 'vote.demarrage', 'Réconciliation indisponible ; reprise au prochain cycle.'));
  for (const collection of ["matches", "test_matches"]) {
    const lastKnownStatus = new Map<string, string>();
    let isFirstSnapshot = true;

    firestore.collection(collection).onSnapshot(
      (snapshot) => {
        if (isFirstSnapshot) {
          snapshot.forEach((doc) =>
            lastKnownStatus.set(doc.id, doc.data().status),
          );
          isFirstSnapshot = false;
          logEvent('info', 'vote.ecoute', 'Écoute des matchs prête.', { collection, count: snapshot.size });
          return;
        }

        snapshot.docChanges().forEach((change) => {
          if (change.type === "removed") {
            lastKnownStatus.delete(change.doc.id);
            if (collection === "matches") rebuildRankingsAndStats().catch((e) =>
              logEvent('error', 'vote.suppression', 'Recalcul après suppression échoué.'),
            );
            return;
          }

          const matchId = change.doc.id;
          const after = change.doc.data();
          const before = lastKnownStatus.get(matchId);
          lastKnownStatus.set(matchId, after.status);

          if (before === after.status) return; // pas un changement de statut, on ignore

          if (before !== "voting_open" && after.status === "voting_open") {
            handleVotingOpened(matchId, after).catch((e) =>
              logEvent('error', 'vote.ouverture', 'Ouverture incomplète ; vérifier la reprise automatique.', { matchId }),
            );
          }
          if (before !== "voting_closed" && after.status === "voting_closed") {
            handleVotingClosed(matchId, after, true).catch((e) =>
              logEvent('error', 'vote.cloture', 'Clôture incomplète ; résultats repris au prochain cycle, notification non rejouée.', { matchId }),
            );
          }
        });
      },
      (error) => {
        // firebase-admin réessaie automatiquement la connexion en cas de coupure
        // réseau ; on journalise simplement pour visibilité (voir `pm2 logs` / `journalctl`).
        logEvent('error', 'vote.ecoute', 'Écoute interrompue ; vérifier la connexion Firestore.', { collection });
      },
    );
  }
}

async function handleVotingOpened(
  matchId: string,
  match: FirebaseFirestore.DocumentData,
): Promise<void> {
  const settings = await getClubSettings();
  const current = await initializeVotingWindow(matchId, settings.voteDurationHours);
  if (!current) return;
  match = current;

  await notifyMembers(await votingOpenedNotification(matchId, match));

  logEvent('info', 'vote.ouverture', 'Vote ouvert ; demande de notification traitée.', { matchId });
}

export async function handleVotingClosed(
  matchId: string,
  match: FirebaseFirestore.DocumentData,
  notify = false,
): Promise<void> {
  const firestore = getFirestore();
  // Re-read under the same lock as deletion; never resurrect an old snapshot.
  const computed = await recomputeClosedMatch(matchId, firestore);
  if (!computed || !notify) return;
  match = computed.match;
  const { mvpUids, totalVotes } = computed.summary;

  // ── Notification de clôture ──
  const membersSnap = await firestore
    .collection("users")
    .where("isActive", "==", true)
    .get();
  const nameOf: Record<string, string> = {};
  membersSnap.forEach((doc) => {
    const d = doc.data();
    nameOf[doc.id] =
      `${d.firstName ?? ""} ${d.lastName ?? ""}`.trim() || "Joueur";
  });
  const mvpNames = mvpUids
    .map((uid: string) => nameOf[uid] ?? "Joueur inconnu")
    .join(", ");
  await notifyMembers(votingClosedNotification(matchId, match, mvpNames));

  logEvent('info', 'vote.cloture', 'Résultats calculés ; demande de notification traitée.', { matchId, count: totalVotes });
}
