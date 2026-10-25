import { before, test } from 'node:test';
import assert from 'node:assert/strict';

// Uniquement l'émulateur avec un projet de démonstration : aucun accès production.
const project = 'demo-chc-web';
const host = process.env.FIRESTORE_EMULATOR_HOST;
if (!host || !/^(127\.0\.0\.1|localhost):\d+$/.test(host)) throw new Error('Émulateur local requis');
const database = `projects/${project}/databases/(default)`;
const base = `http://${host}/v1/${database}/documents`;
const value = v => v === null ? { nullValue:null }
  : v instanceof Date ? { timestampValue:v.toISOString() }
  : Array.isArray(v) ? { arrayValue:{ values:v.map(value) } }
  : typeof v === 'boolean' ? { booleanValue:v }
  : typeof v === 'number' ? { integerValue:String(v) }
  : typeof v === 'object' ? { mapValue:{ fields:fields(v) } }
  : { stringValue:String(v) };
const fields = obj => Object.fromEntries(Object.entries(obj).map(([key, v]) => [key, value(v)]));
function token(uid) {
  const encode = obj => Buffer.from(JSON.stringify(obj)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  return `${encode({ alg:'none', typ:'JWT' })}.${encode({ sub:uid, user_id:uid, aud:project, iss:`https://securetoken.google.com/${project}`, iat:now, exp:now + 3600, firebase:{ sign_in_provider:'custom' } })}.`;
}
async function seed(path, data) {
  const res = await fetch(`${base}/${path}`, { method:'PATCH', headers:{ Authorization:'Bearer owner', 'Content-Type':'application/json' }, body:JSON.stringify({ fields:fields(data) }) });
  assert.equal(res.status, 200, await res.text());
}
async function vote(match, uid = 'voter', choices = ['a','b','c'], extras = {}) {
  return fetch(`${base}:commit`, { method:'POST', headers:{ Authorization:`Bearer ${token(uid)}`, 'Content-Type':'application/json' }, body:JSON.stringify({ writes:[{
    update:{ name:`${database}/documents/matches/${match}/votes/${uid}`, fields:fields({ voterUid:uid, firstPlaceUid:choices[0], secondPlaceUid:choices[1], thirdPlaceUid:choices[2], ...extras }) },
    updateTransforms:[{ fieldPath:'votedAt', setToServerValue:'REQUEST_TIME' }]
  }] }) });
}
const match = { status:'voting_open', presentPlayerIds:['voter','a','b','c'], allowSelfVote:false, votingOpensAt:new Date(Date.now() - 3600000), votingClosesAt:new Date(Date.now() + 3600000) };
before(async () => {
  await seed('users/admin', { isActive:true, role:'admin' });
  await seed('users/inactive-admin', { isActive:false, role:'admin' });
  for (const uid of ['voter','a','b','c','absent']) await seed(`users/${uid}`, { isActive:true, role:'member' });
  await seed('users/inactive', { isActive:false, role:'member' });
});
test("Vote valide, double vote et lecture du bulletin d'un autre membre", async () => {
  await seed('matches/valid', match);
  const accepted = await vote('valid');
  assert.equal(accepted.status, 200, await accepted.text());
  assert.equal((await vote('valid')).status, 403);
  const otherRead = await fetch(`${base}/matches/valid/votes/voter`, { headers:{ Authorization:`Bearer ${token('a')}` } });
  assert.equal(otherRead.status, 403);
});

test('Seul le serveur peut supprimer un bulletin ; son auteur peut ensuite voter à nouveau', async () => {
  await seed('matches/reset', match);
  assert.equal((await vote('reset')).status,200);
  for (const uid of ['voter','admin']) {
    const denied = await fetch(`${base}/matches/reset/votes/voter`, {
      method:'DELETE', headers:{Authorization:`Bearer ${token(uid)}`},
    });
    assert.equal(denied.status,403);
  }
  const removed = await fetch(`${base}/matches/reset/votes/voter`, {
    method:'DELETE',headers:{Authorization:'Bearer owner'},
  });
  assert.equal(removed.status,200);
  assert.equal((await vote('reset','voter',['c','b','a'])).status,200);
  assert.equal((await vote('reset')).status,403);
});
for (const scenario of [
  { name:'joueur absent', uid:'absent' },
  { name:'joueur inactif', uid:'inactive', override:{ presentPlayerIds:['inactive','a','b','c'] } },
  { name:'candidat absent', choices:['a','b','absent'] },
  { name:'doublon', choices:['a','a','c'] },
  { name:'auto-vote interdit', choices:['voter','b','c'] },
  { name:'vote fermé', override:{ status:'voting_closed' } },
  { name:'date limite dépassée', override:{ votingClosesAt:new Date(Date.now() - 10000) } },
  { name:'vote pas encore ouvert', override:{ votingOpensAt:new Date(Date.now() + 100000) } },
  { name:'auteur falsifié', extras:{ voterUid:'other' } },
  { name:'champ supplémentaire', extras:{ admin:true } },
]) {
  test(`Refus : ${scenario.name}`, async () => {
    const id = encodeURIComponent(scenario.name).replaceAll('%', '_');
    await seed(`matches/${id}`, { ...match, ...scenario.override });
    const result = await vote(id, scenario.uid, scenario.choices, scenario.extras);
    assert.equal(result.status, 403, await result.text());
  });
}
test('Auto-vote autorisé et ancien match sans dates', async () => {
  await seed('matches/self', { status:'voting_open', presentPlayerIds:match.presentPlayerIds, allowSelfVote:true });
  const result = await vote('self', 'voter', ['voter','b','c']);
  assert.equal(result.status, 200, await result.text());
});

test('Un joueur sans e-mail ni compte Auth peut recevoir un vote', async () => {
  await seed('users/guest', { firstName:'Alex', lastName:'Martin', email:'', isActive:true, role:'member' });
  await seed('matches/guest-candidate', { ...match, presentPlayerIds:['voter','guest','b','c'] });
  const result = await vote('guest-candidate', 'voter', ['guest','b','c']);
  assert.equal(result.status, 200, await result.text());
});

async function access(path, uid, body) {
  return fetch(`${base}/${path}`, {
    method:body ? 'PATCH' : 'GET',
    headers:{ Authorization:`Bearer ${token(uid)}`, 'Content-Type':'application/json' },
    ...(body ? { body:JSON.stringify({ fields:fields(body) }) } : {}),
  });
}

test('Reopening is server-only; manual deadlines cannot be restored by a client', async () => {
  for (const path of ['matches/reopened','test_matches/test:reopened']) {
    await seed(path,{...match,status:'voting_closed'});
    assert.equal((await access(path,'admin',{...match,status:'voting_open'})).status,403);
    assert.equal((await access(path,'admin',{...match,status:'upcoming'})).status,403);
    const manual={...match,status:'voting_open',manualCloseRequired:true,votingClosesAt:null};
    await seed(path,manual);
    assert.equal((await access(path,'admin',{...manual,status:'voting_closed'})).status,200);
    await seed(path,manual);
    assert.equal((await access(path,'admin',{...manual,manualCloseRequired:false})).status,403);
    assert.equal((await access(path,'admin',{...manual,votingClosesAt:new Date()})).status,403);
    assert.equal((await access(path,'admin',{...manual,status:'upcoming'})).status,403);
  }
});

test('Reopened real match accepts a missing ballot, never a second ballot', async () => {
  await seed('matches/reopen-ballot',{...match,manualCloseRequired:true,votingClosesAt:null});
  assert.equal((await vote('reopen-ballot')).status,200);
  await seed('matches/reopen-ballot',{...match,status:'voting_closed'});
  await seed('matches/reopen-ballot',{...match,manualCloseRequired:true,votingClosesAt:null});
  assert.equal((await vote('reopen-ballot')).status,403);
  assert.equal((await vote('reopen-ballot','a',['voter','b','c'])).status,200);
});

test('Les tests et leurs sous-collections sont lisibles uniquement par les admins actifs', async () => {
  await seed('test_matches/test:private', match);
  await seed('test_matches/test:private/votes/voter', { voterUid:'voter' });
  await seed('test_matches/test:private/results/summary', { totalVotes:1 });
  await seed('test_matches/test:private/playerStats/a', { goals:1 });
  for (const path of ['test_matches', 'test_matches/test:private',
    'test_matches/test:private/votes/voter', 'test_matches/test:private/results/summary',
    'test_matches/test:private/playerStats/a']) {
    assert.equal((await access(path, 'admin')).status, 200, path);
    for (const uid of ['voter','inactive-admin']) assert.equal((await access(path, uid)).status, 403, `${uid}: ${path}`);
  }
  assert.equal((await access('matches', 'voter')).status, 200);
});

test('Création des tests protégée et bulletins simulés réservés au serveur', async () => {
  assert.equal((await access('test_matches/test:created', 'admin', match)).status, 200);
  assert.equal((await access('test_matches/test:denied', 'voter', match)).status, 403);
  assert.equal((await access('test_matches/test:inactive', 'inactive-admin', match)).status, 403);
  assert.equal((await access('test_matches/unprefixed', 'admin', match)).status, 403);
  assert.equal((await access('matches/test:public', 'admin', match)).status, 403);
  for (const uid of ['admin','voter']) {
    assert.equal((await access('test_matches/test:created/votes/voter', uid, { voterUid:'voter' })).status, 403);
  }
});

test('Un client ne peut pas réattribuer un badge révoqué, même admin', async () => {
  await seed('userBadges/voter', { earned:{} });
  for (const uid of ['voter','admin']) {
    assert.equal((await access('userBadges/voter', uid, { earned:{ fairPlay:new Date() } })).status, 403);
    assert.equal((await access('userBadges/voter', uid)).status, 200);
  }
});
