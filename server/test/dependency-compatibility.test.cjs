const { test } = require('node:test');
const assert = require('node:assert/strict');
const nodemailer = require('nodemailer');
const cron = require('node-cron');

test('updated mailer composes club invitations without contacting SMTP', async () => {
  const transport = nodemailer.createTransport({streamTransport:true,buffer:true,newline:'unix'});
  const result = await transport.sendMail({
    from:'CHC MVP <club@example.test>', to:'Joueur <joueur@example.test>',
    subject:'Invitation Châteaubourg',
    text:'Active ton compte : https://example.test/invitation',
    html:'<p>Active ton compte : <a href="https://example.test/invitation">Connexion</a></p>',
  });
  assert.deepEqual(result.envelope.to,['joueur@example.test']);
  const message=result.message.toString();
  assert(message.includes('multipart/alternative'));
  assert(message.includes('https://example.test/invitation'));
});

test('updated scheduler accepts and executes the existing ten-minute job', async () => {
  assert(cron.validate('*/10 * * * *'));
  let calls=0;
  const task=cron.schedule('*/10 * * * *',()=>{calls++;});
  try {
    assert.equal(task.getStatus(),'idle');
    await task.stop();
    await task.execute();
    assert.equal(calls,1);
  } finally { await task.destroy(); }
});
