import { Router } from "express";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { requireAuth, requireAdmin, AuthedRequest } from "../middleware/auth";
import { sendInviteEmail } from "../mailer";

export const membersRouter = Router();
membersRouter.use(requireAuth, requireAdmin);

membersRouter.post("/invite", async (req: AuthedRequest, res) => {
  const { email, firstName, lastName, team, jerseyNumber } = req.body as {
    email: string;
    firstName: string;
    lastName: string;
    team: string;
    jerseyNumber?: number;
  };

  if (!email || !firstName || !lastName || !team) {
    return res.status(400).json({ error: "Champs requis manquants." });
  }

  try {
    const tempPassword = Math.random().toString(36).slice(-12) + "Aa1!";
    const userRecord = await getAuth().createUser({
      email,
      password: tempPassword,
      displayName: `${firstName} ${lastName}`,
    });

    await getFirestore()
      .doc(`users/${userRecord.uid}`)
      .set({
        firstName,
        lastName,
        email,
        team,
        jerseyNumber: jerseyNumber ?? null,
        photoUrl: null,
        role: "member",
        isActive: true,
        fcmTokens: [],
        createdAt: new Date().toISOString(),
      });

    const resetLink = await getAuth().generatePasswordResetLink(email);
    await sendInviteEmail({ to: email, firstName, resetLink });
    // Comme sur Cloud Functions : l'envoi effectif du mail est délégué au
    // template Firebase Auth, ou à un service transactionnel si besoin.
    res.json({ uid: userRecord.uid, resetLink });
  } catch (e: any) {
    res.status(400).json({ error: e.message ?? "Erreur inconnue." });
  }
});

membersRouter.post("/:uid/active", async (req, res) => {
  const { uid } = req.params;
  const { isActive } = req.body as { isActive: boolean };
  if (typeof isActive !== "boolean") {
    return res.status(400).json({ error: "isActive (booléen) requis." });
  }

  await getAuth().updateUser(uid, { disabled: !isActive });
  await getFirestore().doc(`users/${uid}`).update({ isActive });
  res.json({ success: true });
});

membersRouter.post("/:uid/role", async (req, res) => {
  const { uid } = req.params;
  const { role } = req.body as { role: "admin" | "member" };
  if (role !== "admin" && role !== "member") {
    return res
      .status(400)
      .json({ error: "role doit être 'admin' ou 'member'." });
  }

  await getFirestore().doc(`users/${uid}`).update({ role });
  res.json({ success: true });
});

membersRouter.delete("/:uid", async (req: AuthedRequest, res) => {
  const { uid } = req.params;
  if (uid === req.uid) {
    return res
      .status(400)
      .json({ error: "Un administrateur ne peut pas se supprimer lui-même." });
  }

  await getAuth().deleteUser(uid);
  await getFirestore().doc(`users/${uid}`).delete();
  res.json({ success: true });
});
