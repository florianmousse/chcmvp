const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createMember, inviteExistingMember, setMemberActive, deleteMember } = require('../dist/members');
function fixture() {
  const profiles = new Map(), accounts = new Map(), mails = [];
  let sequence = 0;
  const error = code => Object.assign(new Error(code), { code });
  const ref = id => ({ id,
    set: async data => profiles.set(id, structuredClone(data)),
    get: async () => ({ data: () => profiles.get(id) }),
    update: async data => profiles.set(id, { ...profiles.get(id), ...data }),
    delete: async () => profiles.delete(id),
  });
  const deps = {
    db: { collection: () => ({ doc: () => ref(`player-${++sequence}`) }), doc: path => ref(path.split('/')[1]) },
    auth: {
      createUser: async data => {
        if (accounts.has(data.uid)) throw error('auth/uid-already-exists');
        if ([...accounts.values()].some(a => a.email === data.email)) throw error('auth/email-already-exists');
        accounts.set(data.uid, data); return data;
      },
      getUser: async uid => accounts.get(uid),
      updateUser: async (uid, data) => {
        if (!accounts.has(uid)) throw error('auth/user-not-found');
        accounts.set(uid, { ...accounts.get(uid), ...data });
      },
      deleteUser: async uid => { if (!accounts.delete(uid)) throw error('auth/user-not-found'); },
      generatePasswordResetLink: async email => `https://example.test/reset/${email}`,
    },
    sendInvite: async data => mails.push(data),
  };
  return { profiles, accounts, mails, deps };
}
const player = { firstName: 'Camille', lastName: 'Martin', team: 'Seniors' };
test('un joueur sans e-mail est actif sans compte Auth ni invitation', async () => {
  const f = fixture();
  const { uid } = await createMember(player, f.deps);
  assert.equal(f.profiles.get(uid).email, '');
  assert.equal(f.profiles.get(uid).isActive, true);
  assert.equal(f.accounts.size, 0); assert.equal(f.mails.length, 0);
  await setMemberActive(uid, false, f.deps);
  assert.equal(f.profiles.get(uid).isActive, false);
  await setMemberActive(uid, true, f.deps);
  assert.equal(f.profiles.get(uid).isActive, true);
  await deleteMember(uid, f.deps);
  assert.equal(f.profiles.size, 0);
});
test('inviter plus tard conserve UID, date, profil et références des résultats', async () => {
  const f = fixture();
  const { uid } = await createMember(player, f.deps);
  const before = f.profiles.get(uid);
  before.photoUrl = 'https://example.test/avatar.png';
  const result = await inviteExistingMember(uid, { ...player, email: ' CAMILLE@example.test ' }, f.deps);
  assert.equal(result.uid, uid); assert.equal(f.profiles.size, 1);
  assert.equal(f.accounts.get(uid).email, 'camille@example.test');
  assert.equal(f.profiles.get(uid).createdAt, before.createdAt);
  assert.equal(f.profiles.get(uid).photoUrl, before.photoUrl);
  assert.equal(f.mails.length, 1);
  await setMemberActive(uid, false, f.deps);
  assert.equal(f.accounts.get(uid).disabled, true);
  await deleteMember(uid, f.deps);
  assert.equal(f.accounts.size, 0);
});
test('les invitations classiques créent toujours un accès', async () => {
  const f = fixture();
  const { uid } = await createMember({ ...player, email: 'camille@example.test' }, f.deps);
  assert.equal(f.accounts.has(uid), true); assert.equal(f.mails.length, 1);
});
test('un e-mail déjà utilisé ne modifie pas la fiche sans compte', async () => {
  const f = fixture();
  await createMember({ ...player, email: 'existing@example.test' }, f.deps);
  const { uid } = await createMember(player, f.deps);
  await assert.rejects(inviteExistingMember(uid, { email: 'existing@example.test' }, f.deps), /email-already-exists/);
  assert.equal(f.profiles.get(uid).email, '');
  assert.equal(f.accounts.has(uid), false);
});
test('reprise après échec SMTP sans deuxième compte', async () => {
  const f = fixture();
  const { uid } = await createMember(player, f.deps);
  const send = f.deps.sendInvite;
  f.deps.sendInvite = async () => { throw new Error('SMTP unavailable'); };
  await assert.rejects(inviteExistingMember(uid, { email: 'camille@example.test' }, f.deps), /compte est créé/);
  f.deps.sendInvite = send;
  await inviteExistingMember(uid, { email: 'camille@example.test' }, f.deps);
  assert.equal(f.accounts.size, 1); assert.equal(f.profiles.size, 1); assert.equal(f.mails.length, 1);
});
test('validation avant toute création', async () => {
  const f = fixture();
  for (const input of [{ ...player, firstName: ' ' }, { ...player, email: 'bad' }, { ...player, jerseyNumber: -1 }]) {
    await assert.rejects(createMember(input, f.deps));
  }
  assert.equal(f.profiles.size, 0); assert.equal(f.accounts.size, 0);
});
test('un joueur désactivé reste désactivé après invitation', async () => {
  const f = fixture();
  const { uid } = await createMember(player, f.deps);
  await setMemberActive(uid, false, f.deps);
  await inviteExistingMember(uid, { email: 'camille@example.test' }, f.deps);
  assert.equal(f.accounts.get(uid).disabled, true);
  assert.equal(f.profiles.get(uid).isActive, false);
});
