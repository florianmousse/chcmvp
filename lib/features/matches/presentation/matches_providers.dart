import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/models/match_model.dart';
import 'package:chc_mvp/core/models/player_match_stats_model.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'package:chc_mvp/features/matches/data/matches_repository.dart';

final matchesRepositoryProvider = Provider<MatchesRepository>((ref) {
  return MatchesRepository(
    ref.watch(firestoreProvider),
    ref.watch(serverClientProvider),
  );
});

final matchesListProvider = StreamProvider.family<List<MatchModel>, String?>((
  ref,
  team,
) {
  // Voir le commentaire équivalent dans members_providers.dart : force la
  // recréation du listener à chaque changement de compte connecté.
  ref.watch(authStateProvider);
  return ref.watch(matchesRepositoryProvider).watchMatches(team: team);
});

/// Résumé calculé côté serveur (voir server/src/matchListeners.ts) - entries
/// par joueur + mvpUid. Nul tant que le vote n'est pas clôturé.
final matchResultProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, matchId) {
      ref.watch(authStateProvider);
      return ref
          .watch(firestoreProvider)
          .collection('matches')
          .doc(matchId)
          .collection('results')
          .doc('summary')
          .snapshots()
          .map((d) => d.data());
    });

// ─── Stats individuelles par match ─────────────────────────────────────

/// Stats individuelles de chaque joueur pour un match donné.
final playerMatchStatsProvider =
    StreamProvider.family<List<PlayerMatchStats>, String>((ref, matchId) {
      ref.watch(authStateProvider);
      return ref
          .watch(matchesRepositoryProvider)
          .watchPlayerMatchStats(matchId);
    });

/// Stats agrégées de tous les matchs de la saison courante.
/// Recalculé automatiquement à chaque changement de la liste de matchs
/// ou des stats d'un match.
final aggregatedPlayerStatsProvider =
    Provider<AsyncValue<Map<String, AggregatedPlayerStats>>>((ref) {
      final matchesAsync = ref.watch(matchesListProvider(null));

      return matchesAsync.when(
        data: (matches) {
          final agg = <String, _MutableStats>{};
          var loadingCount = 0;

          for (final match in matches) {
            if (match.status != MatchStatus.votingClosed) continue;

            final statsAsync = ref.watch(playerMatchStatsProvider(match.id));
            statsAsync.whenData((statsList) {
              for (final s in statsList) {
                final ms = agg.putIfAbsent(s.playerId, _MutableStats.new);
                ms.goals += s.goals;
                ms.assists += s.assists;
                ms.greenCards += s.greenCards;
                ms.yellowCards += s.yellowCards;
                ms.redCards += s.redCards;
                ms.matchesPlayed++;
              }
            });
            if (statsAsync.isLoading) loadingCount++;
          }

          if (loadingCount > 0 && agg.isEmpty) {
            return const AsyncValue.loading();
          }

          return AsyncValue.data({
            for (final e in agg.entries)
              e.key: AggregatedPlayerStats(
                goals: e.value.goals,
                assists: e.value.assists,
                greenCards: e.value.greenCards,
                yellowCards: e.value.yellowCards,
                redCards: e.value.redCards,
                matchesPlayed: e.value.matchesPlayed,
              ),
          });
        },
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      );
    });

/// Helper mutable pour l'agrégation interne.
class _MutableStats {
  int goals = 0;
  int assists = 0;
  int greenCards = 0;
  int yellowCards = 0;
  int redCards = 0;
  int matchesPlayed = 0;
}

/// Stats agrégées d'un joueur sur tous les matchs clôturés.
class AggregatedPlayerStats {
  final int goals;
  final int assists;
  final int greenCards;
  final int yellowCards;
  final int redCards;
  final int matchesPlayed;

  const AggregatedPlayerStats({
    this.goals = 0,
    this.assists = 0,
    this.greenCards = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.matchesPlayed = 0,
  });

  int get totalCards => greenCards + yellowCards + redCards;
}
