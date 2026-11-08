import { Firestore, Timestamp } from 'firebase-admin/firestore';
import { reviewDatabaseOwner } from './database';
import { Ceremony, validateBallot } from './ceremonies';

type Sender = (message: { title: string; body: string; onlyUids: string[]; data: Record<string, string> }) => Promise<void>;

// Persistent outbox: transitions are recorded in the same transaction as the
// ceremony. A lease prevents simultaneous workers from sending the same job.
// Delivery is at-least-once if the process stops after FCM accepts the message.
export async function processCeremonyNotifications(db: Firestore, send: Sender) {
  if (reviewDatabaseOwner(db)) return;
  const pending = await db.collection('ceremony_notifications').where('done', '==', false).get();
  for (const doc of pending.docs) {
    const job = await db.runTransaction(async tx => {
      const current = (await tx.get(doc.ref)).data();
      if (!current || current.done || (current.leaseUntil?.toMillis() ?? 0) > Date.now()) return null;
      tx.update(doc.ref, { leaseUntil: Timestamp.fromMillis(Date.now() + 5 * 60_000) });
      return current;
    });
    if (!job) continue;
    try {
      const eventRef = db.doc(`ceremonies/${job.ceremonyId}`);
      const data = (await eventRef.get()).data();
      if (data && data.notificationId === doc.id && (data.status === 'open' || data.status === 'closed')) {
        const event = data as Ceremony;
        let recipients = [...new Set([...event.voterIds, ...(event.status === 'closed' ? event.nominees.map(n => n.uid) : [])])];
        if (event.status === 'open') {
          const votes = await eventRef.collection('votes').get();
          const voted = new Set(votes.docs.filter(v => {
            if ((v.data().revision ?? 0) !== (event.revision ?? 0)) return false;
            try { validateBallot(event, v.id, v.data().choices); return true; } catch { return false; }
          }).map(v => v.id));
          recipients = recipients.filter(uid => !voted.has(uid));
        }
        if (recipients.length) await send({
          title: event.status === 'open' ? `À toi de voter · ${event.title}` : `Révélation · ${event.title}`,
          body: event.status === 'open' ? `Le vote ${job.action === 'reopen' ? 'est rouvert' : 'est ouvert'}. Prépare ton top ${event.topSize} !` : 'Les résultats sont disponibles. Découvre le classement et les trophées dans l\'application.',
          onlyUids: recipients,
          data: { type: event.status === 'open' ? 'ceremony_vote' : 'ceremony_results', ceremonyId: job.ceremonyId },
        });
      }
      await doc.ref.update({ done: true, completedAt: Timestamp.now(), leaseUntil: null });
    } catch (error) {
      await doc.ref.update({ leaseUntil: null });
      throw error;
    }
  }
}
