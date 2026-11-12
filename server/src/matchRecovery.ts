import { resultsFingerprint } from './matchResultVersion';
import { FieldPath, Firestore } from 'firebase-admin/firestore';
import { getFirestore } from './database';
import { matchReference } from './matchReference';
import { recomputeClosedMatch } from './rebuildRankings';
import { initializeVotingWindow } from './votingLifecycle';
import { logEvent } from './logger';

/** The durable marker is acknowledged only after all derived writes succeed.
 * A concurrent edit leaves the old marker so the next pass repairs it again. */
export async function repairClosedMatch(matchId: string, db = getFirestore()): Promise<void> {
  const ref = matchReference(matchId, db);
  const snapshot = await ref.get();
  const match = snapshot.data();
  if (!match || match.status !== 'voting_closed' || match.resultsSourceFingerprint === resultsFingerprint(match)) return;
  const computed = await recomputeClosedMatch(matchId, db, true);
  if (!computed) return;
  const fingerprint = resultsFingerprint(computed.match);
  await db.runTransaction(async tx => {
    const current = (await tx.get(ref)).data();
    if (current && resultsFingerprint(current) === fingerprint) tx.update(ref, { resultsSourceFingerprint: fingerprint });
  });
  logEvent('info', 'vote.reparation', 'Résultats et classements recalculés sans notification.', { matchId });
}

const running = new WeakSet<Firestore>();
export async function reconcileMatches(durationHours: number, db = getFirestore()): Promise<void> {
  if (running.has(db)) return;
  running.add(db);
  try {
    for (const collection of ['matches', 'test_matches']) {
      let cursor: FirebaseFirestore.QueryDocumentSnapshot | undefined;
      for (;;) {
        let query = db.collection(collection).orderBy(FieldPath.documentId()).limit(100);
        if (cursor) query = query.startAfter(cursor);
        const page = await query.get();
        for (const doc of page.docs) {
          try {
            const match = doc.data();
            if (match.status === 'voting_closed') await repairClosedMatch(doc.id, db);
            if (match.status === 'voting_open' && !match.manualCloseRequired && !match.votingClosesAt) {
              await initializeVotingWindow(doc.id, durationHours, db);
            }
          } catch {
            logEvent('error', 'vote.reprise', 'Réparation échouée ; nouvelle tentative au prochain cycle.', { matchId: doc.id });
          }
        }
        if (page.size < 100) break;
        cursor = page.docs[page.docs.length - 1];
      }
    }
  } finally { running.delete(db); }
}
