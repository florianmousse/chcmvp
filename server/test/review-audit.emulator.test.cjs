const {test,beforeEach,after}=require('node:test');
const assert=require('node:assert/strict');
const {initializeApp,deleteApp}=require('firebase-admin/app');
const {getFirestore}=require('firebase-admin/firestore');
const {writeData}=require('../dist/routes/data');
const {saveTestVote}=require('../dist/testVotes');
const {reopenVoting}=require('../dist/votingLifecycle');
const {suppressMatchNotification}=require('../dist/reviewAccess');
const {notificationTokens}=require('../dist/notificationAudience');
if (!/^(127\.0\.0\.1|localhost):\d+$/.test(process.env.FIRESTORE_EMULATOR_HOST??'')) throw Error('Local emulator required');
const app=initializeApp({projectId:'demo-chc-review'});
const db=getFirestore(app);
const read=async path=>(await db.doc(path).get()).data();
const match=()=>({date:'2026-11-10T12:00:00Z',time:'15:00',team:'Seniors',opponent:'Rennes',isHome:true,
  status:'upcoming',matchType:'championship',presentPlayerIds:['a','b','c','d'],allowSelfVote:false,
  pointsScale:{first:5,second:3,third:1}});
const create=(uid,path)=>writeData(uid,{path,operation:'create',data:match()},db);
beforeEach(async()=>{
  for(const col of await db.listCollections()) await db.recursiveDelete(col);
  for(const [uid,role] of [['admin','admin'],['review','reviewer'],['other','reviewer'],['member','member']])
    await db.doc(`users/${uid}`).set({role,isActive:true,firstName:uid,lastName:'Club',fcmTokens:['secret-token']});
});
after(async()=>{await db.terminate();await deleteApp(app);});

test('review writes are isolated, server marked, immutable and audited atomically',async()=>{
  await assert.rejects(create('review','matches/real'),{status:403});
  await assert.rejects(create('member','test_matches/test:member'),{status:403});
  await create('review','test_matches/test:owned');
  const data=await read('test_matches/test:owned');
  assert.equal(data.reviewCreatedBy,'review');
  assert.equal(data.reviewSource,'Équipe de validation');
  assert.equal(data.date.toDate().toISOString(),new Date(match().date).toISOString());
  for(const path of ['teams/t','opponents/o','users/admin','settings/global','audit_logs/forged']) {
    await assert.rejects(writeData('review',{path,operation:'update',data:{name:'Changed'}},db));
  }
  await assert.rejects(writeData('review',{path:'test_matches/test:owned',operation:'update',data:{reviewCreatedBy:'other'}},db),{status:400});
  await assert.rejects(writeData('other',{path:'test_matches/test:owned',operation:'update',data:{opponent:'Hacked'}},db),{status:403});
  await writeData('admin',{path:'test_matches/test:owned',operation:'update',data:{opponent:'Updated'}},db);
  assert.equal((await read('test_matches/test:owned')).reviewCreatedBy,'review');
  const logs=(await db.collection('audit_logs').orderBy('at').get()).docs.map(d=>d.data());
  assert.equal(logs.length,2);
  assert.equal(logs[0].actorUid,'review');assert.equal(logs[0].actorRole,'reviewer');
  assert.equal(logs[1].before.opponent,'Rennes');assert.equal(logs[1].after.opponent,'Updated');
  assert(logs.every(l=>l.at.toMillis()>0&&l.status==='success'));
  assert(!JSON.stringify(logs).includes('secret-token'));
  assert.equal((await db.collection('matches').get()).size,0);
});

test('simulation, reopen and notifications respect owner scope, including deleted tests',async()=>{
  await create('review','test_matches/test:owned');
  await create('admin','test_matches/test:admin');
  await writeData('review',{path:'test_matches/test:owned',operation:'update',data:{status:'voting_open'}},db);
  const ballot={voterUid:'d',firstPlaceUid:'a',secondPlaceUid:'b',thirdPlaceUid:'c'};
  await saveTestVote('test:owned','review',ballot,db);
  await assert.rejects(saveTestVote('test:owned','other',ballot,db),{status:403});
  await writeData('review',{path:'test_matches/test:owned',operation:'update',data:{status:'voting_closed'}},db);
  await reopenVoting('test:owned','review',db);
  await assert.rejects(reopenVoting('test:owned','other',db),{status:403});
  assert.equal(await suppressMatchNotification('test:owned',db),true);
  assert.equal(await suppressMatchNotification('test:deleted',db),true);
  assert.equal(await suppressMatchNotification('test:admin',db),false);
  assert.equal(await suppressMatchNotification('real',db),false);
  assert.deepEqual(notificationTokens([{uid:'review',role:'reviewer',isActive:true,fcmTokens:['secret-token']}],{}),[]);
});

test('inactive reviewers cannot write; profile audit omits secrets; deletes preserve history',async()=>{
  await create('review','test_matches/test:owned');
  await db.doc('users/review').update({isActive:false});
  await assert.rejects(writeData('review',{path:'test_matches/test:owned',operation:'update',data:{opponent:'Blocked'}},db),{status:403});
  await writeData('member',{path:'users/member',operation:'update',data:{firstName:'New'}},db);
  await writeData('admin',{path:'teams/t',operation:'create',data:{name:'Team'}},db);
  await writeData('admin',{path:'teams/t',operation:'delete'},db);
  const logs=(await db.collection('audit_logs').get()).docs.map(d=>d.data());
  assert(!JSON.stringify(logs).includes('secret-token'));
  const removed=logs.find(l=>l.action==='delete');assert.deepEqual(removed.before,{name:'Team'});assert.equal(removed.after,null);
  assert.equal((await db.doc('teams/t').get()).exists,false);
});

test('real match rejects reviewer attendance and invalid lifecycle bypasses',async()=>{
  await assert.rejects(writeData('admin',{path:'matches/bad',operation:'create',data:{...match(),presentPlayerIds:['review']}},db),{status:400});
  await create('admin','matches/real');
  await writeData('admin',{path:'matches/real',operation:'update',data:{status:'voting_closed'}},db);
  await assert.rejects(writeData('admin',{path:'matches/real',operation:'update',data:{status:'voting_open'}},db),{status:409});
  await assert.rejects(writeData('admin',{path:'matches/real',operation:'update',data:{manualCloseRequired:false}},db),{status:400});
  assert.equal((await read('matches/real')).status,'voting_closed');
});


test('match API guard blocks real operations, rebuilds, other reviewers and inactive accounts',async()=>{
  const {requireMatchAccess}=require('../dist/middleware/auth');
  await create('review','test_matches/test:owned');
  async function allowed(uid,path) {
    let passed=false;
    const res={status(){return this;},json(){}};
    await requireMatchAccess({uid,path},res,()=>{passed=true;});
    return passed;
  }
  assert.equal(await allowed('review','/test:owned/recompute'),true);
  assert.equal(await allowed('admin','/rankings/rebuild'),true);
  for(const path of ['/real/recompute','/rankings/rebuild','/test:missing','/test%3Aowned%2Fvotes'])
    assert.equal(await allowed('review',path),false,path);
  assert.equal(await allowed('other','/test:owned'),false);
  await db.doc('users/review').update({isActive:false});
  assert.equal(await allowed('review','/test:owned'),false);
});

test('API audit persists attempts and outcomes but never credentials or ballots',async()=>{
  const {EventEmitter}=require('node:events');
  const {auditRequest}=require('../dist/audit');
  let calls=0;
  const res=new EventEmitter();res.statusCode=200;res.status=function(code){this.statusCode=code;return this;};res.json=()=>res;
  await auditRequest({uid:'admin',method:'POST',originalUrl:'/members/review-account?secret=hidden',body:{password:'secret-password',choices:['private-ballot']}},res,()=>calls++);
  assert.equal(calls,1);
  const entry=(await db.collection('audit_logs').get()).docs[0];
  assert.equal(entry.data().status,'pending');
  res.json({uid:'new-user',password:'returned-secret'});
  const completed=new Promise((resolve,reject)=>{
    const timer=setTimeout(()=>{stop();reject(Error('Audit completion timed out'));},5000);
    const stop=entry.ref.onSnapshot(s=>{if(s.data().status==='success'){clearTimeout(timer);stop();resolve(s.data());}},reject);
  });
  res.emit('finish');
  const log=await completed;
  assert.equal(log.resultId,'new-user');
  assert.equal(log.target,'/members/review-account');
  assert(!JSON.stringify(log).includes('secret'));assert(!JSON.stringify(log).includes('private-ballot'));
});
