import { Router } from "express";
import { requireAuth, requireAdmin, AuthedRequest } from "../middleware/auth";
import { matchReference } from "../matchReference";
import { saveTestVote } from "../testVotes";
import { voteParticipation } from "../voteParticipation";
import { resetVote } from "../resetVote";
import { reopenVoting } from "../votingLifecycle";
import { handleVotingClosed } from "../matchListeners";
import { deleteMatchAndRebuild, rebuildRankingsAndStats } from "../rebuildRankings";

export const matchesRouter = Router();
matchesRouter.use(requireAuth, requireAdmin);

matchesRouter.post("/:matchId/votes/:voterUid/reset", async (req: AuthedRequest, res) => {
  try {
    await resetVote(req.params.matchId, req.params.voterUid, req.uid!, req.body?.voteVersion);
    res.json({ success: true });
  } catch (e: any) {
    res.status(e.status ?? 500).json({ error: e.message ?? "Impossible de réinitialiser ce vote." });
  }
});

matchesRouter.post("/:matchId/reopen", async (req: AuthedRequest, res) => {
  try {
    await reopenVoting(req.params.matchId, req.uid!);
    res.json({ success: true });
  } catch (e: any) {
    res.status(e.status ?? 500).json({ error: e.message ?? "Erreur lors de la réouverture." });
  }
});

matchesRouter.get("/:matchId/participation", async (req: AuthedRequest, res) => {
  res.setHeader("Cache-Control", "no-store");
  try {
    res.json(await voteParticipation(req.params.matchId, req.uid!));
  } catch (e: any) {
    res.status(e.status ?? 500).json({ error: e.message ?? "Suivi des votes indisponible." });
  }
});

matchesRouter.post("/:matchId/test-vote", async (req: AuthedRequest, res) => {
  try {
    await saveTestVote(req.params.matchId, req.uid!, req.body);
    res.json({ success: true });
  } catch (e: any) {
    res.status(e.status ?? 500).json({ error: e.message ?? "Erreur de simulation." });
  }
});

matchesRouter.delete("/:matchId", async (req, res) => {
  try {
    const result = await deleteMatchAndRebuild(req.params.matchId);
    res.json({ success: true, ...result });
  } catch (e: any) {
    res.status(500).json({ error: e.message ?? "Erreur lors de la suppression." });
  }
});

/**
 * Recalcule results/summary + rankings_cache + player_stats pour un match
 * déjà clôturé, sans dépendre du listener Firestore (qui réinitialise sa
 * mémoire des statuts à chaque redémarrage du serveur - voir le commentaire
 * dans matchListeners.ts). Le calcul est idempotent (voir handleVotingClosed),
 * donc rappeler cette route plusieurs fois sur le même match est sans danger.
 */
matchesRouter.post("/:matchId/recompute", async (req, res) => {
  const { matchId } = req.params;
  const matchDoc = await matchReference(matchId).get();

  if (!matchDoc.exists) {
    return res.status(404).json({ error: "Match introuvable." });
  }
  if (matchDoc.data()!.status !== "voting_closed") {
    return res.status(409).json({ error: "Le vote de ce match n'est pas clôturé." });
  }

  try {
    await handleVotingClosed(matchId, matchDoc.data()!);
    res.json({ success: true });
  } catch (e: any) {
    res.status(500).json({ error: e.message ?? "Erreur lors du recalcul." });
  }
});

/**
 * Repart des votes des matchs clôturés, nettoie les matchs supprimés et
 * remplace les totaux et historiques. Partage la file avec les clôtures
 * et les suppressions pour éviter les écritures concurrentes du VPS.
 */
matchesRouter.post("/rankings/rebuild", async (req, res) => {
  try {
    const result = await rebuildRankingsAndStats();
    res.json({ success: true, ...result });
  } catch (e: any) {
    res
      .status(500)
      .json({ error: e.message ?? "Erreur lors de la reconstruction." });
  }
});
