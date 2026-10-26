import { votingOpenedNotification, votingClosedNotification } from "./matchNotifications";
import { getFirestore } from "firebase-admin/firestore";
import { initializeVotingWindow } from "./votingLifecycle";
import { getClubSettings, notifyMembers } from "./notify";
import { rebuildRankingsAndStats, recomputeClosedMatch } from "./rebuildRankings";

/**
 * Sur Cloud Functions, `onDocumentUpdated` donne directement before/after.
 * Sur un onSnapshot classique, il faut reconstituer soi-même la transition
 * en gardant le dernier statut connu de chaque match en mémoire. C'est
 * possible ici parce que ce process tourne en continu sur le VPS (contrairement
 * à une fonction serverless qui redémarre à froid) - le cache reste cohérent
 * tant que le serveur ne redémarre pas. Au redémarrage, le premier instantané
 * sert uniquement à initialiser le cache (voir `isFirstSnapshot`), pour ne pas
 * redéclencher des notifications sur des matchs déjà traités auparavant.
 */
export function startMatchListeners(): void {
  const firestore = getFirestore();
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
          console.log(
            `Listener matchs initialisé (${snapshot.size} matchs en cache).`,
          );
          return;
        }

        snapshot.docChanges().forEach((change) => {
          if (change.type === "removed") {
            lastKnownStatus.delete(change.doc.id);
            if (collection === "matches") rebuildRankingsAndStats().catch((e) =>
              console.error("Erreur nettoyage après suppression:", e),
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
              console.error(`Erreur handleVotingOpened(${matchId}):`, e),
            );
          }
          if (before !== "voting_closed" && after.status === "voting_closed") {
            handleVotingClosed(matchId, after, true).catch((e) =>
              console.error(`Erreur handleVotingClosed(${matchId}):`, e),
            );
          }
        });
      },
      (error) => {
        // firebase-admin réessaie automatiquement la connexion en cas de coupure
        // réseau ; on journalise simplement pour visibilité (voir `pm2 logs` / `journalctl`).
        console.error("Erreur du listener matches :", error);
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

  console.log(`Vote ouvert et notification envoyée pour le match ${matchId}`);
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

  console.log(
    `Résultats calculés pour le match ${matchId} (${totalVotes} votes, MVP: ${mvpUids.join(", ") || "aucun"})`,
  );
}
