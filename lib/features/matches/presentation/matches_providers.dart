import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/models/match_model.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'package:chc_mvp/features/matches/data/matches_repository.dart';
import 'package:chc_mvp/features/members/presentation/members_providers.dart';

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

/// Résumé calculé côté serveur (voir server/src/matchListeners.ts) — entries
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
