import 'package:chc_mvp/features/home/domain/advanced_stats_calculator.dart';
import 'package:chc_mvp/features/home/domain/badge_model.dart';
import 'package:chc_mvp/features/ranking/data/ranking_repository.dart';

/// Détermine les badges gagnés par un joueur à partir de ses stats, de son
/// historique et du contexte de la saison. Calcul pur côté client — pas de
/// persistence Firestore, recalculé à chaque rendu.
class BadgeCalculator {
  /// Calcule la liste de badges d'un joueur donné.
  ///
  /// [stats]            Stats agrégées du joueur (player_stats/{uid}).
  /// [history]          Historique match par match, trié par date croissante.
  /// [ranking]          Classement général de la saison (trié par points desc).
  /// [allHistories]     Historiques de tous les joueurs (pour le badge Régularité).
  /// [seasonMatchCount] Nombre total de matchs clôturés dans la saison.
  /// [playerMatchesEligibleCount] Nombre de matchs où le joueur était présent
  ///                              et le vote a eu lieu (pour votant assidu).
  /// [playerVotedCount] Nombre de matchs où le joueur a effectivement voté.
  /// [isSeasonFinished] Si true, la saison est terminée et les badges de fin
  ///                    de saison (MVP, Votant assidu) peuvent être décernés.
  static List<Badge> compute({
    required String uid,
    required PlayerStats stats,
    required List<PlayerHistoryPoint> history,
    required List<RankingEntry> ranking,
    required Map<String, List<PlayerHistoryPoint>> allHistories,
    required int seasonMatchCount,
    required int playerMatchesEligibleCount,
    required int playerVotedCount,
    required bool isSeasonFinished,
  }) {
    final badges = <Badge>[];
    const def = Badge.allDefinitions;

    // 🏆 MVP de la saison — numéro 1 au classement général EN FIN DE SAISON.
    //     Pas attribué en cours de saison (ça n'aurait pas de sens).
    if (isSeasonFinished &&
        ranking.isNotEmpty &&
        ranking.first.uid == uid) {
      badges.add(def[BadgeType.mvpSaison]!);
    }

    // 🔥 Série top 3 — 5 matchs consécutifs ou plus dans le top 3
    if (bestTop3StreakEver(history) >= 5) {
      badges.add(def[BadgeType.serieTop3]!);
    }

    // 🤝 Plébiscité — au moins un match où 80%+ des coéquipiers ont voté
    //     pour lui. On utilise `distinctVotersThisMatch` dans l'historique.
    for (final h in history) {
      if (h.distinctVotersThisMatch != null &&
          h.presentCount != null &&
          h.presentCount! > 0) {
        final ratio = h.distinctVotersThisMatch! / h.presentCount!;
        if (ratio >= 0.8) {
          badges.add(def[BadgeType.plebiscite]!);
          break;
        }
      }
    }

    // 🚀 Révélation — +40% de moyenne par rapport aux 5 premiers matchs
    if (history.length >= 6) {
      final first5 =
          history.take(5).map((h) => h.points).reduce((a, b) => a + b) / 5.0;
      final rest = history.skip(5).toList();
      final avgRest =
          rest.map((h) => h.points).reduce((a, b) => a + b) / rest.length;
      if (first5 > 0 && ((avgRest - first5) / first5) >= 0.4) {
        badges.add(def[BadgeType.revelation]!);
      }
    }

    // 🗳️ Votant assidu — 100% de participation sur une saison complète
    //     UNIQUEMENT décerné une fois la saison terminée.
    if (isSeasonFinished &&
        seasonMatchCount > 0 &&
        playerMatchesEligibleCount >= seasonMatchCount &&
        playerVotedCount >= playerMatchesEligibleCount) {
      badges.add(def[BadgeType.votantAssidu]!);
    }

    // 💯 Centurion — 100+ points cumulés
    if (stats.totalPoints >= 100) {
      badges.add(def[BadgeType.centurion]!);
    }

    // 🥇 Podium Master — 10+ premières places
    if (stats.firstCount >= 10) {
      badges.add(def[BadgeType.podiumMaster]!);
    }

    // 📊 Régularité — écart-type le plus faible parmi tous les joueurs
    //     ayant joué au moins 5 matchs
    if (history.length >= 5) {
      final myStdDev = standardDeviation(history.map((h) => h.points).toList());
      var isLowest = true;
      for (final other in allHistories.entries) {
        if (other.key == uid || other.value.length < 5) continue;
        final otherStdDev =
            standardDeviation(other.value.map((h) => h.points).toList());
        if (otherStdDev < myStdDev) {
          isLowest = false;
          break;
        }
      }
      if (isLowest) {
        badges.add(def[BadgeType.regularite]!);
      }
    }

    return badges;
  }
}
