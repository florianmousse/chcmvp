const {test,beforeEach,after} = require('node:test');
const assert=require('node:assert/strict');
const {initializeApp,deleteApp}=require('firebase-admin/app');
const {getFirestore}=require('firebase-admin/firestore');
const {createCeremony,updateCeremony,ceremonyAction,castCeremonyVote}=require('../dist/ceremonies');
const {processCeremonyNotifications}=require('../dist/ceremonyNotifications');
if (!/^(127\.0\.0\.1|localhost):\d+$/.test(process.env.FIRESTORE_EMULATOR_HOST??'')) throw new Error('Émulateur local requis');
const app=initializeApp({projectId:'demo-chc-ceremonies'},'ceremonies-tests');
const db=getFirestore(app);
beforeEach(async()=>{
  for(const collection of await db.listCollections()) await db.recursiveDelete(collection);
  for(const uid of ['admin','v1','v2','u0','u1','u2']) await db.doc(`users/${uid}`).set({firstName:uid,lastName:'Club',email:`${uid}@example.test`,isActive:true,role:uid==='admin'?'admin':'member'});
});
after(async()=>{await db.terminate();await deleteApp(app);});
const payload=()=>({title:'Puskás 2026',category:'puskas',topSize:2,voterIds:['v1','v2'],allowSelfVote:false,nominees:[0,1,2].map(i=>({uid:`u${i}`,label:`But ${i}`}))});
async function opened(){const id=await createCeremony(payload(),'admin',db);await ceremonyAction(id,'admin','open',db);return id;}

test('player awards need no nomination label',async()=>{
  const body={...payload(),category:'ballon_or',nominees:[0,1,2].map(i=>({uid:`u${i}`}))};
  const id=await createCeremony(body,'admin',db);
  const e=(await db.doc(`ceremonies/${id}`).get()).data();
  assert(e.nominees.every(n=>n.label===n.name));
});
test('ceremony pushes target pending voters, then results without spoilers; retries and duplicates are controlled',async()=>{
  const messages=[]; const send=async m=>messages.push(m);
  const id=await opened();
  await ceremonyAction(id,'admin','open',db);
  await assert.rejects(processCeremonyNotifications(db,async()=>{throw new Error('FCM down');}),/FCM down/);
  await Promise.all([processCeremonyNotifications(db,send),processCeremonyNotifications(db,send)]);
  assert.equal(messages.length,1); assert.deepEqual(messages[0].onlyUids,['v1','v2']);
  assert.equal(messages[0].data.ceremonyId,id);
  await castCeremonyVote(id,'v1',['n1','n2'],db);
  await ceremonyAction(id,'admin','close',db);
  await processCeremonyNotifications(db,send);
  assert.equal(messages.length,2); assert(messages[1].onlyUids.includes('u0'));
  assert(!messages[1].body.includes('u0')); assert.equal(messages[1].data.type,'ceremony_results');
  await ceremonyAction(id,'admin','reopen',db);
  await processCeremonyNotifications(db,send);
  assert.deepEqual(messages[2].onlyUids,['v2']);
  await processCeremonyNotifications(db,send); assert.equal(messages.length,3);
});
test('stale ceremony notifications are discarded after editing or deletion',async()=>{
  const id=await opened(); const messages=[];
  await updateCeremony(id,{...payload(),resetVotes:true,expectedRevision:0},'admin',db);
  await processCeremonyNotifications(db,async m=>messages.push(m)); assert.equal(messages.length,0);
  await ceremonyAction(id,'admin','open',db);
  await ceremonyAction(id,'admin','delete',db);
  await processCeremonyNotifications(db,async m=>messages.push(m)); assert.equal(messages.length,0);
});

test('admin can reopen with valid votes retained; trophies disappear until reclosing',async()=>{
  const id=await opened();
  await castCeremonyVote(id,'v1',['n1','n2'],db);
  await ceremonyAction(id,'admin','close',db);
  await assert.rejects(ceremonyAction(id,'v1','reopen',db),{status:403});
  await ceremonyAction(id,'admin','reopen',db);
  const e=(await db.doc(`ceremonies/${id}`).get()).data();
  assert.equal(e.status,'open'); assert.deepEqual(e.results,[]); assert.equal(e.voteCount,1);
  await assert.rejects(castCeremonyVote(id,'v1',['n2','n1'],db),{status:409});
  await castCeremonyVote(id,'v2',['n2','n1'],db);
  await ceremonyAction(id,'admin','close',db);
  assert.equal((await db.doc(`ceremonies/${id}`).get()).data().voteCount,2);
});

test('editing resets ballots and trophies; stale forms and ballots cannot affect the new vote',async()=>{
  const id=await opened(); await castCeremonyVote(id,'v1',['n1','n2'],db);
  await ceremonyAction(id,'admin','close',db);
  const changed={...payload(),title:'Prix corrigé',resetVotes:true,expectedRevision:0};
  await assert.rejects(updateCeremony(id,changed,'v1',db),{status:403});
  await assert.rejects(updateCeremony(id,{...changed,resetVotes:false},'admin',db));
  await updateCeremony(id,changed,'admin',db);
  const e=(await db.doc(`ceremonies/${id}`).get()).data();
  assert.equal(e.status,'draft');assert.equal(e.revision,1);assert.equal(e.voteCount,0);assert.deepEqual(e.results,[]);
  await assert.rejects(updateCeremony(id,changed,'admin',db),{status:409});
  await ceremonyAction(id,'admin','open',db);
  await assert.rejects(castCeremonyVote(id,'v1',['n1','n2'],db,0),{status:409});
  await castCeremonyVote(id,'v2',['n3','n2'],db,1);
  await ceremonyAction(id,'admin','close',db);
  const result=(await db.doc(`ceremonies/${id}`).get()).data();
  assert.equal(result.voteCount,1); assert.equal(result.results[0].id,'n3');
  await ceremonyAction(id,'admin','reopen',db);
  await castCeremonyVote(id,'v1',['n1','n2'],db,1);
  assert.equal((await db.doc(`ceremonies/${id}`).get()).data().voteCount,2);
});

test('deletion removes the whole ceremony including old ballots, even racing with a vote',async()=>{
  const id=await opened(); await castCeremonyVote(id,'v1',['n1','n2'],db);
  await assert.rejects(ceremonyAction(id,'v1','delete',db),{status:403});
  await Promise.allSettled([ceremonyAction(id,'admin','delete',db),castCeremonyVote(id,'v2',['n3','n2'],db)]);
  assert(!(await db.doc(`ceremonies/${id}`).get()).exists);
  assert.equal((await db.collection(`ceremonies/${id}/votes`).get()).size,0);
});

test('a vote racing with editing cannot leak into the replacement ballot',async()=>{
  const id=await opened();
  const outcomes=await Promise.allSettled([
    updateCeremony(id,{...payload(),resetVotes:true,expectedRevision:0},'admin',db),
    castCeremonyVote(id,'v1',['n1','n2'],db),
  ]);
  assert.equal(outcomes[0].status,'fulfilled');
  await ceremonyAction(id,'admin','open',db);
  await ceremonyAction(id,'admin','close',db);
  const event=(await db.doc(`ceremonies/${id}`).get()).data();
  assert.equal(event.revision,1); assert.equal(event.voteCount,0); assert.deepEqual(event.results,[]);
});

test('reopening repairs legacy votes containing two nominations for the same player',async()=>{
  const id=await opened();const ref=db.doc(`ceremonies/${id}`);
  const e=(await ref.get()).data();e.nominees[1].uid=e.nominees[0].uid;
  await ref.update({nominees:e.nominees,status:'closed',voteCount:1,results:[{rank:1,uid:'u0'}]});
  await ref.collection('votes').doc('v1').set({choices:['n1','n2']});
  await ceremonyAction(id,'admin','reopen',db);
  assert.equal((await ref.get()).data().voteCount,0);
  await castCeremonyVote(id,'v1',['n1','n3'],db);
  assert.equal((await ref.get()).data().voteCount,1);
});
test('non admins cannot create or publish; guests can be nominated but cannot be voters',async()=>{
  await assert.rejects(createCeremony(payload(),'v1',db),{status:403});
  await db.doc('users/u0').update({email:''});
  const id=await createCeremony(payload(),'admin',db);
  await assert.rejects(ceremonyAction(id,'v1','open',db),{status:403});
  await assert.rejects(createCeremony({...payload(),voterIds:['u0']},'admin',db));
});
test('concurrent duplicate ballots counted once; closed results immutable and no match points',async()=>{
  const id=await opened();
  await Promise.all([castCeremonyVote(id,'v1',['n1','n2'],db),castCeremonyVote(id,'v1',['n1','n2'],db)]);
  await assert.rejects(castCeremonyVote(id,'v1',['n2','n1'],db),{status:409});
  await castCeremonyVote(id,'v2',['n2','n1'],db);
  await Promise.all([ceremonyAction(id,'admin','close',db),ceremonyAction(id,'admin','close',db)]);
  const event=(await db.doc(`ceremonies/${id}`).get()).data();
  assert.equal(event.voteCount,2); assert.equal(event.status,'closed');
  assert.deepEqual(event.results.map(r=>r.rank),[1,1]);
  await assert.rejects(castCeremonyVote(id,'v2',['n2','n1'],db),{status:409});
  assert.equal((await db.collection('rankings_cache').get()).size,0);
  assert.equal((await db.collection('userBadges').get()).size,0);
});
test('closing concurrently with last ballot includes it or rejects it, never loses it',async()=>{
  const id=await opened();
  const [vote]=await Promise.allSettled([castCeremonyVote(id,'v1',['n1','n2'],db),ceremonyAction(id,'admin','close',db)]);
  const event=(await db.doc(`ceremonies/${id}`).get()).data();
  const accepted=vote.status==='fulfilled';
  assert.equal(event.voteCount,accepted?1:0);
  assert.equal(event.results.length,accepted?2:0);
});
test('cancelled or empty ceremonies never award trophies; deactivated voters rejected',async()=>{
  const id=await opened();
  await db.doc('users/v1').update({isActive:false});
  await assert.rejects(castCeremonyVote(id,'v1',['n1','n2'],db),{status:403});
  await ceremonyAction(id,'admin','cancel',db);
  await assert.rejects(castCeremonyVote(id,'v2',['n1','n2'],db),{status:409});
  assert.equal((await db.doc(`ceremonies/${id}`).get()).data().results,undefined);
  await db.doc('users/v1').update({isActive:true});
  const empty=await opened();await ceremonyAction(empty,'admin','close',db);
  assert.deepEqual((await db.doc(`ceremonies/${empty}`).get()).data().results,[]);
});
