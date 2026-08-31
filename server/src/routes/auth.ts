import { Router } from "express";
import { getAuth } from "firebase-admin/auth";
import { sendPasswordResetEmail } from "../mailer";

export const authRouter = Router();

/**
 * Volontairement PUBLIQUE (pas de requireAuth/requireAdmin, contrairement
 * aux autres routeurs) : quelqu'un qui a oublié son mot de passe n'est par
 * définition pas connecté, donc ne peut fournir aucun token Firebase.
 *
 * Répond toujours pareil, que l'e-mail corresponde à un compte existant ou
 * non — ne jamais révéler à un appelant anonyme quels comptes existent.
 */
authRouter.post("/forgot-password", async (req, res) => {
  const { email } = req.body as { email?: string };
  if (!email) {
    res.status(400).json({ error: "E-mail requis." });
    return;
  }

  try {
    const resetLink = await getAuth().generatePasswordResetLink(email);
    await sendPasswordResetEmail({ to: email, resetLink });
  } catch (e) {
    // Erreur avalée volontairement (ex: "aucun compte pour cet e-mail") —
    // la réponse ne doit jamais indiquer si un compte existe ou non.
    console.warn(`forgot-password : échec silencieux pour ${email}`, e);
  }

  res.json({ success: true });
});
