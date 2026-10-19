import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'package:chc_mvp/features/members/presentation/members_providers.dart';
import 'package:chc_mvp/features/voting/presentation/voting_providers.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chc_mvp/features/home/presentation/home_screen.dart';
import 'package:chc_mvp/features/home/presentation/highlight_cards.dart';
import 'package:chc_mvp/features/home/presentation/season_records_section.dart';
import 'package:chc_mvp/features/matches/presentation/matches_providers.dart';
import 'package:chc_mvp/features/ranking/presentation/ranking_providers.dart';
import 'package:chc_mvp/features/matches/presentation/match_stats_form_screen.dart';
import 'support/dashboard_fixture.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));
  testWidgets(
    'actual home cards select the clean player and use season ranking',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 2200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider.overrideWith(
              (ref) => Stream.value(demoMember),
            ),
            matchesListProvider.overrideWith(
              (ref, team) => Stream.value(demoMatches),
            ),
            membersListProvider.overrideWith(
              (ref, team) => Stream.value([
                demoMember,
                demoMember.copyWith(uid: 'guest', firstName: 'Alex'),
              ]),
            ),
            allPlayerHistoriesProvider.overrideWith((ref) => Stream.value({})),
            hasVotedProvider.overrideWith((ref, id) => Stream.value(true)),
            matchResultProvider.overrideWith(
              (ref, id) => Stream.value({
                'totalVotes': 3,
                'entries': {
                  'camille': {'points': 5},
                },
              }),
            ),
            currentSeasonProvider.overrideWithValue('2026-2027'),
            seasonGameStatsProvider.overrideWithValue(
              const AsyncData({
                'camille': AggregatedPlayerStats(
                  matchesPlayed: 12,
                  greenCards: 4,
                  goals: 5,
                ),
                'guest': AggregatedPlayerStats(matchesPlayed: 6, assists: 4),
              }),
            ),
            rankingProvider.overrideWith(
              (ref, scope) => Stream.value([
                RankingEntry(
                  uid: scope == 'general' ? 'guest' : 'camille',
                  points: scope == 'general' ? 99 : 5,
                ),
              ]),
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      final records = tester
          .widget<SeasonRecordsSection>(find.byType(SeasonRecordsSection))
          .records;
      final highlights = tester
          .widget<HighlightCardsSection>(find.byType(HighlightCardsSection))
          .cards;
      expect(
        records.singleWhere((r) => r.label == 'Le plus fair-play').value,
        contains('Alex'),
      );
      expect(
        highlights.singleWhere((r) => r.title == 'Fair-play').playerName,
        contains('Alex'),
      );
      expect(
        records.singleWhere((r) => r.label == 'Plus de points').detail,
        '5 pts',
      );
      expect(
        records.singleWhere((r) => r.label == 'Meilleur buteur').value,
        '5 buts',
      );
      expect(
        records.singleWhere((r) => r.label == 'Meilleur passeur').value,
        '4 passes D.',
      );
      expect(
        records.singleWhere((r) => r.label == 'Bilan du club').value,
        '1 V / 0 N / 0 D',
      );
      expect(
        records.singleWhere((r) => r.label == 'Taux de vote moyen').value,
        '75 %',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('match stats cannot overwrite existing values while loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...demoOverrides,
          playerMatchStatsProvider.overrideWith(
            (ref, id) => const Stream.empty(),
          ),
        ],
        child: MaterialApp(home: MatchStatsFormScreen(match: demoMatches.last)),
      ),
    );
    await tester.pump();
    final save = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Enregistrer'),
    );
    expect(save.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
