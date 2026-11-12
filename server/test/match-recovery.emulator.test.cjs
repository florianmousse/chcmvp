const {test,beforeEach,after}=require('node:test');
const assert=require('node:assert/strict');
const {initializeApp,deleteApp,getApps}=require('firebase-admin/app');
const {getFirestore,Timestamp}=require('firebase-admin/firestore');
const {repairClosedMatch,reconcileMatches}=require('../dist/matchRecovery');
const {writeData}=require('../dist/routes/data');
const {reopenVoting}=require('../dist/votingLifecycle');
if(!/^(127\.0\.0\.1|localhost):\d+$/.test(process.env.FIRESTORE_EMULATOR_HOST??'')) throw Error('Local emulator required');
const app=initializeApp({projectId:'demo-chc-recovery'},'recovery');
const db=getFirestore(app);
beforeEach(async()=>{
  for(const collection of await db.listCollections()) await db.recursiveDelete(collection);
  await db.doc('users/admin').set({role:'admin',isActive:true});
  for(const uid of ['a','b','c','d']) await db.doc(`users/${uid}`).set({role:'member',isActive:true});
});
after(async()=>{await db.terminate();for(const instance of getApps()) await deleteApp(instance);});
const data=async path=>(await db.doc(path).get()).data();
async function seed(id='closed') {
  const ref=db.doc(`matches/${id}`);
  await ref.set({status:'voting_closed',date:Timestamp.fromDate(new Date('2026-10-11T12:00:00Z')),
    time:'15:00',team:'Démo',opponent:'Fixture',isHome:true,allowSelfVote:false,
    presentPlayerIds:['a','b','c','d'],pointsScale:{first:5,second:3,third:1}});
  await ref.collection('votes').doc('d').set({voterUid:'d',firstPlaceUid:'a',secondPlaceUid:'b',thirdPlaceUid:'c'});
  await ref.collection('playerStats').doc('a').set({goals:5,assists:0,greenCards:0,yellowCards:0,redCards:0});
  return ref;
}
test('restart repairs closed results and missing deadlines, without replaying badge alerts',async()=>{
  await seed();
  await db.doc('matches/open').set({status:'voting_open',votingClosesAt:null});
  await db.doc('matches/manual').set({status:'voting_open',manualCloseRequired:true,votingClosesAt:null});
  await reconcileMatches(48,db);
  assert.equal((await data('rankings_cache/general')).entries.a.points,5);
  assert((await data('matches/open')).votingClosesAt instanceof Timestamp);
  assert.equal((await data('matches/manual')).votingClosesAt,null);
  assert.equal((await data('userBadges/a')).silent,true);
  const computed=(await data('matches/closed/results/summary')).computedAt;
  await reconcileMatches(48,db);
  assert(computed.isEqual((await data('matches/closed/results/summary')).computedAt));
});
test('failed acknowledgement is retried with no duplicate points',async()=>{
  await seed();let failed=false;
  const unreliable=new Proxy(db,{get(target,key){
    if(key==='runTransaction') return async (...args)=>{if(!failed){failed=true;throw Error('Synthetic failure');}return target.runTransaction(...args);};
    const value=Reflect.get(target,key,target);return typeof value==='function'?value.bind(target):value;
  }});
  await assert.rejects(repairClosedMatch('closed',unreliable),/Synthetic failure/);
  assert.equal((await data('matches/closed')).resultsSourceFingerprint,undefined);
  await repairClosedMatch('closed',db);
  assert.equal((await data('rankings_cache/general')).entries.a.points,5);
  assert.equal(typeof (await data('matches/closed')).resultsSourceFingerprint,'string');
});
test('editing closed dates and points repairs every scope and reopening invalidates the marker',async()=>{
  await seed();await repairClosedMatch('closed',db);
  await writeData('admin',{path:'matches/closed',operation:'update',data:{
    civilDate:'2027-09-02',date:'2027-09-01T15:00:00Z',pointsScale:{first:8,second:4,third:2},
  }},db);
  assert.equal((await data('rankings_cache/general')).entries.a.points,8);
  assert.equal(await data('rankings_cache/2026-2027'),undefined);
  assert.equal((await data('rankings_cache/2027-2028')).entries.a.points,8);
  await reopenVoting('closed','admin',db);
  assert.equal((await data('matches/closed')).resultsSourceFingerprint,null);
  await db.doc('matches/closed/votes/d').delete();
  await writeData('admin',{path:'matches/closed',operation:'update',data:{status:'voting_closed'}},db);
  assert.equal((await data('matches/closed/results/summary')).totalVotes,0);
});
test('server refuses opening with too few distinct players or an inactive actor',async()=>{
  const ref=await seed();await ref.update({status:'upcoming',presentPlayerIds:['a','a','b']});
  const input={path:'matches/closed',operation:'update',data:{status:'voting_open'}};
  await assert.rejects(writeData('admin',input,db),{status:400});
  await db.doc('users/admin').update({isActive:false});
  await assert.rejects(writeData('admin',input,db),{status:403});
});

test('an edit racing with acknowledgement stays pending and is repaired on the next pass',async()=>{
  const ref=await seed();let edited=false;
  const racing=new Proxy(db,{get(target,key){
    if(key==='runTransaction') return async (...args)=>{
      if(!edited){edited=true;await ref.update({pointsScale:{first:9,second:4,third:2}});}
      return target.runTransaction(...args);
    };
    const value=Reflect.get(target,key,target);return typeof value==='function'?value.bind(target):value;
  }});
  await repairClosedMatch('closed',racing);
  assert.equal((await data('matches/closed')).resultsSourceFingerprint,undefined);
  await repairClosedMatch('closed',db);
  assert.equal((await data('rankings_cache/general')).entries.a.points,9);
});
