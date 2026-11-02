import { FieldValue, getFirestore, Transaction, Firestore } from 'firebase-admin/firestore';
import { NextFunction, Response } from 'express';
import { AuthedRequest } from './middleware/auth';

// Never persist request bodies: they can contain passwords, tokens or ballots.
export async function auditRequest(req: AuthedRequest, res: Response, next: NextFunction) {
  if (['GET', 'HEAD', 'OPTIONS'].includes(req.method)) { next(); return; }
  try {
    const db = getFirestore();
    const user = (await db.doc(`users/${req.uid}`).get()).data();
    const entry = db.collection('audit_logs').doc();
    await entry.set({ actorUid: req.uid, actorName: `${user?.firstName ?? ''} ${user?.lastName ?? ''}`.trim(),
      actorRole: user?.role ?? 'unknown', action: req.method, target: req.originalUrl.split('?')[0],
      source: 'api', status: 'pending', at: FieldValue.serverTimestamp() });
    // A pending entry survives a crash and must not be mistaken for success.
    let resultId: string | null = null;
    const json = res.json.bind(res);
    res.json = (body: any) => {
      resultId = typeof body?.uid === 'string' ? body.uid : typeof body?.id === 'string' ? body.id : null;
      return json(body);
    };
    res.once('finish', () => {
      void entry.update({ status: res.statusCode < 400 ? 'success' : 'failed',
        resultId, httpStatus: res.statusCode, finishedAt: FieldValue.serverTimestamp() })
        .catch(error => console.error('Audit completion failed', entry.id, error));
    });
    next();
  } catch { res.status(503).json({ error: 'Journal indisponible. Action non exécutée, réessayez.' }); }
}

export function auditChange(tx: Transaction, db: Firestore, actorUid: string, actor: any,
  action: string, target: string, before: unknown, after: unknown) {
  tx.create(db.collection('audit_logs').doc(), {
    actorUid, actorName: `${actor?.firstName ?? ''} ${actor?.lastName ?? ''}`.trim(),
    actorRole: actor?.role ?? 'system', action, target, before, after,
    source: 'transaction', status: 'success', at: FieldValue.serverTimestamp(),
  });
}
