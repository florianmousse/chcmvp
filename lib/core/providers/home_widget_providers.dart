import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/models/match_model.dart';
import 'package:chc_mvp/core/services/home_widget_service.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'package:chc_mvp/features/matches/presentation/matches_providers.dart';
import 'package:chc_mvp/features/ranking/presentation/ranking_providers.dart';

/// Provider qui maintient les widgets Android à jour en écoutant les données.
/// Doit être watch() dans HockeyClubApp pour rester actif.
final homeWidgetSyncProvider = Provider<void>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return; // Pas connecté → rien à sync

  final matchesAsync = ref.watch(matchesListProvider(null));
  final rankingAsync = ref.watch(rankingProvider('general'));

  // ── Prochain match ──
  matchesAsync.whenData((matches) {
    final now = DateTime.now();
    final upcoming = matches
        .where((m) => m.status == MatchStatus.upcoming && m.date.isAfter(now))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    HomeWidgetService.updateNextMatch(upcoming.isNotEmpty ? upcoming.first : null);
  });

  // ── Mon classement ──
  rankingAsync.whenData((ranking) {
    final uid = user.uid;
    final idx = ranking.indexWhere((e) => e.uid == uid);
    if (idx >= 0) {
      final entry = ranking[idx];
      HomeWidgetService.updateRanking(
        position: idx + 1,
        totalPoints: entry.points,
        matchesPlayed: entry.firstCount + entry.secondCount + entry.thirdCount,
      );
    }
  });

  // ── Dernier résultat ──
  matchesAsync.whenData((matches) {
    final closed = matches
        .where((m) => m.status == MatchStatus.votingClosed)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (closed.isNotEmpty) {
      HomeWidgetService.updateLastResult(match: closed.first);
    }
  });
});
