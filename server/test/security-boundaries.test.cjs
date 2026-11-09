const { test } = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const { validateProfilePatch } = require('../dist/profileValidation');
const { notificationTokens } = require('../dist/notificationAudience');
const { directoryProfile } = require('../dist/memberDirectory');
const { passwordResetHandler } = require('../dist/passwordReset');

test('profile rejects wrong types, oversized names and unsafe URLs', () => {
  for (const photoUrl of [123, {}, [], false, '', 'http://example.test/a', 'javascript:alert(1)', 'https://user:pass@example.test/a']) {
    assert.throws(() => validateProfilePatch({ photoUrl }), { status: 400 });
  }
  for (const patch of [{ firstName: 'a'.repeat(121) }, { team: [] }, { jerseyNumber: 1000 }, { jerseyNumber: 1.5 }]) {
    assert.throws(() => validateProfilePatch(patch), { status: 400 });
  }
  validateProfilePatch({ photoUrl: null, jerseyNumber: null });
  validateProfilePatch({ photoUrl: 'https://example.test/image.png', firstName: 'Camille', jerseyNumber: 12 });
});

test('malformed legacy tokens do not stop notifications to other members', () => {
  const users = [{ uid: 'bad', isActive: true, role: 'member', fcmTokens: {} },
    { uid: 'ok', isActive: true, role: 'member', fcmTokens: ['synthetic-token', 123, null, '', 'white space'] }];
  assert.deepEqual(notificationTokens(users, {}), ['synthetic-token']);
});

test('directory excludes contacts, tokens and future private fields', () => {
  const profile = directoryProfile('synthetic', { firstName: 'Camille', lastName: 'Test', team: 'Demo',
    email: 'private@example.invalid', fcmTokens: ['synthetic-token'], privateNote: 'private', role: 'member', isActive: true });
  assert.equal(profile.email, '');
  assert.equal(profile.fcmTokens, undefined);
  assert.equal(profile.privateNote, undefined);
  assert.equal(profile.firstName, 'Camille');
});

test('password reset limits address and IP, expires and never reveals account existence', async () => {
  let now = 0;
  const deliveries = [];
  const app = express();
  app.use(express.json());
  app.post('/reset', passwordResetHandler(async email => { deliveries.push(email); }, () => now));
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  const url = `http://127.0.0.1:${server.address().port}/reset`;
  const post = email => fetch(url, { method: 'POST', headers: { 'Content-Type': 'application/json',
    'X-Forwarded-For': Math.random().toString() }, body: JSON.stringify({ email }) });
  try {
    for (const email of [123, {}, 'bad', 'a'.repeat(255) + '@example.test']) assert.equal((await post(email)).status, 400);
    for (let i = 0; i < 3; i++) assert.equal((await post('one@example.test')).status, 200);
    const rejected = await post('ONE@example.test');
    assert.equal(rejected.status, 429); assert.equal(rejected.headers.get('retry-after'), '900');
    assert.equal(deliveries.length, 3);
    for (let i = 0; i < 7; i++) assert.equal((await post(`other${i}@example.test`)).status, 200);
    assert.equal((await post('another@example.test')).status, 429);
    now = 900001;
    assert.equal((await post('one@example.test')).status, 200);
  } finally { await new Promise(resolve => server.close(resolve)); }
});

test('password reset returns the same result for failed delivery', async () => {
  const response = { json(body) { this.body = body; }, status(status) { this.code = status; return this; } };
  const handler = passwordResetHandler(async () => { throw Error('synthetic failure'); });
  await handler({ body: { email: 'unknown@example.test' }, ip: '127.0.0.1' }, response);
  assert.deepEqual(response.body, { success: true });
});
