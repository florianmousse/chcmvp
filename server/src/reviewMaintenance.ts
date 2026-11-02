import { getProductionFirestore, getFirestore, inReviewSpace } from './database';
import { processScheduledVoting } from './scheduledVoting';
import { recomputeClosedMatch } from './rebuildRankings';

/** Background jobs use the same isolated scope as HTTP; no production listener
 * watches these collections and notification delivery is suppressed by scope. */
export async function processReviewSpaces(production = getProductionFirestore()) {
  const spaces = await production.collection('review_spaces').get();
  for (const space of spaces.docs) {
    const owner = (await production.doc(`users/${space.id}`).get()).data();
    if (owner?.role !== 'reviewer' || owner.isActive !== true) continue;
    try {
      await inReviewSpace(space.id, async () => {
        await processScheduledVoting();
        for (const collection of ['matches', 'test_matches']) {
          const closed = await getFirestore().collection(collection).where('status', '==', 'voting_closed').get();
          for (const match of closed.docs) await recomputeClosedMatch(match.id);
        }
      }, production);
    } catch (error) { console.error('Cycle de validation échoué', space.id, error); }
  }
}
