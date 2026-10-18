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
