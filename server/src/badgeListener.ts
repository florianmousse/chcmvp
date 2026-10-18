import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

/**
 * Écoute en temps réel les modifications dans la collection `userBadges`.
 * Quand un joueur débloque un nouveau badge (clé ajoutée dans la map `earned`),
 * il reçoit une notification push de félicitations.
 */

// Labels lisibles pour chaque type de badge
const BADGE_LABELS: Record<string, { emoji: string; label: string }> = {
  mvpSaison: { emoji: "🏆", label: "MVP de la saison" },
  serieTop3: { emoji: "🔥", label: "En feu" },
  plebiscite: { emoji: "🤝", label: "Plébiscité" },
  revelation: { emoji: "🚀", label: "Révélation" },
  votantAssidu: { emoji: "🗳️", label: "Votant assidu" },
  centurion: { emoji: "💯", label: "Centurion" },
  podiumMaster: { emoji: "🥇", label: "Podium Master" },
  regularite: { emoji: "📊", label: "Régularité" },
  buteur: { emoji: "⚽", label: "Buteur" },
  passeurDor: { emoji: "🎯", label: "Passeur d'or" },
  fairPlay: { emoji: "😇", label: "Fair-play" },
  couteauSuisse: { emoji: "🦸", label: "Couteau suisse" },
};

export function startBadgeListener(): void {
  const firestore = getFirestore();

  // Cache du dernier état connu de chaque document userBadges.
  // Clé = userId, Valeur = Set de types de badge déjà connus.
  const lastKnownBadges = new Map<string, Set<string>>();
  let isFirstSnapshot = true;

  firestore.collection("userBadges").onSnapshot(
    (snapshot) => {
      if (isFirstSnapshot) {
        // Premier instantané : remplir le cache sans envoyer de notifications
        snapshot.forEach((doc) => {
          const earned = (doc.data().earned ?? {}) as Record<string, Timestamp>;
          lastKnownBadges.set(doc.id, new Set(Object.keys(earned)));
        });
        isFirstSnapshot = false;
        console.log(
          `Listener badges initialisé (${snapshot.size} joueurs en cache).`,
        );
        return;
      }

      snapshot.docChanges().forEach((change) => {
        if (change.type === "removed") {
          lastKnownBadges.delete(change.doc.id);
          return;
        }

        const userId = change.doc.id;
        const earned = (change.doc.data().earned ?? {}) as Record<
          string,
          Timestamp
        >;
        const currentTypes = new Set(Object.keys(earned));
        const previousTypes = lastKnownBadges.get(userId) ?? new Set();

        // Détecter les NOUVEAUX badges (présents maintenant mais pas avant)
        const newBadges: string[] = [];
        for (const type of currentTypes) {
          if (!previousTypes.has(type)) {
            newBadges.push(type);
          }
        }

        // Mettre à jour le cache
        lastKnownBadges.set(userId, currentTypes);

        if (newBadges.length > 0) {
          sendBadgeNotification(userId, newBadges).catch((e) =>
            console.error(
              `Erreur notification badge pour ${userId}:`,
              e,
            ),
          );
        }
      });
    },
    (error) => {
      console.error("Erreur du listener userBadges :", error);
    },
  );
}

async function sendBadgeNotification(
  userId: string,
  newBadgeTypes: string[],
): Promise<void> {
  const firestore = getFirestore();

  // Récupérer les tokens FCM du joueur
  const userDoc = await firestore.collection("users").doc(userId).get();
  if (!userDoc.exists) return;
  const userData = userDoc.data()!;
  const fcmTokens: string[] = userData.fcmTokens ?? [];
  if (fcmTokens.length === 0) return;

  // Construire le message
  const badgeLabels = newBadgeTypes.map((type) => {
    const info = BADGE_LABELS[type];
    return info ? `${info.emoji} ${info.label}` : type;
  });

  const title =
    newBadgeTypes.length === 1
      ? "Nouveau badge débloqué ! 🎉"
      : `${newBadgeTypes.length} nouveaux badges ! 🎉`;
  const body =
    newBadgeTypes.length === 1
      ? `Tu as obtenu le badge ${badgeLabels[0]} !`
      : `Tu as obtenu : ${badgeLabels.join(", ")}`;

  const firstName = userData.firstName ?? "Joueur";
  console.log(
    `Badge notification pour ${firstName} (${userId}): ${badgeLabels.join(", ")}`,
  );

  // Envoyer la notification
  const staleTokens: string[] = [];
  const chunks: string[][] = [];
  for (let i = 0; i < fcmTokens.length; i += 500) {
    chunks.push(fcmTokens.slice(i, i + 500));
  }

  for (const chunk of chunks) {
    const response = await getMessaging().sendEachForMulticast({
      tokens: chunk,
      notification: { title, body },
      data: { type: "badge_earned", badges: newBadgeTypes.join(",") },
    });
    response.responses.forEach((r, i) => {
      if (
        !r.success &&
        r.error?.code === "messaging/registration-token-not-registered"
      ) {
        staleTokens.push(chunk[i]);
      }
    });
  }

  // Nettoyage des tokens expirés
  if (staleTokens.length > 0) {
    const current: string[] = userData.fcmTokens ?? [];
    const cleaned = current.filter((t: string) => !staleTokens.includes(t));
    await firestore
      .collection("users")
      .doc(userId)
      .update({ fcmTokens: cleaned });
  }
}
