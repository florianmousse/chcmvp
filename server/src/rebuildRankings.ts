import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { computeMatchTally, Tally } from "./matchTally";
import { monthId, seasonId } from "./season";
import { withRankingLock } from "./rankingLock";

const zero: Tally = { points: 0, firstCount: 0, secondCount: 0, thirdCount: 0 };

/**
 * Reconstruit entièrement rankings_cache et player_stats en recalculant
 * chaque match clôturé DIRECTEMENT à partir de ses votes bruts (même calcul
 * que handleVotingClosed, via computeMatchTally) - pas depuis les
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
export function rebuildRankingsAndStats(firestore = getFirestore()) {
  return withRankingLock(() => rebuildRankingsUnlocked(firestore));
}

/** Caller must hold the ranking lock. Also usable with a local test database. */
export async function rebuildRankingsUnlocked(firestore = getFirestore()): Promise<{
  matchesProcessed: number;
  orphanMatchesDeleted: number;
}> {
  // listDocuments includes missing parents with remaining subcollections.
  let orphanMatchesDeleted = 0;
  for (const ref of await firestore.collection("matches").listDocuments()) {
    const doc = await ref.get();
    if (!doc.exists) {
      await firestore.recursiveDelete(ref);
      orphanMatchesDeleted++;
    } else if (doc.data()!.status !== "voting_closed") {
      // Reopened votes must not continue showing a previous final result.
      await firestore.recursiveDelete(ref.collection("results"));
    }
  }
  const matchesSnap = await firestore
    .collection("matches")
    .where("status", "==", "voting_closed")
    .get();

  const rankingTotals: Record<string, Record<string, Tally>> = {};
  const playerStatsTotals: Record<
    string,
    Tally & {
      matchesPlayed: number;
      votesReceived: number;
      distinctVoters: number;
    }
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
      for (const place of [
        vote.firstPlaceUid,
        vote.secondPlaceUid,
        vote.thirdPlaceUid,
      ]) {
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

    const presentPlayerIds = [...new Set<string>(match.presentPlayerIds ?? [])];
    const voteRate =
      presentPlayerIds.length > 0
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
    const monthKey = monthId(matchDate.toDate());
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
          c.votesReceived + currentDistinct,
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

  // ── Nettoyage des périodes, joueurs et historiques sans source restante ──
  // Si tous les matchs ont été supprimés, les boucles ci-dessus n'ont rien
  // produit → sans ce nettoyage, les anciens documents resteraient en place.
  const rankingsCacheSnap = await firestore.collection("rankings_cache").get();
  const playerStatsRefs = await firestore.collection("player_stats").listDocuments();
  const historiesByPlayer = new Map<string, Set<string>>();
  for (const h of historyEntries) {
    if (!historiesByPlayer.has(h.uid)) historiesByPlayer.set(h.uid, new Set());
    historiesByPlayer.get(h.uid)!.add(h.matchId);
  }

  // Commit bounded batches; a season's histories can easily exceed 500 writes.
  let batch = firestore.batch();
  let pending = 0;
  const flush = async (force = false) => {
    if (pending && (force || pending >= 400)) {
      await batch.commit();
      batch = firestore.batch();
      pending = 0;
    }
  };
  for (const doc of rankingsCacheSnap.docs) {
    if (!(doc.id in rankingTotals)) {
      batch.delete(doc.ref);
      pending++;
      await flush();
    }
  }
  await flush(true);
  for (const ref of playerStatsRefs) {
    const kept = historiesByPlayer.get(ref.id);
    if (!kept) {
      // Includes histories whose player_stats parent is already missing.
      await firestore.recursiveDelete(ref);
    } else {
      for (const historyRef of await ref.collection("history").listDocuments()) {
        if (!kept.has(historyRef.id)) await firestore.recursiveDelete(historyRef);
      }
    }
  }

  // ── Écriture des nouvelles données recalculées ──
  for (const [scopeId, entries] of Object.entries(rankingTotals)) {
    batch.set(firestore.collection("rankings_cache").doc(scopeId), { entries });
    pending++;
    await flush();
  }

  for (const h of historyEntries) {
    batch.set(
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
    pending++;
    await flush();
  }
  await flush(true);
  // Publish parent documents last so their listeners see complete histories.
  for (const [uid, stats] of Object.entries(playerStatsTotals)) {
    batch.set(firestore.collection("player_stats").doc(uid), {
      matchesPlayed: stats.matchesPlayed,
      totalPoints: stats.points,
      votesReceived: stats.votesReceived,
      distinctVoters: stats.distinctVoters,
      firstCount: stats.firstCount,
      secondCount: stats.secondCount,
      thirdCount: stats.thirdCount,
      // Wake parent listeners even when only dates/history distribution changed.
      updatedAt: Timestamp.now(),
    });
    pending++;
    await flush();
  }
  await flush(true);

  return { matchesProcessed, orphanMatchesDeleted };
}

export function deleteMatchAndRebuild(matchId: string, firestore = getFirestore()) {
  return withRankingLock(async () => {
    await firestore.recursiveDelete(firestore.collection("matches").doc(matchId));
    return rebuildRankingsUnlocked(firestore);
  });
}

export function recomputeClosedMatch(matchId: string, firestore = getFirestore()) {
  return withRankingLock(async () => {
    const ref = firestore.collection("matches").doc(matchId);
    const current = await ref.get();
    if (!current.exists || current.data()!.status !== "voting_closed") return null;
    await rebuildRankingsUnlocked(firestore);
    return {
      match: current.data()!,
      summary: (await ref.collection("results").doc("summary").get()).data()!,
    };
  });
}
