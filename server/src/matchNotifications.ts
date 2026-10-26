import { getFirestore } from "firebase-admin/firestore";
import { isTestMatchId, matchReference } from "./matchReference";

export async function votingOpenedNotification(
  matchId: string,
  match: FirebaseFirestore.DocumentData,
  db = getFirestore(),
) {
  const adminsOnly = isTestMatchId(matchId);
  // Read only voter IDs, never ballot choices. Test matches notify admins
  // independently of simulated voters and never notify real participants.
  const votes = adminsOnly ? null : await matchReference(matchId, db)
    .collection("votes").select().get();
  return {
    adminsOnly,
    title: match.manualCloseRequired ? "Vote rouvert !" : "Vote ouvert !",
    body: match.manualCloseRequired
      ? `Le vote contre ${match.opponent ?? "l'adversaire"} est rouvert. Tu peux encore déposer ton vote pour les 3 meilleurs joueurs !`
      : `Le match contre ${match.opponent ?? "l'adversaire"} est terminé. Vote dès maintenant pour les 3 meilleurs joueurs !`,
    team: match.team as string | undefined,
    onlyUids: (match.presentPlayerIds ?? []) as string[],
    excludeUids: votes?.docs.map((doc) => doc.id) ?? [],
    data: { type: "voting_open", matchId },
  };
}

export function votingClosedNotification(
  matchId: string,
  match: FirebaseFirestore.DocumentData,
  mvpNames: string,
) {
  const adminsOnly = isTestMatchId(matchId);
  const reopened = match.manualCloseRequired === true;
  const resultLabel = adminsOnly ? "Résultats du test calculés."
    : reopened
      ? `Le vote contre ${match.opponent ?? "l'adversaire"} est clôturé après réouverture. Le classement a été recalculé en tenant compte des votes tardifs.`
      : "Le classement a été mis à jour.";
  return {
    adminsOnly,
    title: reopened ? "Classement actualisé ✅" : "Vote clôturé ✅",
    body: mvpNames ? `${resultLabel} MVP : ${mvpNames} 🏆` : resultLabel,
    team: match.team as string | undefined,
    // Everyone present, including previous voters, receives the final results.
    onlyUids: (match.presentPlayerIds ?? []) as string[],
    data: { type: "voting_closed", matchId },
  };
}
