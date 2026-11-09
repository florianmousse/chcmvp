import { memberDirectory } from '../memberDirectory';
import { getReviewSpaceUid } from "../database";
import { getFirestore } from "../database";
import { auditRequest } from '../audit';
import { randomBytes } from 'crypto';
import { getAuth } from 'firebase-admin/auth';
import { Router } from "express";

import { requireAuth, requireAdmin, AuthedRequest } from "../middleware/auth";
import { createMember, changeMemberEmail, inviteExistingMember, setMemberActive, deleteMember, memberDependencies } from "../members";

export const membersRouter = Router();
membersRouter.use(requireAuth);
membersRouter.get('/directory', async (req: AuthedRequest, res) => {
  res.setHeader('Cache-Control', 'no-store');
  if (!req.uid) { res.status(401).json({ error: 'Connexion requise.' }); return; }
  try { res.json(await memberDirectory(req.uid, req.query.cursor, getFirestore())); }
  catch (error: unknown) {
    const status = error instanceof Error && 'status' in error ? error.status : 500;
    res.status(status === 400 || status === 403 ? status : 500).json({
      error: status === 400 ? 'Page invalide.' : status === 403 ? 'Accès refusé.' : 'Annuaire indisponible.',
    });
  }
});
membersRouter.use(requireAdmin, auditRequest);

// Credentials are returned only once, never emailed or written to the audit log.
membersRouter.post('/review-account', async (req, res) => {
  if (getReviewSpaceUid()) return res.status(403).json({ error: 'La création d\'accès réels est réservée à l\'administration du club.' });
  res.setHeader('Cache-Control', 'no-store');
  const email = typeof req.body?.email === 'string' ? req.body.email.trim().toLowerCase() : '';
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return res.status(400).json({ error: 'Adresse e-mail invalide.' });
  const password = randomBytes(24).toString('base64url');
  const doc = getFirestore().collection('users').doc();
  try {
    await getAuth().createUser({ uid: doc.id, email, password, displayName: 'Équipe de validation' });
    try {
      const batch = getFirestore().batch();
      batch.set(doc, { email, firstName: 'Équipe de', lastName: 'validation', team: 'Validation',
        role: 'reviewer', isActive: true, fcmTokens: [], createdAt: new Date().toISOString() });
      batch.create(getFirestore().collection('audit_logs').doc(), { actorUid: (req as AuthedRequest).uid,
        action: 'create', target: doc.path, source: 'transaction', status: 'success', at: new Date() });
      await batch.commit();
    } catch (error) { await getAuth().deleteUser(doc.id); throw error; }
    res.json({ uid: doc.id, email, password });
  } catch (error: any) { res.status(400).json({ error: error.code === 'auth/email-already-exists'
    ? 'Cette adresse possède déjà un compte. Aucun compte existant n\'a été modifié.' : 'Création impossible. Vérifiez les comptes avant de réessayer.' }); }
});

// Empty email creates a player profile without a login account.
membersRouter.post("/invite", async (req, res) => {
  try { res.json(await createMember(req.body ?? {}, memberDependencies())); }
  catch (e: any) { res.status(400).json({ error: e.message ?? "Erreur inconnue." }); }
});

membersRouter.post("/:uid/invite", async (req, res) => {
  try { res.json(await inviteExistingMember(req.params.uid, req.body ?? {}, memberDependencies())); }
  catch (e: any) { res.status(400).json({ error: e.message ?? "Erreur inconnue." }); }
});

membersRouter.post("/:uid/email", async (req, res) => {
  try { res.json(await changeMemberEmail(req.params.uid, req.body ?? {}, memberDependencies())); }
  catch (e: any) { res.status(400).json({ error: e.code === 'auth/email-already-exists' ? 'Cette adresse est déjà utilisée par un autre compte.' : e.message }); }
});

membersRouter.post("/:uid/active", async (req, res) => {
  if (getReviewSpaceUid() && req.params.uid === (req as AuthedRequest).uid) return res.status(400).json({ error: "Gardez votre accès à l'espace de validation actif." });
  const { isActive } = req.body;
  if (typeof isActive !== "boolean") return res.status(400).json({ error: "isActive (booléen) requis." });
  try {
    await setMemberActive(req.params.uid, isActive, memberDependencies());
    res.json({ success: true });
  } catch (e: any) { res.status(400).json({ error: e.message }); }
});

membersRouter.post("/:uid/role", async (req, res) => {
  if (getReviewSpaceUid() && req.params.uid === (req as AuthedRequest).uid) return res.status(400).json({ error: "Votre compte conserve l'accès à la gestion de cet espace." });
  const { role } = req.body;
  if (role !== "admin" && role !== "member") return res.status(400).json({ error: "role doit être 'admin' ou 'member'." });
  try {
    const doc = getFirestore().doc(`users/${req.params.uid}`);
    const profile = (await doc.get()).data();
    if (profile?.role === 'reviewer') return res.status(400).json({ error: 'Un compte de validation doit conserver son rôle isolé.' });
    if (!profile?.email && role === "admin") return res.status(400).json({ error: "Invitez ce joueur avant de le promouvoir." });
    await doc.update({ role });
    res.json({ success: true });
  } catch (e: any) { res.status(400).json({ error: e.message }); }
});

membersRouter.delete("/:uid", async (req: AuthedRequest, res) => {
  if (req.params.uid === req.uid) return res.status(400).json({ error: "Un administrateur ne peut pas se supprimer lui-même." });
  try {
    await deleteMember(req.params.uid, memberDependencies());
    res.json({ success: true });
  } catch (e: any) { res.status(400).json({ error: e.message }); }
});
