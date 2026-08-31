import { initializeApp, applicationDefault } from "firebase-admin/app";
import * as dotenv from "dotenv";

dotenv.config();

// Sur Cloud Functions, les identifiants admin sont fournis automatiquement.
// Sur un VPS classique, il faut pointer explicitement vers le fichier de
// clé de service via la variable d'environnement standard Google
// (GOOGLE_APPLICATION_CREDENTIALS, définie dans .env / le service systemd).
initializeApp({
  credential: applicationDefault(),
});

/** Délai entre la fin du match et l'ouverture automatique du vote (en heures). */
export const VOTE_OPEN_DELAY_HOURS = Number(process.env.VOTE_OPEN_DELAY_HOURS ?? 2);

/** Durée pendant laquelle le vote reste ouvert (en heures). */
export const VOTE_DURATION_HOURS = Number(process.env.VOTE_DURATION_HOURS ?? 48);

/** Envoyer un rappel X heures avant la clôture du vote. */
export const REMINDER_BEFORE_HOURS = Number(process.env.REMINDER_BEFORE_HOURS ?? 24);

/** Envoyer un rappel admin X heures avant le match si la feuille de présence
 *  n'est pas remplie (en heures). */
export const ADMIN_REMINDER_BEFORE_HOURS = Number(process.env.ADMIN_REMINDER_BEFORE_HOURS ?? 1);
