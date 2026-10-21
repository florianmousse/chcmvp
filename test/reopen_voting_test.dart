import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:chc_mvp/core/models/match_model.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'package:chc_mvp/features/matches/presentation/matches_admin_screen.dart';
import 'package:chc_mvp/features/matches/presentation/matches_providers.dart';
import 'package:chc_mvp/features/matches/presentation/vote_participation.dart';
import 'package:chc_mvp/features/ranking/data/ranking_repository.dart';
import 'test_match_test.dart' show RecordingMatches, match;

class ReopeningMatches extends RecordingMatches {
  @override
  Future<void> reopenVoting(String id) async => calls.add('reopen:$id');
}

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  test(
    'old zero-point cache entries disappear without losing positive ties',
    () {
      final entries = RankingRepository.rankingEntriesWithPoints({
        'fourth': {'points': 0},
        'a': {'points': 5, 'firstCount': 1},
        'b': {'points': 5, 'firstCount': 1},
        'c': {'points': 5, 'firstCount': 1},
        'd': {'points': 5, 'firstCount': 1},
      });
      expect(entries.map((e) => e.uid), ['a', 'b', 'c', 'd']);
      expect(
        RankingRepository.rankingEntriesWithPoints({
          'zero': <String, dynamic>{},
        }),
        isEmpty,
      );
    },
  );

  test(
    'old matches default to automatic closing; reopened flag survives JSON',
    () {
      final old = match.toJson()
        ..remove('manualCloseRequired')
        ..['pointsScale'] = match.pointsScale.toJson();
      expect(MatchModel.fromJson(old).manualCloseRequired, isFalse);
      expect(
        MatchModel.fromJson({
          ...old,
          'manualCloseRequired': true,
        }).manualCloseRequired,
        isTrue,
      );
    },
  );

  for (final width in [390.0, 1440.0]) {
    testWidgets('admin confirms reopening a closed match ($width)', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = ReopeningMatches();
      final closed = match.copyWith(
        id: 'real',
        status: MatchStatus.votingClosed,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isAdminProvider.overrideWithValue(true),
            matchesRepositoryProvider.overrideWithValue(repo),
            adminMatchesListProvider.overrideWith(
              (ref) => AsyncValue.data([closed]),
            ),
            voteParticipationProvider.overrideWith(
              (ref, id) => Stream.value({
                'votedCount': 2,
                'totalCount': 4,
                'pending': [],
              }),
            ),
          ],
          child: const MaterialApp(home: MatchesAdminScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rouvrir le vote'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(repo.calls, isEmpty);
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rouvrir le vote'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rouvrir'));
      await tester.pumpAndSettle();
      expect(repo.calls, ['reopen:real']);
      expect(
        find.text('Vote rouvert. Clôture manuelle requise.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
