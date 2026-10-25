import { getFirestore } from "firebase-admin/firestore";
import { matchReference } from "./matchReference";
import { ballotVersion, canResetVote } from "./resetVote";

/** Exposes attendance only, never ballot choices, including while voting is open. */
export async function voteParticipation(matchId: string, adminUid: string, db = getFirestore()) {
  return db.runTransaction(async (tx) => {
    const admin = (await tx.get(db.doc(`users/${adminUid}`))).data();
    if (admin?.role !== "admin" || admin?.isActive !== true) {
      throw Object.assign(new Error("Réservé aux administrateurs."), { status: 403 });
    }
    const ref = matchReference(matchId, db);
    const match = (await tx.get(ref)).data();
    if (!match) throw Object.assign(new Error("Match introuvable."), { status: 404 });
    const present = [...new Set<string>(match.presentPlayerIds ?? [])];
    // No ballot fields are fetched: only document IDs and update times.
    const ballots = await tx.get(ref.collection("votes").select());
    const versions = new Map(ballots.docs.map((doc) => [doc.id, ballotVersion(doc.updateTime)]));
    const profiles = present.length ? await tx.getAll(...present.map((uid) => db.doc(`users/${uid}`))) : [];
    const players = profiles.map((doc) => {
      const user = doc.data();
      const name = `${user?.firstName ?? ""} ${user?.lastName ?? ""}`.trim() || "Joueur supprimé";
      return {
        uid: doc.id, name,
        accountStatus: !user ? "missing" : !user.email?.trim() ? "no_account" : user.isActive !== true ? "inactive" : "active",
      };
    }).sort((a, b) => Number(a.accountStatus === "no_account") - Number(b.accountStatus === "no_account") ||
      a.name.localeCompare(b.name, "fr"));
    const pending = players.filter((player) => !versions.has(player.uid));
    const voted = players.filter((player) => versions.has(player.uid)).map((player) => ({
      ...player, voteVersion: versions.get(player.uid)!,
    }));
    return { matchId, status: match.status, canReset: canResetVote(match),
      votedCount: voted.length, totalCount: present.length, pending, voted };
  });
}
