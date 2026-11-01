const { test } = require('node:test');
const assert = require('node:assert/strict');
const { calculateBadges } = require('../dist/rebuildBadges');
const { notificationTokens } = require('../dist/notificationAudience');
const now = new Date('2026-10-19T12:00:00Z');
const entry = (points = 5, firstCount = 1) => ({ points, firstCount, secondCount:0, thirdCount:0 });
function match(i, overrides = {}) {
  return { id:`m${i}`, date:new Date(Date.UTC(2026,8,1+i)), team:'Seniors', present:['a','b','c','d','e'],
    entries:{ a:entry() }, distinctVoters:{ a:4 }, voters:new Set(['a']),
    gameStats:{ a:{ goals:1, assists:1, greenCards:0, yellowCards:0, redCards:0 } }, ...overrides };
}
test('badges are revoked when the remaining matches no longer meet thresholds', () => {
  const matches = Array.from({ length:5 }, (_, i) => match(i));
  const earned = calculateBadges(matches, now).get('a');
  for (const type of ['serieTop3','plebiscite','regularite','buteur','passeurDor','fairPlay']) assert(earned.has(type), type);
  const recalculated = calculateBadges(matches.slice(1), now).get('a');
  for (const type of ['regularite','buteur','passeurDor','fairPlay']) assert(!recalculated.has(type), type);
  assert.equal(calculateBadges([], now).size, 0);
});
test('green cards and missing sheets prevent fair-play; test matches grant nothing', () => {
  const matches = Array.from({ length:5 }, (_, i) => match(i));
  matches[0].gameStats.a.greenCards = 1;
  assert(!calculateBadges(matches, now).get('a').has('fairPlay'));
  delete matches[0].gameStats.a;
  assert(!calculateBadges(matches, now).get('a').has('fairPlay'));
  assert.equal(calculateBadges(matches.map((m) => ({...m, id:`test:${m.id}`})), now).size, 0);
});
test('season awards stay in their season and past-season achievements remain valid', () => {
  const older = Array.from({ length:20 }, (_, i) => match(i, { date:new Date(Date.UTC(2025,8,1+i)) }));
  const badges = calculateBadges(older, now).get('a');
  for (const type of ['mvpSaison','votantAssidu','centurion','podiumMaster']) assert(badges.has(type), type);
  const split = older.map((m, i) => ({ ...m, date:new Date(Date.UTC(2020 + Math.floor(i / 5),8,1+i)) }));
  assert(!calculateBadges(split, now).get('a').has('centurion'));
  assert(!calculateBadges([match(0)], now).get('a').has('mvpSaison'));
});
test('revelation and polyvalence are recalculated from remaining real match data', () => {
  const matches = Array.from({ length:4 }, (_, i) => match(i, { entries:{ a:entry(i<3 ? 1 : 3,0) },
    gameStats:{a:{goals:1,assists:1,greenCards:1}} }));
  const badges = calculateBadges(matches, now).get('a');
  assert(badges.has('revelation')); assert(badges.has('couteauSuisse'));
  assert(!calculateBadges(matches.slice(0,3), now).get('a').has('revelation'));
});
test('test notifications target active admins only regardless of simulated participants', () => {
  const users = [
    {uid:'admin', role:'admin', isActive:true, fcmTokens:['admin-token','admin-token']},
    {uid:'member', role:'member', isActive:true, fcmTokens:['member-token']},
    {uid:'disabled', role:'admin', isActive:false, fcmTokens:['disabled-token']},
  ];
  assert.deepEqual(notificationTokens(users, {adminsOnly:true, onlyUids:['member'], excludeUids:['admin']}), ['admin-token']);
  assert.deepEqual(notificationTokens(users, {onlyUids:['member']}), ['member-token']);
});

test('bronze 5, silver 15, gold 25 goals and assists; recalculation downgrades tiers',()=>{
  const build=(goals,assists=goals)=>match(0,{gameStats:{a:{goals,assists}}});
  for(const count of [4,5,14,15,24,25]){
    const earned=calculateBadges([build(count)],now).get('a');
    assert.equal(earned.has('buteur'),count>=5);
    assert.equal(earned.has('buteurArgent'),count>=15);
    assert.equal(earned.has('buteurOr'),count>=25);
    assert.equal(earned.has('passeurDor'),count>=5);
    assert.equal(earned.has('passeurArgent'),count>=15);
    assert.equal(earned.has('passeurOr'),count>=25);
  }
  const old=build(15);old.date=new Date('2025-10-01');
  assert(!calculateBadges([old,build(15)],now).get('a').has('buteurOr'));
  assert(calculateBadges([old],now).get('a').has('buteurArgent'));
  assert(!calculateBadges([build(5)],now).get('a').has('buteurArgent'));
});

test('short season thresholds and Swiss army tiers ignore cards entirely', () => {
  const earned = (n) => calculateBadges(Array.from({length:n}, (_,i)=>match(i)),now).get('a');
  assert(!earned(2).has('serieTop3')); assert(earned(3).has('serieTop3'));
  assert(!earned(4).has('podiumMaster')); assert(earned(5).has('podiumMaster'));
  assert(!earned(5).has('centurion')); assert(earned(6).has('centurion'));
  const broken = [match(0),match(1),match(2,{entries:{}}),match(3),match(4)];
  assert(!calculateBadges(broken,now).get('a').has('serieTop3'));
  for (const count of [2,3,7,8,14,15]) {
    for (const cards of [0,50]) {
      const badges=calculateBadges([match(0,{gameStats:{a:{goals:count,assists:count,greenCards:cards}}})],now).get('a');
      assert.equal(badges.has('couteauSuisse'),count>=3);
      assert.equal(badges.has('couteauSuisseArgent'),count>=8);
      assert.equal(badges.has('couteauSuisseOr'),count>=15);
    }
  }
  assert(!calculateBadges([match(0,{gameStats:{a:{goals:15,assists:2,greenCards:50}}})],now).get('a').has('couteauSuisse'));
});

test('Cap des 50 adds all seasons, excludes tests and is revoked below 50', () => {
  const matches=Array.from({length:10},(_,i)=>match(i,{date:new Date(Date.UTC(i<5 ? 2025 : 2026,8,1+i))}));
  const earned=calculateBadges(matches,now).get('a');
  assert(earned.has('capDes50'));
  assert(!earned.has('centurion')); // 25 in each season, below the seasonal 30.
  assert(!calculateBadges(matches.slice(1),now).get('a').has('capDes50'));
  const testMatch=match(99,{id:'test:bonus',entries:{a:entry(100)}});
  assert(!calculateBadges([...matches.slice(1),testMatch],now).get('a').has('capDes50'));
  const older=matches.map(m=>({...m,date:new Date('2024-10-01')}));
  assert(calculateBadges(older,now).get('a').has('capDes50'));
});
