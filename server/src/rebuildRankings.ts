import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { computeMatchTally, Tally } from "./matchTally";
import { seasonId } from "./season";

const zero: Tally = { points: 0, firstCount: 0, secondCount: 0, thirdCount: 0 };

/**
 * Reconstruit entièrement rankings_cache et player_stats en recalculant
 * chaque match clôturé DIRECTEMENT à partir de ses votes bruts (même calcul
 * que handleVotingClosed, via computeMatchTally) — pas depuis les
 * results/summary existants. Ça rend cette fonction totalement autonome :
 * peu importe l'état actuel des documents (vides, corrompus, calculés avec
 * une ancienne version du code...), le résultat final ne dépend que des
 * votes réellement enregistrés, la seule vraie source de vérité.
 *
 * Réécrit aussi results/summary au passage, pour que le détail par match
 * affiché dans l'app reste cohérent avec ce qui vient d'être recalculé ici.
 *
 * Écrase entièrement les documents concernés (pas de merge/increment) :
 * volontaire, on reconstruit un état propre plutôt que d'accumuler par-dessus
 * l'existant.
 */
export async function rebuildRankingsAndStats(): Promise<{
  matchesProcessed: number;
}> {
  const firestore = getFirestore();
  const matchesSnap = await firestore
    .collection("matches")
    .where("status", "==", "voting_closed")
    .get();

  const rankingTotals: Record<string, Record<string, Tally>> = {};
  const playerStatsTotals: Record<
    string,
    Tally & { matchesPlayed: number; votesReceived: number; distinctVoters: number }
  > = {};
  const historyEntries: {
    uid: string;
    matchId: string;
    matchDate: Timestamp;
    points: number;
    distinctVotersThisMatch: number;
    presentCount: number;
    rank: number | null;
  }[] = [];

  let matchesProcessed = 0;

  for (const matchDoc of matchesSnap.docs) {
    const match = matchDoc.data();
    const votesSnap = await matchDoc.ref.collection("votes").get();
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

    matchesProcessed++;

    await matchDoc.ref.collection("results").doc("summary").set({
      entries,
      mvpUids,
      totalVotes,
      voteRate,
      distinctVotersMap,
      computedAt: Timestamp.now(),
    });

    const matchDate: Timestamp = match.date;
    const year = matchDate.toDate().getUTCFullYear();
    const month = matchDate.toDate().getUTCMonth() + 1;
    const monthKey = `${year}-${String(month).padStart(2, "0")}`;
    const season = seasonId(matchDate.toDate());

    for (const scopeId of ["general", season, monthKey]) {
      rankingTotals[scopeId] ??= {};
      for (const [uid, t] of Object.entries(entries)) {
        const c = rankingTotals[scopeId][uid] ?? zero;
        rankingTotals[scopeId][uid] = {
          points: c.points + t.points,
          firstCount: c.firstCount + t.firstCount,
          secondCount: c.secondCount + t.secondCount,
          thirdCount: c.thirdCount + t.thirdCount,
        };
      }
    }

    for (const uid of presentPlayerIds) {
      const t = entries[uid] ?? zero;
      const c = playerStatsTotals[uid] ?? {
        ...zero,
        matchesPlayed: 0,
        votesReceived: 0,
        distinctVoters: 0,
      };
      const currentDistinct = distinctVotersMap[uid] ?? 0;
      playerStatsTotals[uid] = {
        matchesPlayed: c.matchesPlayed + 1,
        points: c.points + t.points,
        votesReceived:
          c.votesReceived + t.firstCount + t.secondCount + t.thirdCount,
        distinctVoters: c.distinctVoters + currentDistinct,
        firstCount: c.firstCount + t.firstCount,
        secondCount: c.secondCount + t.secondCount,
        thirdCount: c.thirdCount + t.thirdCount,
      };
      historyEntries.push({
        uid,
        matchId: matchDoc.id,
        matchDate,
        points: t.points,
        distinctVotersThisMatch: currentDistinct,
        presentCount: presentPlayerIds.length,
        rank:
          t.firstCount > 0
            ? 1
            : t.secondCount > 0
              ? 2
              : t.thirdCount > 0
                ? 3
                : null,
      });
    }
  }

  const batch = firestore.batch();
  for (const [scopeId, entries] of Object.entries(rankingTotals)) {
    batch.set(firestore.collection("rankings_cache").doc(scopeId), { entries });
  }
  for (const [uid, stats] of Object.entries(playerStatsTotals)) {
    batch.set(firestore.collection("player_stats").doc(uid), {
      matchesPlayed: stats.matchesPlayed,
      totalPoints: stats.points,
      votesReceived: stats.votesReceived,
      distinctVoters: stats.distinctVoters,
      firstCount: stats.firstCount,
      secondCount: stats.secondCount,
      thirdCount: stats.thirdCount,
    });
  }
  await batch.commit();

  const historyBatch = firestore.batch();
  for (const h of historyEntries) {
    historyBatch.set(
      firestore
        .collection("player_stats")
        .doc(h.uid)
        .collection("history")
        .doc(h.matchId),
      {
        matchId: h.matchId,
        matchDate: h.matchDate,
        points: h.points,
        distinctVotersThisMatch: h.distinctVotersThisMatch,
        presentCount: h.presentCount,
        rank: h.rank,
      },
    );
  }
  await historyBatch.commit();

  return { matchesProcessed };
}
