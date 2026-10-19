const { test, beforeEach, after } = require('node:test');
const assert = require('node:assert/strict');
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { rebuildRankingsAndStats, deleteMatchAndRebuild, recomputeClosedMatch } = require('../dist/rebuildRankings');
const { withRankingLock } = require('../dist/rankingLock');

// Refuse to touch any remote or production database.
if (!/^(127\.0\.0\.1|localhost):\d+$/.test(process.env.FIRESTORE_EMULATOR_HOST ?? '')) {
  throw new Error('FIRESTORE_EMULATOR_HOST local requis');
}
const app = initializeApp({ projectId: 'demo-chc-audit' }, 'ranking-audit');
const db = getFirestore(app);
beforeEach(async () => {
  for (const collection of await db.listCollections()) await db.recursiveDelete(collection);
});
after(async () => { await db.terminate(); await deleteApp(app); });

async function seedMatch(id, date = '2026-10-12T12:00:00Z', voters = ['d', 'e']) {
  const ref = db.doc(`matches/${id}`);
  await ref.set({ status: 'voting_closed', date: Timestamp.fromDate(new Date(date)),
    presentPlayerIds: ['a', 'b', 'c', 'd', 'e'], pointsScale: { first: 5, second: 3, third: 1 } });
  for (const uid of voters) await ref.collection('votes').doc(uid).set({
    voterUid: uid, firstPlaceUid: 'a', secondPlaceUid: 'b', thirdPlaceUid: 'c',
  });
  return ref;
}
async function data(path) { return (await db.doc(path).get()).data(); }

test('rebuild removes deleted-match subcollections, old scopes and orphan histories', async () => {
  const deleted = await seedMatch('deleted', '2025-10-12T12:00:00Z');
  await deleted.collection('playerStats').doc('a').set({ greenCards: 3 });
  await seedMatch('kept');
  await rebuildRankingsAndStats(db);
  await deleted.delete(); // Reproduce legacy client / console deletion.
  await db.doc('player_stats/missing/history/deleted').set({ points: 99 });
  const result = await rebuildRankingsAndStats(db);
  assert.equal(result.orphanMatchesDeleted, 1);
  assert.equal(result.matchesProcessed, 1);
  for (const collection of ['votes', 'results', 'playerStats']) {
    assert.equal((await deleted.collection(collection).get()).size, 0);
  }
  assert.equal(await data('rankings_cache/2025-2026'), undefined);
  assert.equal(await data('rankings_cache/2025-10'), undefined);
  assert.equal(await data('player_stats/a/history/deleted'), undefined);
  assert.equal(await data('player_stats/missing/history/deleted'), undefined);
  for (const scope of ['general', '2026-2027', '2026-10']) {
    assert.equal((await data(`rankings_cache/${scope}`)).entries.a.points, 5);
  }
  assert.equal((await data('player_stats/a')).totalPoints, 5);
  assert.equal((await data('player_stats/a')).votesReceived, 2); // ballots, not one podium
  assert.equal((await data('player_stats/d')).matchesPlayed, 1);
  assert.equal((await data('player_stats/d')).votesReceived, 0);
  const expected = await data('player_stats/a');
  await rebuildRankingsAndStats(db);
  const repeated = await data('player_stats/a');
  delete expected.updatedAt; delete repeated.updatedAt;
  assert.deepEqual(repeated, expected);
});

test('deleting the last match leaves no votes, rankings or player history', async () => {
  await seedMatch('last');
  await rebuildRankingsAndStats(db);
  await deleteMatchAndRebuild('last', db);
  for (const name of ['matches', 'rankings_cache', 'player_stats']) {
    assert.equal((await db.collection(name).listDocuments()).length, 0);
  }
  await rebuildRankingsAndStats(db);
  assert.equal((await db.collectionGroup('history').get()).size, 0);
});

test('more than 500 histories rebuild correctly and twice without doubling totals', async () => {
  for (let i = 0; i < 102; i++) await seedMatch(`m${i}`);
  const first = await rebuildRankingsAndStats(db);
  assert.equal(first.matchesProcessed, 102);
  assert.equal((await db.collectionGroup('history').get()).size, 510);
  assert.equal((await data('player_stats/a')).totalPoints, 510);
  await rebuildRankingsAndStats(db);
  assert.equal((await data('player_stats/a')).votesReceived, 204);
  assert.equal((await data('rankings_cache/general')).entries.a.points, 510);
});

test('open votes remain intact but contribute no points after reconstruction', async () => {
  const ref = await seedMatch('open');
  await rebuildRankingsAndStats(db);
  await ref.update({ status: 'voting_open' });
  await rebuildRankingsAndStats(db);
  assert.equal((await ref.collection('votes').get()).size, 2);
  assert.equal((await db.collection('rankings_cache').get()).size, 0);
  assert.equal((await ref.collection('results').get()).size, 0);
});

test('simultaneous deletion and rebuild cannot reintroduce the deleted match', async () => {
  await seedMatch('keep'); await seedMatch('remove');
  await Promise.all([rebuildRankingsAndStats(db), deleteMatchAndRebuild('remove', db), rebuildRankingsAndStats(db)]);
  assert.equal((await data('rankings_cache/general')).entries.a.points, 5);
  assert.equal(await data('player_stats/a/history/remove'), undefined);
});

test('a failed operation releases the ranking queue', async () => {
  await assert.rejects(withRankingLock(async () => { throw new Error('test failure'); }));
  assert.equal(await withRankingLock(async () => 'ok'), 'ok');
});

test('closure recomputation after a rebuild stays idempotent and ignores deleted matches', async () => {
  await seedMatch('match');
  await rebuildRankingsAndStats(db);
  await recomputeClosedMatch('match', db);
  await recomputeClosedMatch('match', db);
  assert.equal((await data('player_stats/a')).totalPoints, 5);
  assert.equal((await data('player_stats/a')).votesReceived, 2);
  assert.equal((await data('player_stats/a')).matchesPlayed, 1);
  await deleteMatchAndRebuild('match', db);
  assert.equal(await recomputeClosedMatch('match', db), null);
  assert.equal((await db.collection('matches').listDocuments()).length, 0);
});
