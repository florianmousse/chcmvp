import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chc_mvp/core/models/match_model.dart';
import 'package:chc_mvp/core/utils/season.dart';
import 'package:chc_mvp/features/matches/domain/match_list.dart';
import 'package:chc_mvp/features/matches/presentation/matches_providers.dart';
import 'package:chc_mvp/features/matches/presentation/matches_screen.dart';

MatchModel match(String id, int day, MatchStatus status) => MatchModel(
  id: id,
  date: DateTime(2026, 10, day),
  time: '15:00',
  opponent: 'Club test',
  isHome: true,
  team: 'Seniors',
  status: status,
);

void main() {
  test(
    'Votes ouverts prioritaires, puis dates décroissantes sans groupe de statut',
    () {
      final matches = [
        match('closed-new', 25, MatchStatus.votingClosed),
        match('open-old', 1, MatchStatus.votingOpen),
        match('upcoming', 20, MatchStatus.upcoming),
        match('open-new', 10, MatchStatus.votingOpen),
        match('closed-old', 15, MatchStatus.votingClosed),
      ];
      expect(sortMatchList(matches).map((m) => m.id), [
        'open-new',
        'open-old',
        'closed-new',
        'upcoming',
        'closed-old',
      ]);
      expect(matches.first.id, 'closed-new');
      expect(
        sortMatchList(
          matches,
          status: MatchStatus.votingClosed,
        ).map((m) => m.id),
        ['closed-new', 'closed-old'],
      );
      expect(sortMatchList([]), isEmpty);
    },
  );

  test('Bornes de saison au 1er septembre à minuit à Paris', () {
    expect(matchSeasonStart(2026), DateTime.parse('2026-09-01T00:00:00+02:00'));
    expect(matchSeasonStart(2027), DateTime.parse('2027-09-01T00:00:00+02:00'));
    expect(matchSeasonStart(2026).isUtc, isTrue);
  });

  testWidgets('Sans match, aucune saison proposée ni requête de matchs', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          matchSeasonsProvider.overrideWith((ref) async => []),
          seasonMatchesProvider.overrideWith(
            (ref, year) => throw StateError('Saison inexistante'),
          ),
        ],
        child: const MaterialApp(home: MatchesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aucun match pour le moment.'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<int>), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Saison courante absente : sélectionner la dernière disponible', (
    tester,
  ) async {
    final latest = currentSeasonStartYear() - 2;
    final requested = <int>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          matchSeasonsProvider.overrideWith(
            (ref) async => [latest, latest - 3],
          ),
          seasonMatchesProvider.overrideWith((ref, year) {
            requested.add(year);
            return Stream.value(<MatchModel>[]);
          }),
        ],
        child: const MaterialApp(home: MatchesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(requested, [latest]);
    expect(find.text('$latest-${latest + 1}'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [390.0, 1280.0]) {
    testWidgets("Choisir uniquement une saison existante ($width)", (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final requested = <int>[];
      final current = currentSeasonStartYear();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchSeasonsProvider.overrideWith(
              (ref) async => [current, current - 2],
            ),
            seasonMatchesProvider.overrideWith((ref, year) {
              requested.add(year);
              return Stream.value(<MatchModel>[]);
            }),
            matchesListProvider.overrideWith(
              (ref, team) => throw StateError('Historique interdit'),
            ),
          ],
          child: const MaterialApp(home: MatchesScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Aucun match pour cette saison.'), findsOneWidget);
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      expect(find.text('${current - 1}-$current'), findsNothing);
      await tester.tap(find.text('${current - 2}-${current - 1}').last);
      await tester.pumpAndSettle();
      expect(requested, [current, current - 2]);
      expect(find.text('${current - 2}-${current - 1}'), findsOneWidget);
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('$current-${current + 1}').last);
      await tester.pumpAndSettle();
      expect(find.text('$current-${current + 1}'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
