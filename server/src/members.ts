import { randomBytes } from "crypto";
import { Auth, getAuth } from "firebase-admin/auth";
import { Firestore, getFirestore } from "firebase-admin/firestore";
import { sendInviteEmail } from "./mailer";

export interface MemberDependencies {
  auth: Auth;
  db: Firestore;
  sendInvite: typeof sendInviteEmail;
}
export const memberDependencies = (): MemberDependencies => ({
  auth: getAuth(), db: getFirestore(), sendInvite: sendInviteEmail,
});

export function memberFields(input: Record<string, unknown>) {
  const text = (key: string) => typeof input[key] === "string" ? (input[key] as string).trim() : "";
  const email = text("email").toLowerCase();
  const firstName = text("firstName"), lastName = text("lastName"), team = text("team");
  if (!firstName || !lastName || !team) throw new Error("Prénom, nom et équipe requis.");
  if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) throw new Error("Adresse e-mail invalide.");
  const jerseyNumber = input.jerseyNumber ?? null;
  if (jerseyNumber !== null && (!Number.isInteger(jerseyNumber) || (jerseyNumber as number) < 0)) {
    throw new Error("Numéro de maillot invalide.");
  }
  return { email, firstName, lastName, team, jerseyNumber };
}

async function sendInvitation(uid: string, email: string, firstName: string, deps: MemberDependencies) {
  try {
    const resetLink = await deps.auth.generatePasswordResetLink(email);
    await deps.sendInvite({ to: email, firstName, resetLink });
  } catch {
    throw new Error("Le compte est créé, mais l'e-mail n'a pas pu être envoyé. Utilisez « Mot de passe oublié » sur la connexion pour réessayer.");
  }
  return { uid };
}

export async function createMember(input: Record<string, unknown>, deps: MemberDependencies) {
  const fields = memberFields(input);
  const doc = deps.db.collection("users").doc();
  const profile = { ...fields, photoUrl: null, role: "member", isActive: true,
    fcmTokens: [], createdAt: new Date().toISOString() };
  if (!fields.email) {
    await doc.set(profile);
    return { uid: doc.id };
  }
  await deps.auth.createUser({ uid: doc.id, email: fields.email,
    password: randomBytes(32).toString("base64url"), displayName: `${fields.firstName} ${fields.lastName}` });
  try { await doc.set(profile); }
  catch (error) { await deps.auth.deleteUser(doc.id); throw error; }
  return sendInvitation(doc.id, fields.email, fields.firstName, deps);
}

export async function inviteExistingMember(uid: string, input: Record<string, unknown>, deps: MemberDependencies) {
  const doc = deps.db.doc(`users/${uid}`);
  const existing = (await doc.get()).data();
  if (!existing) throw new Error("Joueur introuvable.");
  const fields = memberFields({ ...existing, ...input });
  if (!fields.email) throw new Error("Adresse e-mail requise pour inviter le joueur.");
  if (existing.email && existing.email !== fields.email) throw new Error("Ce joueur possède déjà un compte avec une autre adresse.");
  // Reuse the player UID so matches, votes, rankings and badges keep their references.
  let created = false;
  try {
    await deps.auth.createUser({ uid, email: fields.email,
      password: randomBytes(32).toString("base64url"), disabled: !existing.isActive,
      displayName: `${fields.firstName} ${fields.lastName}` });
    created = true;
  } catch (error: any) {
    if (error.code !== "auth/uid-already-exists") throw error;
    const account = await deps.auth.getUser(uid);
    if (account.email?.toLowerCase() !== fields.email) throw new Error("Ce joueur possède déjà un autre compte.");
  }
  try { await doc.update(fields); }
  catch (error) { if (created) await deps.auth.deleteUser(uid); throw error; }
  return sendInvitation(uid, fields.email, fields.firstName, deps);
}

export async function setMemberActive(uid: string, isActive: boolean, deps: MemberDependencies) {
  const doc = deps.db.doc(`users/${uid}`);
  const profile = (await doc.get()).data();
  if (!profile) throw new Error("Joueur introuvable.");
  try { await deps.auth.updateUser(uid, { disabled: !isActive }); }
  catch (error: any) {
    if (error.code !== "auth/user-not-found" || profile.email) throw error;
  }
  await doc.update({ isActive });
}

export async function deleteMember(uid: string, deps: MemberDependencies) {
  try { await deps.auth.deleteUser(uid); }
  catch (error: any) { if (error.code !== "auth/user-not-found") throw error; }
  await deps.db.doc(`users/${uid}`).delete();
}
