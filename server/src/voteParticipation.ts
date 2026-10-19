import { getFirestore } from "firebase-admin/firestore";
import { matchReference } from "./matchReference";

/** Exposes attendance only, never ballot choices, including while voting is open. */
export async function voteParticipation(matchId: string, adminUid: string, db = getFirestore()) {
  const admin = (await db.doc(`users/${adminUid}`).get()).data();
  if (admin?.role !== "admin" || admin?.isActive !== true) {
    throw Object.assign(new Error("Réservé aux administrateurs."), { status: 403 });
  }
  const ref = matchReference(matchId, db);
  const match = (await ref.get()).data();
  if (!match) throw Object.assign(new Error("Match introuvable."), { status: 404 });
  const present = [...new Set<string>(match.presentPlayerIds ?? [])];
  // select() with no fields retrieves document IDs without reading vote choices.
  const ballots = await ref.collection("votes").select().get();
  const voted = new Set(ballots.docs.map((doc) => doc.id));
  const missing = present.filter((uid) => !voted.has(uid));
  const profiles = missing.length ? await db.getAll(...missing.map((uid) => db.doc(`users/${uid}`))) : [];
  const pending = profiles.map((doc) => {
    const user = doc.data();
    const name = `${user?.firstName ?? ""} ${user?.lastName ?? ""}`.trim() || "Joueur supprimé";
    return {
      uid: doc.id, name,
      accountStatus: !user ? "missing" : user.isActive !== true ? "inactive" : !user.email?.trim() ? "no_account" : "active",
    };
  }).sort((a, b) => a.name.localeCompare(b.name, "fr"));
  return { matchId, status: match.status, votedCount: present.length - missing.length,
    totalCount: present.length, pending };
}
