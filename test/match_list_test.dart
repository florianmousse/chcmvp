import 'dart:async';

import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'package:chc_mvp/features/voting/presentation/voting_providers.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chc_mvp/core/models/match_model.dart';
import 'package:chc_mvp/core/utils/season.dart';
import 'package:chc_mvp/features/matches/domain/match_list.dart';
import 'package:chc_mvp/features/matches/presentation/matches_providers.dart';
import 'package:chc_mvp/features/matches/presentation/matches_screen.dart';
import 'support/dashboard_fixture.dart';

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
  setUpAll(() => initializeDateFormatting('fr_FR'));

  testWidgets('Le match quitte la priorité dès que le vote est enregistré', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final votes = StreamController<bool>();
    addTearDown(votes.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...demoOverrides,
          canManageMatchesProvider.overrideWith((ref) => false),
          hasVotedProvider.overrideWith((ref, id) => votes.stream),
        ],
        child: const MaterialApp(home: MatchesScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
    votes.add(false);
    await tester.pumpAndSettle();
    List<String> opponents() => tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .whereType<String>()
        .where((text) => ['Rennes', 'Nantes', 'Angers'].contains(text))
        .toList();
    expect(opponents(), ['Rennes', 'Nantes', 'Angers']);
    votes.add(true);
    await tester.pumpAndSettle();
    expect(opponents(), ['Nantes', 'Rennes', 'Angers']);
    expect(find.text('Déjà voté'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  test(
    'Votes ouverts non effectués prioritaires, puis dates décroissantes',
    () {
      final matches = [
        match('closed-new', 25, MatchStatus.votingClosed),
        match('open-old', 1, MatchStatus.votingOpen),
        match('upcoming', 20, MatchStatus.upcoming),
        match('open-new', 10, MatchStatus.votingOpen),
        match('closed-old', 15, MatchStatus.votingClosed),
        match('open-voted', 5, MatchStatus.votingOpen),
      ];
      expect(
        sortMatchList(
          matches,
          pendingVoteMatchIds: {'open-old', 'open-new', 'closed-old'},
        ).map((m) => m.id),
        [
          'open-new',
          'open-old',
          'closed-new',
          'upcoming',
          'closed-old',
          'open-voted',
        ],
      );
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

  test(
    'Même jour : heure décroissante, indépendamment du timestamp et de l\'ID',
    () {
      final matches = [
        for (final (id, time, hour) in [
          ('a', '19:50', 23),
          ('b', '18:45', 12),
          ('c', '21:15', 0),
          ('d', '16:45', 20),
        ])
          match(
            id,
            10,
            MatchStatus.votingOpen,
          ).copyWith(time: time, date: DateTime(2026, 10, 10, hour)),
      ];
      expect(sortMatchList(matches).map((m) => m.id), ['c', 'a', 'b', 'd']);
      expect(
        sortMatchList(
          matches,
          pendingVoteMatchIds: {'a', 'b', 'c', 'd'},
        ).map((m) => m.id),
        ['c', 'a', 'b', 'd'],
      );
      expect(
        sortMatchList([
          matches.first.copyWith(id: 'z'),
          matches.first,
        ]).map((m) => m.id),
        ['a', 'z'],
      );
    },
  );

  test(
    'Administration : tri date et heure des matchs réels et de test',
    () async {
      final container = ProviderContainer(
        overrides: [
          matchesListProvider.overrideWith(
            (ref, team) => Stream.value([
              match('open', 10, MatchStatus.votingOpen).copyWith(time: '18:45'),
              match('closed', 11, MatchStatus.votingClosed),
            ]),
          ),
          testMatchesListProvider.overrideWith(
            (ref) => Stream.value([
              match(
                'test:late',
                10,
                MatchStatus.upcoming,
              ).copyWith(time: '21:15'),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(matchesListProvider(null).future);
      await container.read(testMatchesListProvider.future);
      expect(
        container.read(adminMatchesListProvider).requireValue.map((m) => m.id),
        ['closed', 'test:late', 'open'],
      );
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
