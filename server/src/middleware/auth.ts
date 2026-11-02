import { getFirestore } from "../database";
import { enterRequestSpace } from "../reviewSpace";
import { Request, Response, NextFunction } from "express";
import { getAuth } from "firebase-admin/auth";

import { canManageMatch } from '../reviewAccess';
import { matchReference } from '../matchReference';

export interface AuthedRequest extends Request {
  uid?: string;
}

/** Router-wide guard: reviewers can only reach their own test match routes. */
export async function requireMatchAccess(req: AuthedRequest, res: Response, next: NextFunction) {
  try {
    const db = getFirestore();
    const user: any = { ...(await db.doc(`users/${req.uid}`).get()).data(), uid: req.uid };
    if (user.isActive === true && user.role === 'admin') { next(); return; }
    const matchId = decodeURIComponent(req.path.split('/')[1] ?? '');
    if (!matchId.startsWith('test:') || matchId.includes('/')) {
      res.status(403).json({ error: 'Réservé aux administrateurs.' }); return;
    }
    const match = (await matchReference(matchId, db).get()).data();
    if (!canManageMatch(user, matchId, match)) {
      res.status(403).json({ error: 'Vous pouvez uniquement gérer vos matchs de validation.' }); return;
    }
    next();
  } catch { res.status(403).json({ error: 'Accès refusé.' }); }
}

/**
 * L'app envoie le token Firebase de l'utilisateur connecté dans l'en-tête
 * Authorization: Bearer <idToken> (voir server_client.dart côté Flutter).
 * On le vérifie cryptographiquement avec l'Admin SDK - c'est l'équivalent
 * exact de `request.auth` que Cloud Functions fournissait automatiquement.
 */
export async function requireAuth(
  req: AuthedRequest,
  res: Response,
  next: NextFunction,
): Promise<void> {
  const header = req.headers.authorization;
  if (!header?.startsWith("Bearer ")) {
    res.status(401).json({ error: "Token manquant." });
    return;
  }
  try {
    const decoded = await getAuth().verifyIdToken(
      header.slice("Bearer ".length),
    );
    req.uid = decoded.uid;
    await enterRequestSpace(req, res, next);
  } catch (error: any) {
    res.status(error.status ?? 401).json({ error: error.status ? error.message : "Connexion ou préparation de l’espace impossible. Réessayez." });
  }
}

/** À chaîner après requireAuth sur toutes les routes réservées à l'administration. */
export async function requireAdmin(
  req: AuthedRequest,
  res: Response,
  next: NextFunction,
): Promise<void> {
  const doc = await getFirestore().doc(`users/${req.uid}`).get();
  const data = doc.data();
  if (!doc.exists || data?.role !== "admin" || data?.isActive !== true) {
    res.status(403).json({ error: "Réservé aux administrateurs." });
    return;
  }
  next();
}
