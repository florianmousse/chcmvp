import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { getClubSettings, notifyMembers } from "./notify";
import { computeMatchTally, Tally } from "./matchTally";
import { seasonId } from "./season";

const zero: Tally = { points: 0, firstCount: 0, secondCount: 0, thirdCount: 0 };

/**
 * Sur Cloud Functions, `onDocumentUpdated` donne directement before/after.
 * Sur un onSnapshot classique, il faut reconstituer soi-même la transition
 * en gardant le dernier statut connu de chaque match en mémoire. C'est
 * possible ici parce que ce process tourne en continu sur le VPS (contrairement
 * à une fonction serverless qui redémarre à froid) — le cache reste cohérent
 * tant que le serveur ne redémarre pas. Au redémarrage, le premier instantané
 * sert uniquement à initialiser le cache (voir `isFirstSnapshot`), pour ne pas
 * redéclencher des notifications sur des matchs déjà traités auparavant.
 */
export function startMatchListeners(): void {
  const firestore = getFirestore();
  const lastKnownStatus = new Map<string, string>();
  let isFirstSnapshot = true;

  firestore.collection("matches").onSnapshot(
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
          handleVotingClosed(matchId, after).catch((e) =>
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

async function handleVotingOpened(
  matchId: string,
  match: FirebaseFirestore.DocumentData,
): Promise<void> {
  const matchRef = getFirestore().collection("matches").doc(matchId);
  const settings = await getClubSettings();

  if (!match.votingClosesAt) {
    const opensAt = Timestamp.now();
    const closesAt = Timestamp.fromMillis(
      opensAt.toMillis() + settings.voteDurationHours * 3600 * 1000,
    );
    await matchRef.update({
      votingOpensAt: opensAt,
      votingClosesAt: closesAt,
      reminderSentAt: null,
    });
  }

  const presentPlayerIds: string[] = match.presentPlayerIds ?? [];

  await notifyMembers({
    title: "Vote ouvert !",
    body: `Le match contre ${match.opponent ?? "l'adversaire"} est terminé. Vote dès maintenant pour les 3 meilleurs joueurs !`,
    team: match.team,
    onlyUids: presentPlayerIds.length > 0 ? presentPlayerIds : undefined,
    data: { type: "voting_open", matchId },
  });

  console.log(`Vote ouvert et notification envoyée pour le match ${matchId}`);
}

export async function handleVotingClosed(
  matchId: string,
  match: FirebaseFirestore.DocumentData,
): Promise<void> {
  const firestore = getFirestore();
  const matchRef = firestore.collection("matches").doc(matchId);

  const votesSnap = await matchRef.collection("votes").get();
  const scale = match.pointsScale ?? { first: 5, second: 3, third: 1 };
  const votes = votesSnap.docs.map((v) => v.data() as any);
  const { entries, mvpUids, totalVotes } = computeMatchTally(votes, scale);

  // Calcul du nombre de votants distincts par joueur
  const voterSets: Record<string, Set<string>> = {};
  for (const doc of votesSnap.docs) {
    const vote = doc.data();
    const voterUid = vote.voterUid ?? doc.id;
    for (const place of [vote.firstPlaceUid, vote.secondPlaceUid, vote.thirdPlaceUid]) {
      if (place) {
        if (!voterSets[place]) voterSets[place] = new Set<string>();
        voterSets[place].add(voterUid);
      }
    }
  }
  const distinctVotersMap: Record<string, number> = {};
  for (const [uid, set] of Object.entries(voterSets)) {
    distinctVotersMap[uid] = set.size;
  }

  const presentPlayerIds: string[] = match.presentPlayerIds ?? [];
  const voteRate = presentPlayerIds.length > 0
    ? Math.round((totalVotes / presentPlayerIds.length) * 100)
    : 0;

  const resultsRef = matchRef.collection("results").doc("summary");

  // Idempotence : si ce match avait déjà été calculé une première fois (ex:
  // recalcul manuel en rouvrant/refermant le vote), on ne veut incrémenter
  // rankings_cache/player_stats que de la DIFFÉRENCE avec le calcul
  // précédent — jamais réappliquer le total en entier une deuxième fois.
  // results/summary lui-même est un set() sans merge (réécriture complète à
  // chaque fois), donc toujours fiable comme référence de "ce qui a déjà été
  // compté avant" ; c'est justement pour ça qu'il restait juste alors que
  // rankings_cache dérivait au fil des recalculs.
  const previousSnap = await resultsRef.get();
  const prevData = previousSnap.data();
  const previousEntries = (prevData?.entries ?? {}) as Record<string, Tally>;
  const previousDistinctVotersMap = (prevData?.distinctVotersMap ?? {}) as Record<string, number>;
  const alreadyComputedBefore = previousSnap.exists;

  await resultsRef.set({
    entries,
    mvpUids,
    totalVotes,
    voteRate,
    distinctVotersMap,
    computedAt: Timestamp.now(),
  });

  const allUids = new Set([
    ...Object.keys(entries),
    ...Object.keys(previousEntries),
    ...Object.keys(distinctVotersMap),
    ...Object.keys(previousDistinctVotersMap),
  ]);
  const deltas = new Map<string, Tally>();
  for (const uid of allUids) {
    const now = entries[uid] ?? zero;
    const prev = previousEntries[uid] ?? zero;
    deltas.set(uid, {
      points: now.points - prev.points,
      firstCount: now.firstCount - prev.firstCount,
      secondCount: now.secondCount - prev.secondCount,
      thirdCount: now.thirdCount - prev.thirdCount,
    });
  }

  const matchDate: Timestamp = match.date;
  const year = matchDate.toDate().getUTCFullYear();
  const month = matchDate.toDate().getUTCMonth() + 1;
  const monthKey = `${year}-${String(month).padStart(2, "0")}`;
  const season = seasonId(matchDate.toDate());

  const batch = firestore.batch();

  for (const scopeId of ["general", season, monthKey]) {
    const ref = firestore.collection("rankings_cache").doc(scopeId);
    const entriesUpdate: Record<
      string,
      Record<string, FirebaseFirestore.FieldValue>
    > = {};
    for (const [uid, d] of deltas) {
      if (
        d.points === 0 &&
        d.firstCount === 0 &&
        d.secondCount === 0 &&
        d.thirdCount === 0
      )
        continue;
      entriesUpdate[uid] = {
        points: FieldValue.increment(d.points),
        firstCount: FieldValue.increment(d.firstCount),
        secondCount: FieldValue.increment(d.secondCount),
        thirdCount: FieldValue.increment(d.thirdCount),
      };
    }
    // Objet réellement imbriqué (et non des clés à points comme
    // "entries.uid.points") : avec set(), contrairement à update(), les clés
    // à points ne sont PAS interprétées comme des chemins imbriqués — elles
    // créent un champ littéral nommé "entries.uid.points" au lieu de la
    // structure entries -> uid -> champ attendue. merge:true sur un objet
    // imbriqué fusionne correctement sans écraser les autres joueurs déjà
    // présents dans entries.
    if (Object.keys(entriesUpdate).length > 0) {
      batch.set(ref, { entries: entriesUpdate }, { merge: true });
    }
  }

  for (const uid of presentPlayerIds) {
    const d = deltas.get(uid) ?? zero;
    const currentDistinct = distinctVotersMap[uid] ?? 0;
    const prevDistinct = previousDistinctVotersMap[uid] ?? 0;
    const distinctDelta = currentDistinct - prevDistinct;

    const statsRef = firestore.collection("player_stats").doc(uid);
    batch.set(
      statsRef,
      {
        // matchesPlayed ne doit être compté qu'une seule fois par match,
        // jamais à chaque recalcul — d'où le +1 conditionné à "première fois".
        matchesPlayed: FieldValue.increment(alreadyComputedBefore ? 0 : 1),
        totalPoints: FieldValue.increment(d.points),
        votesReceived: FieldValue.increment(
          d.firstCount + d.secondCount + d.thirdCount,
        ),
        distinctVoters: FieldValue.increment(distinctDelta),
        firstCount: FieldValue.increment(d.firstCount),
        secondCount: FieldValue.increment(d.secondCount),
        thirdCount: FieldValue.increment(d.thirdCount),
      },
      { merge: true },
    );
    // L'historique reflète le résultat réel du joueur pour CE match (pas la
    // différence) — c'est un set() sans merge, un doc par match, déjà
    // naturellement idempotent en soi.
    const matchTally = entries[uid] ?? zero;
    batch.set(statsRef.collection("history").doc(matchId), {
      matchId,
      matchDate,
      points: matchTally.points,
      distinctVotersThisMatch: currentDistinct,
      presentCount: presentPlayerIds.length,
      rank:
        matchTally.firstCount > 0
          ? 1
          : matchTally.secondCount > 0
            ? 2
            : matchTally.thirdCount > 0
              ? 3
              : null,
    });
  }

  await batch.commit();

  // ── Notification de clôture ──
  const membersSnap = await firestore
    .collection("users")
    .where("isActive", "==", true)
    .get();
  const nameOf: Record<string, string> = {};
  membersSnap.forEach((doc) => {
    const d = doc.data();
    nameOf[doc.id] = `${d.firstName ?? ""} ${d.lastName ?? ""}`.trim() || "Joueur";
  });
  const mvpNames = mvpUids.map((uid: string) => nameOf[uid] ?? "Joueur inconnu").join(", ");
  const notifBody = mvpUids.length > 0
    ? `Le classement a été mis à jour. MVP : ${mvpNames} 🏆`
    : "Le classement a été mis à jour.";

  await notifyMembers({
    title: "Vote clôturé ✅",
    body: notifBody,
    team: match.team,
    onlyUids: presentPlayerIds.length > 0 ? presentPlayerIds : undefined,
    data: { type: "voting_closed", matchId },
  });

  console.log(
    `Résultats calculés pour le match ${matchId} (${totalVotes} votes, MVP: ${mvpUids.join(", ") || "aucun"})`,
  );
}
