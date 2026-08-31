import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import {
  VOTE_DURATION_HOURS,
  REMINDER_BEFORE_HOURS,
  VOTE_OPEN_DELAY_HOURS,
  ADMIN_REMINDER_BEFORE_HOURS,
} from "./firebase";

export interface ClubSettings {
  voteDurationHours: number;
  reminderBeforeHours: number;
  voteOpenDelayHours: number;
  adminReminderBeforeHours: number;
}

/** Réglages globaux du club (settings/global, modifiable par l'admin), avec repli sur les valeurs de .env. */
export async function getClubSettings(): Promise<ClubSettings> {
  const snap = await getFirestore().doc("settings/global").get();
  const defaults: ClubSettings = {
    voteDurationHours: VOTE_DURATION_HOURS,
    reminderBeforeHours: REMINDER_BEFORE_HOURS,
    voteOpenDelayHours: VOTE_OPEN_DELAY_HOURS,
    adminReminderBeforeHours: ADMIN_REMINDER_BEFORE_HOURS,
  };
  if (!snap.exists) return defaults;
  return { ...defaults, ...(snap.data() as Partial<ClubSettings>) };
}

export async function notifyMembers({
  title,
  body,
  team,
  excludeUids = [],
  onlyUids,
  data,
}: {
  title: string;
  body: string;
  team?: string;
  excludeUids?: string[];
  /** Si fourni, seuls les users dont l'uid est dans cette liste reçoivent la notification. */
  onlyUids?: string[];
  data?: Record<string, string>;
}): Promise<void> {
  const firestore = getFirestore();
  let query = firestore.collection("users").where("isActive", "==", true) as FirebaseFirestore.Query;
  if (team) query = query.where("team", "==", team);

  const usersSnap = await query.get();
  const exclude = new Set(excludeUids);
  const only = onlyUids ? new Set(onlyUids) : null;

  const tokens: string[] = [];
  usersSnap.forEach((doc) => {
    if (exclude.has(doc.id)) return;
    if (only && !only.has(doc.id)) return;
    const fcmTokens: string[] = doc.data().fcmTokens ?? [];
    tokens.push(...fcmTokens);
  });

  if (tokens.length === 0) {
    console.log(`notifyMembers: aucun token à notifier pour "${title}"`);
    return;
  }

  await sendToTokens(tokens, { title, body }, data);
}

/**
 * Envoie une notification uniquement aux administrateurs (role === "admin").
 * Utile pour les rappels de feuille de présence.
 */
export async function notifyAdmins({
  title,
  body,
  data,
}: {
  title: string;
  body: string;
  data?: Record<string, string>;
}): Promise<void> {
  const firestore = getFirestore();
  const adminsSnap = await firestore
    .collection("users")
    .where("isActive", "==", true)
    .where("role", "==", "admin")
    .get();

  const tokens: string[] = [];
  adminsSnap.forEach((doc) => {
    const fcmTokens: string[] = doc.data().fcmTokens ?? [];
    tokens.push(...fcmTokens);
  });

  if (tokens.length === 0) {
    console.log(`notifyAdmins: aucun token admin pour "${title}"`);
    return;
  }

  await sendToTokens(tokens, { title, body }, data);
}

/** Envoie les notifications par paquets de 500 et nettoie les tokens expirés. */
async function sendToTokens(
  tokens: string[],
  notification: { title: string; body: string },
  data?: Record<string, string>,
): Promise<void> {
  const chunks: string[][] = [];
  for (let i = 0; i < tokens.length; i += 500) {
    chunks.push(tokens.slice(i, i + 500));
  }

  const staleTokens: string[] = [];
  for (const chunk of chunks) {
    const response = await getMessaging().sendEachForMulticast({
      tokens: chunk,
      notification,
      data,
    });
    response.responses.forEach((r, i) => {
      if (!r.success && r.error?.code === "messaging/registration-token-not-registered") {
        staleTokens.push(chunk[i]);
      }
    });
  }

  if (staleTokens.length > 0) {
    await pruneStaleTokens(staleTokens);
  }
}

async function pruneStaleTokens(staleTokens: string[]): Promise<void> {
  const firestore = getFirestore();
  const usersSnap = await firestore
    .collection("users")
    .where("fcmTokens", "array-contains-any", staleTokens.slice(0, 10))
    .get();
  const batch = firestore.batch();
  usersSnap.forEach((doc) => {
    const current: string[] = doc.data().fcmTokens ?? [];
    const cleaned = current.filter((t) => !staleTokens.includes(t));
    batch.update(doc.ref, { fcmTokens: cleaned });
  });
  await batch.commit();
}
