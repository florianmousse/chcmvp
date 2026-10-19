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
  for (const type of ['serieTop3','regularite','buteur','passeurDor','fairPlay']) assert(!recalculated.has(type), type);
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
  const split = older.map((m, i) => ({ ...m, date:new Date(Date.UTC(i < 10 ? 2025 : 2026,8,1+i)) }));
  assert(!calculateBadges(split, now).get('a').has('centurion'));
  assert(!calculateBadges([match(0)], now).get('a').has('mvpSaison'));
});
test('revelation and polyvalence are recalculated from remaining real match data', () => {
  const matches = Array.from({ length:6 }, (_, i) => match(i, { entries:{ a:entry(i<5 ? 1 : 3,0) },
    gameStats:{a:{goals:1,assists:1,greenCards:1}} }));
  const badges = calculateBadges(matches, now).get('a');
  assert(badges.has('revelation')); assert(badges.has('couteauSuisse'));
  assert(!calculateBadges(matches.slice(0,5), now).get('a').has('revelation'));
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
