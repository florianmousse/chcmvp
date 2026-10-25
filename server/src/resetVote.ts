import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { matchReference } from "./matchReference";

// Identifies exactly the ballot displayed to the admin, without revealing its choices.
export const ballotVersion = (time: Timestamp) => `${time.seconds}:${time.nanoseconds}`;

export function canResetVote(match: FirebaseFirestore.DocumentData, now = Timestamp.now()) {
  return match.status === "voting_open" &&
    (!match.votingOpensAt || match.votingOpensAt.toMillis() <= now.toMillis()) &&
    (!match.votingClosesAt || match.votingClosesAt.toMillis() > now.toMillis());
}

export async function resetVote(
  matchId: string, voterUid: string, adminUid: string,
  expectedVersion: unknown, db = getFirestore(),
) {
  if (!voterUid || voterUid.includes("/") ||
      typeof expectedVersion !== "string" || !/^\d+:\d+$/.test(expectedVersion)) {
    throw Object.assign(new Error("Actualise le suivi avant de réinitialiser ce vote."), { status: 400 });
  }
  const ref = matchReference(matchId, db);
  const ballot = ref.collection("votes").doc(voterUid);
  await db.runTransaction(async (tx) => {
    const [admin, match, vote] = await tx.getAll(db.doc(`users/${adminUid}`), ref, ballot);
    if (admin.data()?.role !== "admin" || admin.data()?.isActive !== true) {
      throw Object.assign(new Error("Réservé aux administrateurs actifs."), { status: 403 });
    }
    if (!match.exists) throw Object.assign(new Error("Match introuvable."), { status: 404 });
    if (!canResetVote(match.data()!)) {
      throw Object.assign(new Error("Le vote doit être ouvert et sa période de participation encore en cours."), { status: 409 });
    }
    if (!vote.exists || ballotVersion(vote.updateTime!) !== expectedVersion) {
      throw Object.assign(new Error("Ce bulletin a déjà été réinitialisé ou remplacé. Actualise le suivi."), { status: 409 });
    }
    // The transaction protects against a concurrent closure or replacement ballot.
    tx.delete(ballot);
  });
}
