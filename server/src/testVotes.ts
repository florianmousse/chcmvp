import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { isTestMatchId, matchReference } from "./matchReference";

function reject(status: number, message: string): never {
  throw Object.assign(new Error(message), { status });
}

export async function saveTestVote(matchId: string, adminUid: string, input: any, db = getFirestore()) {
  if (!isTestMatchId(matchId)) reject(400, "La simulation est réservée aux matchs de test.");
  const { voterUid, firstPlaceUid, secondPlaceUid, thirdPlaceUid } = input ?? {};
  const choices = [firstPlaceUid, secondPlaceUid, thirdPlaceUid];
  if ([voterUid, ...choices].some((uid) => typeof uid !== "string" || !uid || uid.includes("/"))) {
    reject(400, "Choisis un votant et trois joueurs.");
  }
  if (new Set(choices).size !== 3) reject(400, "Le top 3 doit contenir trois joueurs différents.");
  const matchRef = matchReference(matchId, db);
  await db.runTransaction(async (tx) => {
    const admin = (await tx.get(db.doc(`users/${adminUid}`))).data();
    if (admin?.role !== "admin" || admin?.isActive !== true) reject(403, "Réservé aux administrateurs.");
    const match = (await tx.get(matchRef)).data();
    if (!match) reject(404, "Match de test introuvable.");
    if (match.status !== "voting_open") reject(409, "Ouvre le vote du match de test avant de simuler un bulletin.");
    const now = Timestamp.now();
    if ((match.votingOpensAt && now.toMillis() < match.votingOpensAt.toMillis()) ||
        (match.votingClosesAt && now.toMillis() >= match.votingClosesAt.toMillis())) {
      reject(409, "La période de vote est fermée.");
    }
    const present = new Set(match.presentPlayerIds ?? []);
    if (![voterUid, ...choices].every((uid) => present.has(uid))) reject(400, "Le votant et les candidats doivent être présents.");
    if (!match.allowSelfVote && choices.includes(voterUid)) reject(400, "Le vote pour soi-même est désactivé.");
    tx.set(matchRef.collection("votes").doc(voterUid), {
      voterUid, firstPlaceUid, secondPlaceUid, thirdPlaceUid,
      votedAt: now, simulatedByAdminUid: adminUid,
    });
  });
}
