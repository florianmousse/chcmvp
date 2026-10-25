const { test, beforeEach, after } = require('node:test');
const assert = require('node:assert/strict');
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { rebuildRankingsAndStats, deleteMatchAndRebuild, recomputeClosedMatch } = require('../dist/rebuildRankings');
const { withRankingLock } = require('../dist/rankingLock');
const { saveTestVote } = require('../dist/testVotes');
const { voteParticipation } = require('../dist/voteParticipation');
const { resetVote, ballotVersion } = require('../dist/resetVote');
const { reopenVoting, initializeVotingWindow, closeExpiredVoting, remindReopenedVoting, REOPEN_REMINDER_INTERVAL_MS } = require('../dist/votingLifecycle');

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

test('reset only removes the selected ballot on an open match, then accepts a fresh vote', async () => {
  await db.doc('users/admin').set({role:'admin',isActive:true});
  await db.doc('users/d').set({firstName:'Didier',email:'d@example.test',isActive:true});
  await db.doc('users/e').set({firstName:'Eric',email:'e@example.test',isActive:true});
  for (const id of ['reset','test:reset']) {
    const ref = id.startsWith('test:') ? db.doc(`test_matches/${id}`) : await seedMatch(id);
    if (id.startsWith('test:')) {
      await ref.set({presentPlayerIds:['d','e'],status:'voting_open'});
      for (const uid of ['d','e']) await ref.collection('votes').doc(uid).set({voterUid:uid,firstPlaceUid:'SECRET'});
    } else await ref.update({status:'voting_open'});
    const originalMatch = (await ref.get()).data();
    const other = (await ref.collection('votes').doc('e').get()).data();
    const before = await voteParticipation(id,'admin',db);
    assert.equal(before.canReset,true);
    assert.equal(before.votedCount,2);
    assert(!JSON.stringify(before).includes('SECRET'));
    assert(!JSON.stringify(before).includes('firstPlaceUid'));
    const version=before.voted.find(p=>p.uid==='d').voteVersion;
    await resetVote(id,'d','admin',version,db);
    assert.equal((await ref.collection('votes').doc('d').get()).exists,false);
    assert.deepEqual((await ref.get()).data(),originalMatch);
    assert.deepEqual((await ref.collection('votes').doc('e').get()).data(),other);
    const after=await voteParticipation(id,'admin',db);
    assert.equal(after.votedCount,1);
    assert(after.pending.some(p=>p.uid==='d'));
    await assert.rejects(resetVote(id,'d','admin',version,db),{status:409});
    // Simulate the newly submitted ballot; a stale confirmation must not delete it.
    await ref.collection('votes').doc('d').set({voterUid:'d',firstPlaceUid:'NEW_SECRET'});
    await assert.rejects(resetVote(id,'d','admin',version,db),{status:409});
    assert.equal((await ref.collection('votes').doc('d').get()).data().firstPlaceUid,'NEW_SECRET');
  }
});

test('reset enforces active admin and current voting window; simultaneous resets delete once', async () => {
  await db.doc('users/admin').set({role:'admin',isActive:true});
  await db.doc('users/member').set({role:'member',isActive:true});
  await db.doc('users/inactive').set({role:'admin',isActive:false});
  const ref=await seedMatch('protected');
  const version=ballotVersion((await ref.collection('votes').doc('d').get()).updateTime);
  for (const uid of ['member','inactive','unknown']) {
    await assert.rejects(resetVote(ref.id,'d',uid,version,db),{status:403});
  }
  for (const status of ['voting_closed','upcoming']) {
    await ref.update({status});
    await assert.rejects(resetVote(ref.id,'d','admin',version,db),{status:409});
  }
  await ref.update({status:'voting_open',votingClosesAt:Timestamp.fromMillis(Date.now()-10000)});
  assert.equal((await voteParticipation(ref.id,'admin',db)).canReset,false);
  await assert.rejects(resetVote(ref.id,'d','admin',version,db),{status:409});
  await ref.update({votingClosesAt:null,votingOpensAt:Timestamp.fromMillis(Date.now()+60000)});
  await assert.rejects(resetVote(ref.id,'d','admin',version,db),{status:409});
  await ref.update({votingOpensAt:null,manualCloseRequired:true});
  await assert.rejects(resetVote('missing','d','admin',version,db),{status:404});
  await assert.rejects(resetVote(ref.id,'d','admin',undefined,db),{status:400});
  await assert.rejects(resetVote(ref.id,'bad/id','admin',version,db),{status:400});
  const results=await Promise.allSettled([resetVote(ref.id,'d','admin',version,db), resetVote(ref.id,'d','admin',version,db)]);
  assert.equal(results.filter(r=>r.status==='fulfilled').length,1);
  assert.equal(results.find(r=>r.status==='rejected').reason.status,409);
  assert.equal((await ref.collection('votes').get()).size,1);
});

test('reopening preserves ballots, revokes totals and badges, and recomputes once on closure', async () => {
  await db.doc('users/admin').set({ role:'admin', isActive:true });
  const ref = await seedMatch('reopen');
  await rebuildRankingsAndStats(db);
  assert.equal((await data('rankings_cache/general')).entries.a.points, 5);
  await reopenVoting('reopen', 'admin', db);
  const opened = await data('matches/reopen');
  assert.equal(opened.status, 'voting_open');
  assert.equal(opened.manualCloseRequired, true);
  assert.equal(opened.votingClosesAt, null);
  assert.equal(opened.reopenedBy, 'admin');
  assert.equal((await ref.collection('votes').get()).size, 2);
  assert.equal(await data('matches/reopen/results/summary'), undefined);
  assert.equal(await data('rankings_cache/general'), undefined);
  assert.equal(await data('player_stats/a'), undefined);
  for (const badge of (await db.collection('userBadges').get()).docs) {
    assert.deepEqual(badge.data().earned, {});
  }
  await reopenVoting('reopen', 'admin', db); // retry after a disconnected client
  assert((await data('matches/reopen')).reopenedAt.isEqual(opened.reopenedAt));
  await initializeVotingWindow('reopen', 48, db);
  assert.equal((await data('matches/reopen')).votingClosesAt, null);
  await ref.collection('votes').doc('a').set({ voterUid:'a', firstPlaceUid:'b', secondPlaceUid:'c', thirdPlaceUid:'d' });
  await ref.update({status:'voting_closed'});
  await recomputeClosedMatch('reopen', db);
  assert.equal((await data('matches/reopen/results/summary')).totalVotes, 3);
  assert.equal((await data('rankings_cache/general')).entries.b.points, 5);
  await recomputeClosedMatch('reopen', db);
  assert.equal((await data('rankings_cache/general')).entries.b.points, 5);
});

test('only active admins can reopen closed votes; tests remain isolated', async () => {
  await db.doc('users/admin').set({ role:'admin', isActive:true });
  await db.doc('users/inactive').set({ role:'admin', isActive:false });
  await db.doc('users/member').set({ role:'member', isActive:true });
  await seedMatch('real');
  await rebuildRankingsAndStats(db);
  const before = await data('rankings_cache/general');
  const ref = db.doc('test_matches/test:reopen');
  await ref.set({ status:'voting_closed', presentPlayerIds:['a','b','c','d'], allowSelfVote:false });
  await ref.collection('votes').doc('d').set({voterUid:'d',firstPlaceUid:'a',secondPlaceUid:'b',thirdPlaceUid:'c'});
  await ref.collection('results').doc('summary').set({totalVotes:1});
  for (const uid of ['inactive','member','unknown']) {
    await assert.rejects(reopenVoting('real', uid, db), {status:403});
  }
  await assert.rejects(reopenVoting('missing','admin',db), {status:404});
  await db.doc('matches/upcoming').set({status:'upcoming'});
  await assert.rejects(reopenVoting('upcoming','admin',db), {status:409});
  await db.doc('matches/upcoming').update({status:'voting_open'});
  await assert.rejects(reopenVoting('upcoming','admin',db), {status:409});
  await reopenVoting(ref.id,'admin',db);
  assert.equal(await data('test_matches/test:reopen/results/summary'), undefined);
  assert.equal((await ref.collection('votes').get()).size, 1);
  await saveTestVote(ref.id,'admin',{voterUid:'d',firstPlaceUid:'c',secondPlaceUid:'b',thirdPlaceUid:'a'},db);
  assert.deepEqual(await data('rankings_cache/general'), before);
});

test('automatic closing re-reads state and can never close a manually reopened vote', async () => {
  const now = Timestamp.now();
  for (const collection of ['matches','test_matches']) {
    const id = collection === 'matches' ? 'expired' : 'test:expired';
    const ref = db.doc(`${collection}/${id}`);
    await ref.set({status:'voting_open',votingClosesAt:Timestamp.fromMillis(now.toMillis()-1000)});
    assert.equal(await closeExpiredVoting(id,now,db),true);
    // Simulates a stale cron snapshot whose deadline was already read before reopening.
    await ref.update({status:'voting_open',manualCloseRequired:true});
    assert.equal(await closeExpiredVoting(id,now,db),false);
    assert.equal((await ref.get()).data().status,'voting_open');
    await initializeVotingWindow(id,48,db);
    assert.equal(await closeExpiredVoting(id,Timestamp.fromMillis(now.toMillis()+10*REOPEN_REMINDER_INTERVAL_MS),db),false);
  }
  await db.doc('matches/future').set({status:'voting_open',votingClosesAt:Timestamp.fromMillis(now.toMillis()+1000)});
  assert.equal(await closeExpiredVoting('future',now,db),false);
  assert.equal(await closeExpiredVoting('missing',now,db),false);
});

test('admin reminders are persistent, limited to once a day, retry failures and stop on close/delete', async () => {
  const sent=[];
  const send = async payload => {sent.push(payload);};
  const now = Timestamp.now();
  const ref=db.doc('test_matches/test:reminder');
  await ref.set({status:'voting_open',manualCloseRequired:true,opponent:'Rennes'});
  const concurrent=await Promise.all(Array.from({length:3},()=>remindReopenedVoting(ref.id,now,send,db)));
  assert.equal(concurrent.filter(Boolean).length,1);
  assert.equal(sent[0].title,'[TEST] Vote rouvert à clôturer');
  assert.equal(sent[0].data.type,'admin_reopened_vote_reminder');
  assert.equal(await remindReopenedVoting(ref.id,Timestamp.fromMillis(now.toMillis()+REOPEN_REMINDER_INTERVAL_MS-1),send,db),false);
  const tomorrow=Timestamp.fromMillis(now.toMillis()+REOPEN_REMINDER_INTERVAL_MS);
  await assert.rejects(remindReopenedVoting(ref.id,tomorrow,async()=>{throw new Error('FCM unavailable');},db));
  assert.equal(await remindReopenedVoting(ref.id,tomorrow,send,db),true);
  assert.equal(sent.length,2);
  const later=Timestamp.fromMillis(tomorrow.toMillis()+REOPEN_REMINDER_INTERVAL_MS);
  await ref.update({status:'voting_closed'});
  assert.equal(await remindReopenedVoting(ref.id,later,send,db),false);
  await ref.delete();
  assert.equal(await remindReopenedVoting(ref.id,later,send,db),false);
  await db.doc('matches/ordinary').set({status:'voting_open'});
  assert.equal(await remindReopenedVoting('ordinary',later,send,db),false);
});

test('fourth-place votes stay in stats but zero points never create a ranking entry', async () => {
  const ref=await seedMatch('fourth',undefined,['d']);
  await ref.collection('votes').doc('e').set({voterUid:'e',firstPlaceUid:'a',secondPlaceUid:'b',thirdPlaceUid:'c'});
  await ref.collection('votes').doc('c').set({voterUid:'c',firstPlaceUid:'a',secondPlaceUid:'b',thirdPlaceUid:'d'});
  await rebuildRankingsAndStats(db);
  for (const scope of ['general','2026-2027','2026-10']) {
    assert.deepEqual(Object.keys((await data(`rankings_cache/${scope}`)).entries).sort(),['a','b','c']);
  }
  assert.equal((await data('matches/fourth/results/summary')).entries.d.points,0);
  assert.equal((await data('player_stats/d')).votesReceived,1);
  assert.equal((await data('player_stats/d/history/fourth')).points,0);
});

test('admin turnout is live, deduplicates attendance and never exposes ballot choices', async () => {
  await db.doc('users/admin').set({ role:'admin', isActive:true });
  await db.doc('users/member').set({ role:'member', isActive:true });
  await db.doc('users/inactiveAdmin').set({ role:'admin', isActive:false });
  await db.doc('users/a').set({ firstName:'Alice', lastName:'Martin', email:'a@example.test', isActive:true });
  await db.doc('users/b').set({ firstName:'Benoît', lastName:'Dupont', email:'', isActive:true });
  await db.doc('users/c').set({ firstName:'Camille', lastName:'Petit', email:'c@example.test', isActive:false });
  for (const path of ['matches/live','test_matches/test:live']) {
    const ref = db.doc(path);
    await ref.set({ status:'voting_open', presentPlayerIds:['a','b','c','missing','a'] });
    await ref.collection('votes').doc('a').set({ firstPlaceUid:'SECRET', voterUid:'other' });
    await ref.collection('votes').doc('absent').set({ firstPlaceUid:'SECRET' });
    const result = await voteParticipation(ref.id, 'admin', db);
    assert.equal(result.votedCount, 1); assert.equal(result.totalCount, 4);
    assert.deepEqual(result.pending.map(p=>[p.name,p.accountStatus]), [
      ['Camille Petit','inactive'], ['Joueur supprimé','missing'], ['Benoît Dupont','no_account'],
    ]);
    assert(!JSON.stringify(result).includes('SECRET'));
    assert(!JSON.stringify(result).includes('@'));
    await ref.collection('votes').doc('b').set({ firstPlaceUid:'SECRET' });
    assert.equal((await voteParticipation(ref.id,'admin',db)).votedCount, 2);
    await ref.update({ status:'voting_closed' });
    assert.equal((await voteParticipation(ref.id,'admin',db)).votedCount, 2);
    for (const uid of ['member','inactiveAdmin','unknown']) {
      await assert.rejects(voteParticipation(ref.id,uid,db), {status:403});
    }
  }
  await db.doc('matches/empty').set({status:'upcoming',presentPlayerIds:[]});
  assert.deepEqual((await voteParticipation('empty','admin',db)).pending, []);
  await assert.rejects(voteParticipation('removed','admin',db), {status:404});
});

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

test('deleting a source match revokes badges and preserves dates of valid badges', async () => {
  for (let i = 0; i < 5; i++) {
    const ref = await seedMatch(`badge${i}`);
    await ref.collection('playerStats').doc('a').set({ goals: 2, assists: 1, greenCards: 0 });
  }
  await rebuildRankingsAndStats(db);
  const earned = (await data('userBadges/a')).earned;
  assert.ok(earned.fairPlay && earned.buteur && earned.passeurDor && earned.serieTop3);
  await rebuildRankingsAndStats(db);
  assert.deepEqual((await data('userBadges/a')).earned, earned);
  await deleteMatchAndRebuild('badge4', db);
  const remaining = (await data('userBadges/a')).earned;
  assert.deepEqual(Object.keys(remaining), ['buteur']);
  assert.ok(remaining.buteur.isEqual(earned.buteur));
  for (let i = 0; i < 4; i++) await deleteMatchAndRebuild(`badge${i}`, db);
  assert.deepEqual((await data('userBadges/a')).earned, {});
});

test('test ballots validate the voter and candidates and never change real totals or badges', async () => {
  await seedMatch('real');
  await rebuildRankingsAndStats(db);
  const ranking = await data('rankings_cache/general');
  const stats = await data('player_stats/a');
  const badges = await db.collection('userBadges').get();
  await db.doc('users/admin').set({ role: 'admin', isActive: true });
  await db.doc('users/member').set({ role: 'member', isActive: true });
  await db.doc('users/inactive').set({ role: 'admin', isActive: false });
  const ref = db.doc('test_matches/test:simulation');
  await ref.set({ status: 'voting_open', date: Timestamp.now(), presentPlayerIds: ['a','b','c','d'], allowSelfVote: false });
  const ballot = { voterUid:'d', firstPlaceUid:'a', secondPlaceUid:'b', thirdPlaceUid:'c' };
  for (const [id, uid, input, status] of [
    ['real','admin',ballot,400],
    [ref.id,'member',ballot,403],
    [ref.id,'inactive',ballot,403],
    [ref.id,'admin',{...ballot, voterUid:'absent'},400],
    [ref.id,'admin',{...ballot, firstPlaceUid:'absent'},400],
    [ref.id,'admin',{...ballot, firstPlaceUid:'d'},400],
    [ref.id,'admin',{...ballot, firstPlaceUid:'b'},400],
  ]) await assert.rejects(saveTestVote(id, uid, input, db), { status });
  await saveTestVote(ref.id, 'admin', ballot, db);
  await saveTestVote(ref.id, 'admin', {...ballot, firstPlaceUid:'b', secondPlaceUid:'a'}, db);
  assert.equal((await ref.collection('votes').get()).size, 1);
  assert.equal((await data(`${ref.path}/votes/d`)).simulatedByAdminUid, 'admin');
  await ref.update({ status:'voting_closed' });
  await assert.rejects(saveTestVote(ref.id, 'admin', ballot, db), { status:409 });
  const result = await recomputeClosedMatch(ref.id, db);
  assert.equal(result.summary.entries.b.points, 5);
  assert.equal(result.summary.totalVotes, 1);
  assert.deepEqual(await data('rankings_cache/general'), ranking);
  assert.deepEqual(await data('player_stats/a'), stats);
  assert.deepEqual((await db.collection('userBadges').get()).docs.map(d=>d.data()), badges.docs.map(d=>d.data()));
  await rebuildRankingsAndStats(db);
  assert.deepEqual(await data('rankings_cache/general'), ranking);
  await deleteMatchAndRebuild(ref.id, db);
  assert.equal((await ref.get()).exists, false);
  assert.equal((await ref.collection('votes').get()).size, 0);
  assert.equal((await ref.collection('results').get()).size, 0);
  assert.deepEqual(await data('rankings_cache/general'), ranking);
});
