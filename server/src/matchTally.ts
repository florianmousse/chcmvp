export interface Tally {
  points: number;
  firstCount: number;
  secondCount: number;
  thirdCount: number;
}

export interface MatchTallyResult {
  entries: Record<string, Tally>;
  mvpUids: string[];
  totalVotes: number;
}

interface PointsScale {
  first: number;
  second: number;
  third: number;
}

interface RawVote {
  firstPlaceUid: string;
  secondPlaceUid: string;
  thirdPlaceUid: string;
}

/**
 * Calcule le résultat RÉEL d'un match à partir de ses votes bruts, en trois
 * temps :
 * 1. Un score BRUT par joueur (somme pondérée des votes individuels selon
 *    le barème) — sert UNIQUEMENT à les classer entre eux pour ce match, ce
 *    n'est jamais le nombre de points final attribué.
 * 2. Le classement du match (qui a fini 1er/2e/3e) via un rang "olympique"
 *    standard sur ce score brut : le rang d'un joueur est 1 + le nombre de
 *    joueurs strictement devant lui. Une égalité CONSOMME autant de rangs
 *    qu'il y a de joueurs à égalité — si 4 joueurs sont à égalité en tête,
 *    ils sont tous 1ers (et tous MVP), et le joueur suivant est 5e, pas 2e.
 * 3. Les points FINAUX (ceux qui comptent pour le classement général) ne
 *    dépendent QUE du rang obtenu à cette étape, pas du score brut : 5
 *    points pour avoir fini 1er de CE match, 3 pour 2e, 1 pour 3e, peu
 *    importe le nombre de votes reçus ou l'écart entre les joueurs — jamais
 *    5 points par votant ayant choisi ce joueur en 1ère place.
 */
export function computeMatchTally(
  votes: RawVote[],
  scale: PointsScale,
): MatchTallyResult {
  const rawScoreByPlayer = new Map<string, number>();
  const bump = (uid: string, points: number) => {
    rawScoreByPlayer.set(uid, (rawScoreByPlayer.get(uid) ?? 0) + points);
  };
  for (const vote of votes) {
    bump(vote.firstPlaceUid, scale.first);
    bump(vote.secondPlaceUid, scale.second);
    bump(vote.thirdPlaceUid, scale.third);
  }

  const allScores = Array.from(rawScoreByPlayer.values());
  const entries: Record<string, Tally> = {};
  for (const [uid, score] of rawScoreByPlayer) {
    const rank = 1 + allScores.filter((s) => s > score).length;
    entries[uid] = {
      points:
        rank === 1
          ? scale.first
          : rank === 2
            ? scale.second
            : rank === 3
              ? scale.third
              : 0,
      firstCount: rank === 1 ? 1 : 0,
      secondCount: rank === 2 ? 1 : 0,
      thirdCount: rank === 3 ? 1 : 0,
    };
  }

  // MVP(s) : tous les joueurs de rang 1 — pluriel assumé, en cas d'égalité
  // pour la 1ère place ils sont tous MVP.
  const mvpUids = Object.entries(entries)
    .filter(([, t]) => t.firstCount === 1)
    .map(([uid]) => uid);

  return { entries, mvpUids, totalVotes: votes.length };
}
