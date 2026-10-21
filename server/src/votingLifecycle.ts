import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { isTestMatchId, matchReference } from "./matchReference";
import { withRankingLock } from "./rankingLock";
import { rebuildRankingsUnlocked } from "./rebuildRankings";

export const REOPEN_REMINDER_INTERVAL_MS = 24 * 60 * 60 * 1000;

export function reopenVoting(matchId: string, adminUid: string, db = getFirestore()) {
  return withRankingLock(async () => {
    const ref = matchReference(matchId, db);
    await db.runTransaction(async (tx) => {
      const [admin, snapshot] = await Promise.all([
        tx.get(db.doc(`users/${adminUid}`)), tx.get(ref),
      ]);
      if (admin.data()?.role !== "admin" || admin.data()?.isActive !== true) {
        throw Object.assign(new Error("Action réservée aux administrateurs actifs."), { status: 403 });
      }
      if (!snapshot.exists) throw Object.assign(new Error("Match introuvable."), { status: 404 });
      const match = snapshot.data()!;
      // A retry after a failed rebuild must finish the rebuild, without resetting reminders.
      if (match.status === "voting_open" && match.manualCloseRequired === true) return;
      if (match.status !== "voting_closed") {
        throw Object.assign(new Error("Seul un vote terminé peut être rouvert."), { status: 409 });
      }
      const now = Timestamp.now();
      tx.update(ref, {
        status: "voting_open", manualCloseRequired: true,
        reopenedAt: now, reopenedBy: adminUid, votingOpensAt: now,
        votingClosesAt: null, reminderSentAt: null, adminReopenReminderSentAt: null,
      });
    });
    if (isTestMatchId(matchId)) {
      await db.recursiveDelete(ref.collection("results"));
    } else {
      await rebuildRankingsUnlocked(db);
    }
  });
}

/** Re-read inside the transaction: a delayed listener must never restore an old deadline. */
export function initializeVotingWindow(matchId: string, durationHours: number, db = getFirestore()) {
  const ref = matchReference(matchId, db);
  return db.runTransaction(async (tx) => {
    const match = (await tx.get(ref)).data();
    if (!match || match.status !== "voting_open") return null;
    if (!match.manualCloseRequired && !match.votingClosesAt) {
      const now = Timestamp.now();
      tx.update(ref, {
        votingOpensAt: now,
        votingClosesAt: Timestamp.fromMillis(now.toMillis() + durationHours * 3600000),
        reminderSentAt: null,
      });
    }
    return match;
  });
}

/** A stale cron snapshot cannot close a match that an admin has just reopened. */
export function closeExpiredVoting(matchId: string, now: Timestamp, db = getFirestore()) {
  const ref = matchReference(matchId, db);
  return db.runTransaction(async (tx) => {
    const match = (await tx.get(ref)).data();
    if (!match || match.status !== "voting_open" || match.manualCloseRequired === true ||
        !match.votingClosesAt || match.votingClosesAt.toMillis() > now.toMillis()) return false;
    tx.update(ref, { status: "voting_closed" });
    return true;
  });
}

type AdminNotification = { title: string; body: string; data: Record<string, string> };

export async function remindReopenedVoting(
  matchId: string, now: Timestamp,
  sendToAdmins: (message: AdminNotification) => Promise<void>, db = getFirestore(),
) {
  const ref = matchReference(matchId, db);
  const claimed = await db.runTransaction(async (tx) => {
    const match = (await tx.get(ref)).data();
    if (!match || match.status !== "voting_open" || match.manualCloseRequired !== true) return null;
    const previous: Timestamp | undefined = match.adminReopenReminderSentAt;
    if (previous && now.toMillis() - previous.toMillis() < REOPEN_REMINDER_INTERVAL_MS) return null;
    tx.update(ref, { adminReopenReminderSentAt: now });
    return { match, previous: previous ?? null };
  });
  if (!claimed) return false;
  try {
    await sendToAdmins({
      title: `${isTestMatchId(matchId) ? "[TEST] " : ""}Vote rouvert à clôturer`,
      body: `Le vote contre ${claimed.match.opponent ?? "l'adversaire"} est toujours ouvert. Clôturez-le manuellement pour finaliser ${isTestMatchId(matchId) ? "les résultats du test" : "le classement"}.`,
      data: { type: "admin_reopened_vote_reminder", matchId },
    });
  } catch (error) {
    // Permit the next cron to retry, without overwriting a newer reminder/reopening.
    await db.runTransaction(async (tx) => {
      const current = (await tx.get(ref)).data();
      if (current?.adminReopenReminderSentAt?.isEqual(now)) {
        tx.update(ref, { adminReopenReminderSentAt: claimed.previous });
      }
    });
    throw error;
  }
  return true;
}
