const {test}=require('node:test');
const assert=require('node:assert/strict');
const {spawnSync}=require('node:child_process');
const {Timestamp}=require('firebase-admin/firestore');
const {matchDateTime}=require('../dist/matchTime');
const {sendInviteEmail,sendPasswordResetEmail}=require('../dist/mailer');

test('missing SMTP rejects both deliveries without logging recipients or reset links',async()=>{
  const previous=[process.env.SMTP_USER,process.env.SMTP_APP_PASSWORD];
  delete process.env.SMTP_USER;delete process.env.SMTP_APP_PASSWORD;
  const logs=[];const error=console.error;console.error=(...args)=>logs.push(args.join(' '));
  try {
    const payload={to:'private-fixture@example.invalid',firstName:'Fixture',resetLink:'https://example.invalid/?oobCode=SYNTHETIC_SECRET'};
    await assert.rejects(sendInviteEmail(payload),{code:'SMTP_NOT_CONFIGURED'});
    await assert.rejects(sendPasswordResetEmail(payload),{code:'SMTP_NOT_CONFIGURED'});
    assert.equal(logs.length,2);
    assert(logs.every(line=>line.includes('ERREUR') && line.includes('mail.configuration')));
    assert(!logs.join('\n').includes(payload.to));assert(!logs.join('\n').includes('SYNTHETIC_SECRET'));
  } finally {
    console.error=error;
    for(const [i,key] of ['SMTP_USER','SMTP_APP_PASSWORD'].entries()) {
      if(previous[i]===undefined) delete process.env[key];else process.env[key]=previous[i];
    }
  }
});

test('Paris calendar is independent of the server timezone, in summer and winter',()=>{
  for(const tz of ['UTC','Europe/Paris','America/New_York']) {
    const result=spawnSync(process.execPath,['-e',`
      const {matchDateTime}=require('./dist/matchTime');
      const {Timestamp}=require('firebase-admin/firestore');
      console.log(JSON.stringify(['2026-07-10T22:00:00Z','2026-01-10T23:00:00Z'].map(value=>
        new Date(matchDateTime(Timestamp.fromDate(new Date(value)),'15:00')).toISOString())));
    `],{cwd:require('node:path').resolve(__dirname,'..'),env:{...process.env,TZ:tz},encoding:'utf8'});
    assert.equal(result.status,0,result.stderr);
    assert.deepEqual(JSON.parse(result.stdout),['2026-07-11T13:00:00.000Z','2026-01-11T14:00:00.000Z']);
  }
});

test('civil dates from another device timezone and DST transitions have explicit semantics',()=>{
  const timestamp=Timestamp.fromDate(new Date('2026-07-10T15:00:00Z'));
  const iso=(civil,time)=>new Date(matchDateTime(timestamp,time,civil)).toISOString();
  assert.equal(iso('2026-07-11','15:00'),'2026-07-11T13:00:00.000Z');
  assert.throws(()=>iso('2026-03-29','02:30'));
  assert.equal(iso('2026-10-25','02:30'),'2026-10-25T00:30:00.000Z');
  assert.throws(()=>iso('2026-02-30','15:00'));
  assert.throws(()=>iso('2026-07-11','25:00'));
});

test('an empty presence never reaches Firestore or the notification sender',async()=>{
  const {sendReminderToNonVoters}=require('../dist/scheduledVoting');
  await sendReminderToNonVoters('fixture',{presentPlayerIds:[]});
});
