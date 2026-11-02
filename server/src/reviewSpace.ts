import { Firestore, Timestamp } from 'firebase-admin/firestore';
import { getProductionFirestore, inReviewSpace } from './database';
import type { AuthedRequest } from './middleware/auth';
import type { NextFunction, Response } from 'express';

/** Idempotent, atomic bootstrap. No production documents are copied or changed. */
export async function ensureReviewSpace(ownerUid: string, actorUid: string, db = getProductionFirestore()) {
  const root = db.doc(`review_spaces/${ownerUid}`);
  await db.runTransaction(async tx => {
    const [owner, actor, space, visitor] = await tx.getAll(db.doc(`users/${ownerUid}`), db.doc(`users/${actorUid}`), root,
      root.collection('users').doc(actorUid));
    const o = owner.data(), a = actor.data();
    if (o?.role !== 'reviewer' || (actorUid === ownerUid && o.isActive !== true) || a?.isActive !== true ||
        (actorUid !== ownerUid && a.role !== 'admin')) throw Object.assign(new Error('Accès à cet espace refusé.'), { status: 403 });
    const profile = (data: any) => ({ firstName: data.firstName ?? 'Validation', lastName: data.lastName ?? 'CHC',
      email: data.email ?? '', team: 'Équipe démo', role: 'admin', isActive: true, fcmTokens: [],
      createdAt: Timestamp.now(), reviewSource: 'Équipe de validation', reviewSpaceUid: ownerUid });
    if (!space.exists) {
      tx.create(root, { ownerUid, label: 'Équipe de validation', name: `${o.firstName ?? ''} ${o.lastName ?? ''}`.trim(), createdAt: Timestamp.now() });
      tx.create(root.collection('users').doc(ownerUid), profile(o));
      tx.create(root.collection('teams').doc('demo'), { name: 'Équipe démo' });
      tx.create(root.collection('opponents').doc('demo'), { name: 'Adversaire démo' });
      for (let i = 1; i <= 5; i++) tx.create(root.collection('users').doc(`demo-player-${i}`), {
        firstName: 'Joueur démo', lastName: String(i), email: `player${i}@example.invalid`, team: 'Équipe démo',
        role: 'member', isActive: true, jerseyNumber: i, fcmTokens: [], createdAt: Timestamp.now(),
      });
    }
    if (actorUid !== ownerUid && !visitor.exists) tx.create(visitor.ref, profile(a));
  });
}

/** Auth identity is always checked against production, before selecting data. */
export async function enterRequestSpace(req: AuthedRequest, res: Response, next: NextFunction, db: Firestore = getProductionFirestore()) {
  const user = (await db.doc(`users/${req.uid}`).get()).data();
  if (user?.isActive !== true) { res.status(403).json({ error: 'Compte inactif.' }); return; }
  const requested = req.headers['x-review-space'];
  if (requested !== undefined && (typeof requested !== 'string' || !requested || requested.includes('/') || ['.', '..'].includes(requested))) {
    res.status(400).json({ error: 'Espace invalide.' }); return;
  }
  if (requested && user.role !== 'admin' && !(user.role === 'reviewer' && requested === req.uid)) {
    res.status(403).json({ error: 'Accès à cet espace refusé.' }); return;
  }
  const owner = user.role === 'reviewer' ? req.uid! : requested;
  if (!owner) { next(); return; }
  await ensureReviewSpace(owner, req.uid!, db);
  inReviewSpace(owner, next, db);
}
