import 'package:chc_mvp/core/models/match_model.dart';
import 'package:chc_mvp/core/models/opponent_model.dart';
import 'package:chc_mvp/features/home/presentation/home_screen.dart';
import 'package:chc_mvp/features/matches/domain/club_record.dart';
import 'package:chc_mvp/features/matches/presentation/matches_providers.dart';
import 'package:chc_mvp/features/matches/presentation/matches_screen.dart';
import 'package:chc_mvp/features/opponents/presentation/opponent_detail_screen.dart';
import 'package:chc_mvp/features/ranking/presentation/player_stats_screen.dart';
import 'package:chc_mvp/features/ranking/presentation/ranking_screen.dart';
import 'package:chc_mvp/features/voting/presentation/vote_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'support/dashboard_fixture.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  final win = demoMatches.last;
  final loss = win.copyWith(
    id: 'away',
    isHome: false,
    scoreHome: 1,
    scoreAway: 4,
    date: DateTime(2025, 1, 1),
    status: MatchStatus.votingOpen,
  );
  final draw = win.copyWith(id: 'draw', scoreHome: 0, scoreAway: 0);

  test(
    'Bilan toutes saisons : ouverts, extérieurs, nuls ; pas de tests ni scores incomplets',
    () {
      final record = ClubRecord.fromMatches([
        win,
        loss,
        draw,
        win.copyWith(id: 'test:demo', scoreHome: 99),
        win.copyWith(id: 'future', status: MatchStatus.upcoming),
        win.copyWith(id: 'missing', scoreAway: null),
        win.copyWith(id: 'negative', scoreHome: -1),
      ]);
      expect(record.played, 3);
      expect([record.wins, record.draws, record.losses], [1, 1, 1]);
      expect([record.goalsFor, record.goalsAgainst], [4, 5]);
      expect(record.matches.last.id, 'away');
      expect(ClubRecord.fromMatches([win, draw]).goalsAgainst, 1);
      expect(ClubRecord.fromMatches([]).played, 0);
    },
  );

  test('Bilan adverse : ID prioritaire et anciens matchs sans ID par nom', () {
    final record = ClubRecord.fromMatches([
      win.copyWith(opponentId: 'angers', opponent: 'Ancien nom'),
      loss.copyWith(opponent: ' ANGERS '),
      draw.copyWith(opponentId: 'autre', opponent: 'Angers'),
      win.copyWith(opponent: 'Rennes'),
    ], opponent: const OpponentModel(id: 'angers', name: 'Angers'));
    expect(record.played, 2);
    expect([record.goalsFor, record.goalsAgainst], [4, 5]);
  });

  Future<void> mount(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...demoOverrides,
          firebaseAuthProvider.overrideWithValue(_TestAuth()),
        ],
        child: MaterialApp(home: page),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('La tuile ouvre le bilan par son titre, même sans ID adverse', (
    tester,
  ) async {
    await mount(tester, const MatchesScreen());
    await tester.tap(find.text('CHC vs Rennes'));
    await tester.pumpAndSettle();
    expect(find.byType(OpponentDetailScreen), findsOneWidget);
    expect(find.text('Historique des confrontations'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Le bouton Voter garde son action dans la tuile cliquable', (
    tester,
  ) async {
    await mount(tester, const MatchesScreen());
    await tester.tap(find.text('Voter pour les 3 meilleurs joueurs'));
    await tester.pumpAndSettle();
    expect(find.byType(VoteScreen), findsOneWidget);
    expect(find.byType(OpponentDetailScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Le logo accueil ouvre le bilan du club', (tester) async {
    await mount(tester, const HomeScreen());
    await tester.tap(find.byKey(const ValueKey('club-record-link')));
    await tester.pumpAndSettle();
    expect(find.text('Bilan du club'), findsOneWidget);
    expect(find.text('Buts marqués'), findsOneWidget);
    expect(find.text('Buts encaissés'), findsOneWidget);
    expect(find.text('CHC 3 - 1 Angers'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 1440.0]) {
    testWidgets('Bilan et profils accessibles à $width pixels', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mount(tester, const MatchHistoryScreen());
      expect(find.text('Buts encaissés'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await mount(tester, const RankingScreen());
      expect(find.text('Voir le profil'), findsWidgets);
      await tester.tap(find.text('Camille Martin').first);
      await tester.pumpAndSettle();
      expect(find.byType(PlayerStatsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Le classement Stats ouvre aussi le profil du joueur', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: demoOverrides,
        child: ProviderScope(
          overrides: [
            aggregatedPlayerStatsProvider.overrideWithValue(
              const AsyncData({
                'camille': AggregatedPlayerStats(goals: 2, matchesPlayed: 1),
              }),
            ),
          ],
          child: const MaterialApp(home: RankingScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Camille Martin').last);
    await tester.pumpAndSettle();
    expect(find.byType(PlayerStatsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _TestAuth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => null;
}
