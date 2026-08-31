import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'package:chc_mvp/features/ranking/data/ranking_repository.dart';

// Re-export pour que les consommateurs puissent importer les types depuis le
// même fichier que les providers.
export 'package:chc_mvp/features/ranking/data/ranking_repository.dart'
    show PlayerStats, PlayerHistoryPoint, RankingEntry;

final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  return RankingRepository(ref.watch(firestoreProvider));
});

/// scope : "general" | "2026" (annuel) | "2026-08" (mensuel)
final rankingProvider = StreamProvider.family<List<RankingEntry>, String>((
  ref,
  scope,
) {
  // Voir le commentaire équivalent dans members_providers.dart : sans ça, un
  // flux qui a émis "permission-denied" une seule fois (ex: pendant un
  // changement de compte) reste bloqué indéfiniment, ce qui se traduisait
  // par un classement qui ne se met plus jamais à jour.
  ref.watch(authStateProvider);
  return ref.watch(rankingRepositoryProvider).watchRanking(scope);
});

final playerStatsProvider = StreamProvider.family<PlayerStats, String>((
  ref,
  uid,
) {
  ref.watch(authStateProvider);
  return ref.watch(rankingRepositoryProvider).watchPlayerStats(uid);
});

final playerHistoryProvider =
    StreamProvider.family<List<PlayerHistoryPoint>, String>((ref, uid) {
      ref.watch(authStateProvider);
      return ref.watch(rankingRepositoryProvider).watchPlayerHistory(uid);
    });

/// Mois "YYYY-MM" et années "YYYY" qui ont au moins un résultat — utilisé
/// par l'écran classement pour sauter les périodes vides à la navigation.
final availableRankingScopesProvider = StreamProvider<List<String>>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(rankingRepositoryProvider).watchAvailableScopes();
});

/// Stats agrégées de TOUS les joueurs — utilisé par l'écran d'accueil pour
/// les stats avancées (joueur le plus plébiscité, révélation, etc.).
final allPlayerStatsProvider =
    StreamProvider<Map<String, PlayerStats>>((ref) {
      ref.watch(authStateProvider);
      return ref.watch(rankingRepositoryProvider).watchAllPlayerStats();
    });

/// Historiques match par match de TOUS les joueurs — utilisé par l'écran
/// d'accueil pour les séries top 3, la révélation, les stats insolites.
final allPlayerHistoriesProvider =
    StreamProvider<Map<String, List<PlayerHistoryPoint>>>((ref) {
      ref.watch(authStateProvider);
      return ref.watch(rankingRepositoryProvider).watchAllPlayerHistories();
    });

