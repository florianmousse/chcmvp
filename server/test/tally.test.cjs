const { test } = require('node:test');
const assert = require('node:assert/strict');
const { computeMatchTally } = require('../dist/matchTally');
const { seasonId, monthId } = require('../dist/season');
const scale = { first: 5, second: 3, third: 1 };
test('points are awarded once per match, not multiplied by voter count', () => {
  const votes = Array.from({ length: 10 }, () => ({ firstPlaceUid:'a', secondPlaceUid:'b', thirdPlaceUid:'c' }));
  const result = computeMatchTally(votes, scale);
  assert.equal(result.totalVotes, 10);
  assert.deepEqual(result.entries.a, { points:5, firstCount:1, secondCount:0, thirdCount:0 });
  assert.equal(result.entries.b.points, 3); assert.equal(result.entries.c.points, 1);
});
test('joint first places consume two ranks; next player is third', () => {
  const result = computeMatchTally([
    { firstPlaceUid:'a', secondPlaceUid:'b', thirdPlaceUid:'c' },
    { firstPlaceUid:'b', secondPlaceUid:'a', thirdPlaceUid:'c' },
  ], scale);
  assert.deepEqual(result.mvpUids.sort(), ['a', 'b']);
  assert.equal(result.entries.c.points, 1);
  assert.equal(result.entries.c.thirdCount, 1);
});
test('no ballots means no MVP or phantom points', () => {
  assert.deepEqual(computeMatchTally([], scale), { entries:{}, mvpUids:[], totalVotes:0 });
});
test('month and season follow the club calendar at French midnight', () => {
  const september = new Date('2026-08-31T22:00:00Z');
  assert.equal(seasonId(september), '2026-2027');
  assert.equal(monthId(september), '2026-09');
  assert.equal(seasonId(new Date('2026-08-31T21:59:59Z')), '2025-2026');
  assert.equal(monthId(new Date('2026-12-31T23:00:00Z')), '2027-01');
});
