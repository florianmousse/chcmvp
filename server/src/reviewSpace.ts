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
    const ownerProfile = actorUid === ownerUid ? visitor : await tx.get(root.collection('users').doc(ownerUid));
    if (o?.role !== 'reviewer' || (actorUid === ownerUid && o.isActive !== true) || a?.isActive !== true ||
        (actorUid !== ownerUid && a.role !== 'admin')) throw Object.assign(new Error('Accès à cet espace refusé.'), { status: 403 });
    const profile = (visitor: boolean) => ({ firstName: visitor ? 'Administrateur' : 'Validation', lastName: 'CHC',
      email: visitor ? 'admin@example.invalid' : 'review@example.invalid', team: 'Équipe démo', role: 'admin', isActive: true, fcmTokens: [],
      createdAt: Timestamp.now(), reviewSource: 'Équipe de validation', reviewSpaceUid: ownerUid, syntheticIdentityVersion: 1 });
    if (!space.exists) {
      tx.create(root, { ownerUid, label: 'Équipe de validation', name: 'Équipe de validation', createdAt: Timestamp.now() });
      tx.create(root.collection('users').doc(ownerUid), profile(false));
      tx.create(root.collection('teams').doc('demo'), { name: 'Équipe démo' });
      tx.create(root.collection('opponents').doc('demo'), { name: 'Adversaire démo' });
      for (let i = 1; i <= 5; i++) tx.create(root.collection('users').doc(`demo-player-${i}`), {
        firstName: 'Joueur démo', lastName: String(i), email: `player${i}@example.invalid`, team: 'Équipe démo',
        role: 'member', isActive: true, jerseyNumber: i, fcmTokens: [], createdAt: Timestamp.now(),
      });
    }
    if (actorUid !== ownerUid && !visitor.exists) tx.create(visitor.ref, profile(true));
    // Targeted, resumable migration: preserve sandbox matches and member edits.
    // Only bootstrap identities which predate synthetic identity version 1.
    if (space.exists && space.data()?.syntheticIdentityVersion !== 1) {
      tx.update(root, { name: 'Équipe de validation', syntheticIdentityVersion: 1 });
    }
    for (const [snapshot, visiting] of [[ownerProfile, false], [visitor, actorUid !== ownerUid]] as const) {
      if (snapshot.exists && snapshot.data()?.syntheticIdentityVersion !== 1) {
        const synthetic = profile(visiting);
        tx.update(snapshot.ref, { firstName: synthetic.firstName, lastName: synthetic.lastName,
          email: synthetic.email, photoUrl: null, syntheticIdentityVersion: 1 });
      }
    }
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
