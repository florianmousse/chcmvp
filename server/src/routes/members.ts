import { Router } from "express";
import { getFirestore } from "firebase-admin/firestore";
import { requireAuth, requireAdmin, AuthedRequest } from "../middleware/auth";
import { createMember, inviteExistingMember, setMemberActive, deleteMember, memberDependencies } from "../members";

export const membersRouter = Router();
membersRouter.use(requireAuth, requireAdmin);

// Empty email creates a player profile without a login account.
membersRouter.post("/invite", async (req, res) => {
  try { res.json(await createMember(req.body ?? {}, memberDependencies())); }
  catch (e: any) { res.status(400).json({ error: e.message ?? "Erreur inconnue." }); }
});

membersRouter.post("/:uid/invite", async (req, res) => {
  try { res.json(await inviteExistingMember(req.params.uid, req.body ?? {}, memberDependencies())); }
  catch (e: any) { res.status(400).json({ error: e.message ?? "Erreur inconnue." }); }
});

membersRouter.post("/:uid/active", async (req, res) => {
  const { isActive } = req.body;
  if (typeof isActive !== "boolean") return res.status(400).json({ error: "isActive (booléen) requis." });
  try {
    await setMemberActive(req.params.uid, isActive, memberDependencies());
    res.json({ success: true });
  } catch (e: any) { res.status(400).json({ error: e.message }); }
});

membersRouter.post("/:uid/role", async (req, res) => {
  const { role } = req.body;
  if (role !== "admin" && role !== "member") return res.status(400).json({ error: "role doit être 'admin' ou 'member'." });
  try {
    const doc = getFirestore().doc(`users/${req.params.uid}`);
    const profile = (await doc.get()).data();
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
