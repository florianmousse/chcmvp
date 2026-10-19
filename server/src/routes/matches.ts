import { Router } from "express";
import { getFirestore } from "firebase-admin/firestore";
import { requireAuth, requireAdmin } from "../middleware/auth";
import { handleVotingClosed } from "../matchListeners";
import { deleteMatchAndRebuild, rebuildRankingsAndStats } from "../rebuildRankings";

export const matchesRouter = Router();
matchesRouter.use(requireAuth, requireAdmin);

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
  const matchDoc = await getFirestore()
    .collection("matches")
    .doc(matchId)
    .get();

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
