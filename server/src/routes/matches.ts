import { Router } from "express";
import { getFirestore } from "firebase-admin/firestore";
import { requireAuth, requireAdmin } from "../middleware/auth";
import { handleVotingClosed } from "../matchListeners";
import { rebuildRankingsAndStats } from "../rebuildRankings";

export const matchesRouter = Router();
matchesRouter.use(requireAuth, requireAdmin);

/**
 * Recalcule results/summary + rankings_cache + player_stats pour un match
 * déjà clôturé, sans dépendre du listener Firestore (qui réinitialise sa
 * mémoire des statuts à chaque redémarrage du serveur — voir le commentaire
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

  try {
    await handleVotingClosed(matchId, matchDoc.data()!);
    res.json({ success: true });
  } catch (e: any) {
    res.status(500).json({ error: e.message ?? "Erreur lors du recalcul." });
  }
});

/**
 * Reconstruit entièrement rankings_cache et player_stats à partir de tous
 * les results/summary existants (voir rebuildRankings.ts) — l'outil à
 * utiliser après un pépin sur le cache (suppression, bug corrigé après
 * coup, etc.), plutôt que de rejouer chaque match un par un : celui-ci ne
 * dépend d'aucun état préalable, contrairement au recalcul par match qui
 * n'applique qu'une différence par rapport au dernier calcul.
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
