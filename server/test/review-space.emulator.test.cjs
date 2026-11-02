const {test,beforeEach,after}=require('node:test');
const assert=require('node:assert/strict');
const {initializeApp,deleteApp,getApps}=require('firebase-admin/app');
const {getFirestore: firebaseDb,Timestamp}=require('firebase-admin/firestore');
const {getFirestore,inReviewSpace,getReviewSpaceUid,reviewDatabase}=require('../dist/database');
const {ensureReviewSpace,enterRequestSpace}=require('../dist/reviewSpace');
const {writeData}=require('../dist/routes/data');
const {createCeremony,updateCeremony,ceremonyAction,castCeremonyVote}=require('../dist/ceremonies');
const {processCeremonyNotifications}=require('../dist/ceremonyNotifications');
const {createMember,inviteExistingMember,changeMemberEmail,setMemberActive,deleteMember,memberDependencies}=require('../dist/members');
const {deleteMatchAndRebuild}=require('../dist/rebuildRankings');
if(!/^(127\.0\.0\.1|localhost):\d+$/.test(process.env.FIRESTORE_EMULATOR_HOST??'')) throw Error('Local emulator required');
const app=initializeApp({projectId:'demo-chc-full-review'},'full-review-tests');
const production=firebaseDb(app);
const scope=(uid,work)=>inReviewSpace(uid,work,production);
const players=['demo-player-1','demo-player-2','demo-player-3'];
const payload=()=>({date:'2026-12-10T12:00:00.000Z',time:'15:00',team:'Équipe démo',opponent:'Démo',isHome:true,
  status:'upcoming',matchType:'championship',presentPlayerIds:['review',...players],allowSelfVote:false,pointsScale:{first:5,second:3,third:1}});
const ceremony=()=>({title:'Prix démo',category:'ballon_or',topSize:3,allowSelfVote:false,
  voterIds:['review'],nominees:players.map(uid=>({uid}))});
let original;
const productionState=async()=>{
  const out={};
  for(const name of ['users','matches','ceremonies','rankings_cache','userBadges','player_stats','teams','opponents','ceremony_notifications']) {
    out[name]=(await production.collection(name).get()).docs.map(d=>({id:d.id,...d.data()}));
  }
  return JSON.stringify(out);
};
beforeEach(async()=>{
  for(const col of await production.listCollections()) await production.recursiveDelete(col);
  for(const [uid,role] of [['review','reviewer'],['other','reviewer'],['admin','admin'],['member','member']]) {
    await production.doc(`users/${uid}`).set({role,isActive:true,firstName:uid,lastName:'Club',email:`${uid}@example.test`,team:'Club réel',fcmTokens:['production-token']});
  }
  await production.doc('matches/live').set({opponent:'Ne pas toucher',status:'upcoming'});
  await production.doc('ceremonies/live').set({title:'Cérémonie réelle',status:'open'});
  await production.doc('rankings_cache/general').set({entries:{member:{points:99}}});
  original=await productionState();
});
after(async()=>{
  await production.terminate();await deleteApp(app);
  for(const extra of getApps()) await deleteApp(extra);
});

test('bootstrap is isolated, idempotent and only grants synthetic administration',async()=>{
  await Promise.all([ensureReviewSpace('review','review',production),ensureReviewSpace('review','review',production)]);
  const db=reviewDatabase('review',production);
  assert.equal((await db.collection('users').get()).size,6);
  assert.equal((await db.doc('users/review').get()).data().role,'admin');
  assert.equal((await production.doc('users/review').get()).data().role,'reviewer');
  await db.doc('users/demo-player-1').update({firstName:'Modifié'});
  await ensureReviewSpace('review','admin',production);
  assert.equal((await db.doc('users/demo-player-1').get()).data().firstName,'Modifié');
  assert.equal((await db.doc('users/admin').get()).data().role,'admin');
  assert.equal(await productionState(),original);
  assert.throws(()=>db.doc('../users/member'));
  assert.throws(()=>db.doc('review_spaces/other/users/member'));
  assert.throws(()=>db.collectionGroup('votes'));
});

test('ceremony creation, actual voting, reveal, edit, reopen, cancellation and deletion never touch production',async()=>{
  await ensureReviewSpace('review','review',production);
  await scope('review',async()=>{
    const db=getFirestore();
    const event=await createCeremony(ceremony(),'review');
    await ceremonyAction(event,'review','open');
    await castCeremonyVote(event,'review',['n1','n2','n3']);
    await ceremonyAction(event,'review','close');
    assert.equal((await db.doc(`ceremonies/${event}`).get()).data().results[0].uid,players[0]);
    await ceremonyAction(event,'review','reopen');
    await updateCeremony(event,{...ceremony(),resetVotes:true,expectedRevision:0},'review');
    await ceremonyAction(event,'review','cancel');
    assert.equal((await db.doc(`ceremonies/${event}`).get()).data().status,'cancelled');
    assert.equal((await db.collection('ceremony_notifications').get()).size,0);
    // Even an accidentally enqueued review notification cannot be delivered.
    await db.collection('ceremony_notifications').add({done:false,ceremonyId:event,action:'open'});
    await processCeremonyNotifications(db,async()=>{throw Error('A notification escaped');});
    await ceremonyAction(event,'review','delete');
    assert.equal((await db.doc(`ceremonies/${event}`).get()).exists,false);
    await assert.rejects(ceremonyAction('live','review','delete'),{status:404});
  });
  assert.equal(await productionState(),original);
});

test('normal matches with colliding IDs update only sandbox results, rankings and badges',async()=>{
  await ensureReviewSpace('review','review',production);
  await scope('review',async()=>{
    const db=getFirestore();
    await writeData('review',{path:'matches/live',operation:'create',data:payload()});
    await writeData('review',{path:'matches/live',operation:'update',data:{status:'voting_open'}});
    const match=(await db.doc('matches/live').get()).data();assert(match.votingClosesAt instanceof Timestamp);
    await db.doc('matches/live/votes/review').set({voterUid:'review',firstPlaceUid:players[0],secondPlaceUid:players[1],thirdPlaceUid:players[2],votedAt:Timestamp.now()});
    await writeData('review',{path:`matches/live/playerStats/${players[0]}`,operation:'merge',data:{goals:25,assists:0,greenCards:0,yellowCards:0,redCards:0}});
    await writeData('review',{path:'matches/live',operation:'update',data:{status:'voting_closed'}});
    assert.equal((await db.doc('rankings_cache/general').get()).data().entries[players[0]].points,5);
    assert((await db.doc(`userBadges/${players[0]}`).get()).exists);
    assert((await db.doc('matches/live/results/summary').get()).exists);
    assert((await db.collection('audit_logs').get()).size>=4);
    await deleteMatchAndRebuild('live');
    assert.equal((await db.doc('matches/live').get()).exists,false);
  });
  assert.equal(await productionState(),original);
});

test('member lifecycle is fully simulated, with no Firebase Auth accounts or SMTP',async()=>{
  await ensureReviewSpace('review','review',production);
  await scope('review',async()=>{
    const deps=memberDependencies();
    const {uid}=await createMember({firstName:'Test',lastName:'Invité',email:'member@example.test',team:'Équipe démo'},deps);
    await changeMemberEmail(uid,{expectedEmail:'member@example.test',email:'changed@example.test'},deps);
    await setMemberActive(uid,false,deps);
    assert.equal((await deps.db.doc(`users/${uid}`).get()).data().isActive,false);
    const guest=await createMember({firstName:'Sans',lastName:'Compte',email:'',team:'Équipe démo'},deps);
    await inviteExistingMember(guest.uid,{email:'guest@example.test'},deps);
    await deleteMember(uid,deps);
    assert.equal((await deps.db.doc(`users/${uid}`).get()).exists,false);
    const accounts=(await deps.db.collection('simulated_accounts').get()).docs.map(d=>d.data());
    assert(accounts.every(a=>!('password' in a)));
    // Guard the actual delivery functions too, even with a production-looking token/email.
    const {sendInviteEmail,sendPasswordResetEmail}=require('../dist/mailer');
    await sendInviteEmail({to:'member@example.test',firstName:'Test',resetLink:'secret'});
    await sendPasswordResetEmail({to:'member@example.test',resetLink:'secret'});
    const {notifyMembers,notifyAdmins}=require('../dist/notify');
    await notifyMembers({title:'Test',body:'Test'});await notifyAdmins({title:'Test',body:'Test'});
  });
  assert.equal(await productionState(),original);
});

test('scope is forced by real identity and survives concurrent async operations',async()=>{
  async function enter(uid,headers={}) {
    let selected='not-entered',status=200;
    const res={status(code){status=code;return this;},json(){}};
    await enterRequestSpace({uid,headers},res,()=>{selected=getReviewSpaceUid()??'production';},production);
    return {selected,status};
  }
  assert.deepEqual(await enter('review'),{selected:'review',status:200});
  assert.deepEqual(await enter('review',{'x-review-space':'other'}),{selected:'not-entered',status:403});
  assert.deepEqual(await enter('member',{'x-review-space':'review'}),{selected:'not-entered',status:403});
  assert.deepEqual(await enter('admin',{'x-review-space':'review'}),{selected:'review',status:200});
  assert.deepEqual(await enter('admin'),{selected:'production',status:200});
  await ensureReviewSpace('other','other',production);
  await Promise.all(['review','other'].map(uid=>scope(uid,async()=>{
    await new Promise(r=>setTimeout(r,5));
    await writeData(uid,{path:'teams/same-id',operation:'create',data:{name:uid}});
    assert.equal(getReviewSpaceUid(),uid);
  })));
  for(const uid of ['review','other']) assert.equal((await production.doc(`review_spaces/${uid}/teams/same-id`).get()).data().name,uid);
  assert.equal(getReviewSpaceUid(),undefined);
  assert.equal(await productionState(),original);
  await production.doc('users/review').update({isActive:false});
  assert.deepEqual(await enter('review'),{selected:'not-entered',status:403});
  // Admins retain access to the data of a deactivated test account.
  assert.deepEqual(await enter('admin',{'x-review-space':'review'}),{selected:'review',status:200});
});


test('automatic lifecycle runs and calculates results only inside active review spaces',async()=>{
  await ensureReviewSpace('review','review',production);
  await scope('review',async()=>{
    await writeData('review',{path:'matches/automatic',operation:'create',data:{...payload(),date:'2020-01-01T00:00:00.000Z'}});
  });
  const {processReviewSpaces}=require('../dist/reviewMaintenance');
  await processReviewSpaces(production);
  const db=reviewDatabase('review',production);
  assert.equal((await db.doc('matches/automatic').get()).data().status,'voting_closed');
  assert((await db.doc('matches/automatic/results/summary').get()).exists);
  assert.equal(await productionState(),original);
});
