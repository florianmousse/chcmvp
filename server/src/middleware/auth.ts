import { Request, Response, NextFunction } from "express";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";

export interface AuthedRequest extends Request {
  uid?: string;
}

/**
 * L'app envoie le token Firebase de l'utilisateur connecté dans l'en-tête
 * Authorization: Bearer <idToken> (voir server_client.dart côté Flutter).
 * On le vérifie cryptographiquement avec l'Admin SDK — c'est l'équivalent
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
    next();
  } catch {
    res.status(401).json({ error: "Token invalide ou expiré." });
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
