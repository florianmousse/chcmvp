import "./firebase"; // initialise firebase-admin avant tout le reste
import express from "express";
import { dataRouter } from "./routes/data";
import path from "path";
import cron from "node-cron";
import { startBadgeListener } from "./badgeListener";
import { startMatchListeners } from "./matchListeners";
import { processScheduledVoting } from "./scheduledVoting";
import { authRouter } from "./routes/auth";
import { membersRouter } from "./routes/members";
import { matchesRouter } from "./routes/matches";
import { ceremoniesRouter } from "./routes/ceremonies";
import { createCorsMiddleware } from "./middleware/cors";

import { getFirestore } from 'firebase-admin/firestore';
import { notifyMembers } from './notify';
import { processCeremonyNotifications } from './ceremonyNotifications';

const deliverCeremonies = () => processCeremonyNotifications(getFirestore(), notifyMembers)
  .catch(e => console.error('Notifications cérémonies:', e));
getFirestore().collection('ceremony_notifications').where('done', '==', false)
  .onSnapshot(snapshot => {
    if (snapshot.docChanges().some(change => change.type === 'added')) void deliverCeremonies();
  }, e => console.error('Listener cérémonies:', e));
cron.schedule('*/10 * * * *', () => { void deliverCeremonies(); });

const app = express();
app.use(
  createCorsMiddleware((process.env.WEB_ALLOWED_ORIGINS ?? "").split(",")),
);
app.use(express.json());

app.get("/health", (_req, res) =>
  res.json({ status: "ok", time: new Date().toISOString() }),
);

// authRouter est volontairement public (pas de requireAuth) - contrairement
// aux deux routeurs suivants, qui exigent un admin authentifié.
app.use("/auth", authRouter);
app.use("/data", dataRouter);
app.use("/members", membersRouter);
app.use("/matches", matchesRouter);
app.use("/ceremonies", ceremoniesRouter);

// Sert server/public/ tel quel (ex: /privacy.html) - dossier à côté de src/,
// jamais compilé par TypeScript, donc pas dans dist/. process.cwd() vaut
// /opt/hockey-club-server puisque c'est le WorkingDirectory du service
// systemd (voir deploy/hockey-club-server.service).
app.use(express.static(path.join(process.cwd(), "public")));

// Équivalent du trigger Firestore onDocumentUpdated : une connexion ouverte
// en continu, viable ici car le VPS ne s'endort jamais (contrairement à un
// service serverless gratuit qui se met en veille).
startMatchListeners();
startBadgeListener();

// Traitement périodique du cycle de vie des votes : ouverture automatique,
// rappels, clôture. Toutes les 10 minutes pour une réactivité raisonnable
// (un match de 20:00 → vote ouvert entre 22:00 et 22:10 au plus tard).
cron.schedule("*/10 * * * *", () => {
  processScheduledVoting().catch((e) =>
    console.error("Erreur processScheduledVoting :", e),
  );
});

const port = Number(process.env.PORT ?? 8080);
app.listen(port, () => {
  console.log(`Serveur CHC MVP démarré sur le port ${port}`);
});
