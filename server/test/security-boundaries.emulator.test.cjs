const { test, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { memberDirectory } = require('../dist/memberDirectory');
const { reviewDatabase } = require('../dist/database');
const { writeData } = require('../dist/routes/data');
if (!/^(127\.0\.0\.1|localhost):\d+$/.test(process.env.FIRESTORE_EMULATOR_HOST ?? '')) throw Error('Local emulator required');
const app = initializeApp({ projectId: 'demo-chc-boundaries' }, 'boundaries');
const db = getFirestore(app);
beforeEach(async () => {
  for (const collection of await db.listCollections()) await db.recursiveDelete(collection);
  await db.doc('users/member').set({ role: 'member', isActive: true, firstName: 'Camille', lastName: 'Test', team: 'Demo', email: 'private@example.invalid', fcmTokens: ['synthetic-token'] });
  await db.doc('users/inactive').set({ role: 'member', isActive: false });
  await db.doc('users/reviewer').set({ role: 'reviewer', isActive: true });
});
after(async () => { await db.terminate(); await deleteApp(app); });

test('directory denies inactive, missing and unscoped review accounts', async () => {
  for (const uid of ['inactive', 'unknown', 'reviewer']) await assert.rejects(memberDirectory(uid, undefined, db), { status: 403 });
  await assert.rejects(memberDirectory('member', '../users', db), { status: 400 });
  const directory = await memberDirectory('member', undefined, db);
  assert.equal(directory.members.find(m => m.uid === 'member').email, '');
  assert(!JSON.stringify(directory).includes('synthetic-token'));
  assert(!directory.members.some(m => m.uid === 'reviewer'));
  await db.doc('users/admin').set({ role: 'admin', isActive: true });
  const managed = await memberDirectory('admin', undefined, db);
  assert.equal(managed.members.find(m => m.uid === 'member').email, 'private@example.invalid');
  assert(!JSON.stringify(managed).includes('synthetic-token'));
});

test('directory pages have no loss or duplicates and review reads stay isolated', async () => {
  const batch = db.batch();
  for (let i = 0; i < 105; i++) batch.set(db.doc(`users/player-${String(i).padStart(3, '0')}`), { role: 'member', isActive: true });
  await batch.commit();
  const first = await memberDirectory('member', undefined, db);
  const second = await memberDirectory('member', first.nextCursor, db);
  assert.equal(first.members.length, 100);
  assert.equal(second.nextCursor, null);
  const ids = [...first.members, ...second.members].map(m => m.uid);
  assert.equal(ids.length, 107); assert.equal(new Set(ids).size, 107);
  const sandbox = reviewDatabase('reviewer', db);
  await sandbox.doc('users/reviewer').set({ role: 'admin', isActive: true });
  await sandbox.doc('users/demo').set({ role: 'member', isActive: true });
  assert.deepEqual((await memberDirectory('reviewer', undefined, sandbox)).members.map(m => m.uid), ['demo', 'reviewer']);
});

test('invalid profile writes fail atomically and cannot corrupt another member', async () => {
  const write = (path, data) => writeData('member', { path, operation: 'update', data }, db);
  await assert.rejects(write('users/member', { photoUrl: 123 }), { status: 400 });
  await assert.rejects(write('users/inactive', { photoUrl: null }), { status: 403 });
  assert.equal((await db.collection('audit_logs').get()).size, 0);
  assert.equal((await db.doc('users/member').get()).data().photoUrl, undefined);
  await write('users/member', { photoUrl: 'https://example.test/photo.png' });
  assert.equal((await db.doc('users/member').get()).data().photoUrl, 'https://example.test/photo.png');
  assert.equal((await db.collection('audit_logs').get()).size, 1);
});
