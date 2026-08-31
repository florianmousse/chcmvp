import "./firebase"; // initialise firebase-admin avant tout le reste
import express from "express";
import path from "path";
import cron from "node-cron";
import { startMatchListeners } from "./matchListeners";
import { processScheduledVoting } from "./scheduledVoting";
import { authRouter } from "./routes/auth";
import { membersRouter } from "./routes/members";
import { matchesRouter } from "./routes/matches";

const app = express();
app.use(express.json());

app.get("/health", (_req, res) =>
  res.json({ status: "ok", time: new Date().toISOString() }),
);

// authRouter est volontairement public (pas de requireAuth) — contrairement
// aux deux routeurs suivants, qui exigent un admin authentifié.
app.use("/auth", authRouter);
app.use("/members", membersRouter);
app.use("/matches", matchesRouter);

// Sert server/public/ tel quel (ex: /privacy.html) — dossier à côté de src/,
// jamais compilé par TypeScript, donc pas dans dist/. process.cwd() vaut
// /opt/hockey-club-server puisque c'est le WorkingDirectory du service
// systemd (voir deploy/hockey-club-server.service).
app.use(express.static(path.join(process.cwd(), "public")));

// Équivalent du trigger Firestore onDocumentUpdated : une connexion ouverte
// en continu, viable ici car le VPS ne s'endort jamais (contrairement à un
// service serverless gratuit qui se met en veille).
startMatchListeners();

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
