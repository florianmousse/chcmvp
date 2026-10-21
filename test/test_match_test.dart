import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chc_mvp/core/models/match_model.dart';
import 'package:chc_mvp/core/models/opponent_model.dart';
import 'package:chc_mvp/core/models/team_model.dart';
import 'package:chc_mvp/core/models/user_model.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'package:chc_mvp/features/matches/data/matches_repository.dart';
import 'package:chc_mvp/features/matches/presentation/matches_providers.dart';
import 'package:chc_mvp/features/matches/presentation/test_match_screen.dart';
import 'package:chc_mvp/features/matches/presentation/match_form_screen.dart';
import 'package:chc_mvp/features/members/presentation/members_providers.dart';
import 'package:chc_mvp/features/opponents/presentation/opponents_providers.dart';
import 'package:chc_mvp/features/teams/presentation/teams_providers.dart';

final match = MatchModel(
  id: 'test:demo',
  date: DateTime(2026, 10, 19),
  time: '15:00',
  opponent: 'Rennes',
  team: 'Seniors',
  isHome: true,
  status: MatchStatus.votingOpen,
  presentPlayerIds: ['a', 'b', 'c', 'd'],
);
final members = ['a', 'b', 'c', 'd']
    .map(
      (id) => UserModel(
        uid: id,
        firstName: 'Joueur',
        lastName: id.toUpperCase(),
        email: '',
        team: 'Seniors',
      ),
    )
    .toList();

class RecordingMatches extends Fake implements MatchesRepository {
  List<String>? ballot;
  bool? createdTest;
  List<String>? present;
  final calls = <String>[];
  @override
  Future<void> reopenVoting(String id) async {
    calls.add('reopen:$id');
  }

  @override
  Future<void> saveTestVote(
    String id, {
    required String voterUid,
    required String firstPlaceUid,
    required String secondPlaceUid,
    required String thirdPlaceUid,
  }) async {
    ballot = [id, voterUid, firstPlaceUid, secondPlaceUid, thirdPlaceUid];
  }

  @override
  Future<void> closeVoting(String id) async {
    calls.add('close:$id');
  }

  @override
  Future<void> recomputeResults(String id) async {
    calls.add('recompute:$id');
  }

  @override
  Future<void> createMatch({
    required DateTime date,
    required String time,
    required String opponent,
    required bool isHome,
    required String team,
    required List<String> presentPlayerIds,
    required PointsScale pointsScale,
    required bool allowSelfVote,
    String? opponentLogoAsset,
    String? opponentId,
    bool isTest = false,
  }) async {
    createdTest = isTest;
    present = presentPlayerIds;
  }
}

Future<void> choose(WidgetTester tester, String label, String name) async {
  final field = find.widgetWithText(DropdownButtonFormField<String>, label);
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'closed test uses server reopening and hides zero-point results',
    (tester) async {
      final repo = RecordingMatches();
      final closed = match.copyWith(status: MatchStatus.votingClosed);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isAdminProvider.overrideWithValue(true),
            matchesRepositoryProvider.overrideWithValue(repo),
            testMatchesListProvider.overrideWith(
              (ref) => Stream.value([closed]),
            ),
            membersListProvider.overrideWith(
              (ref, team) => Stream.value(members),
            ),
            testVotesProvider.overrideWith((ref, id) => Stream.value([])),
            matchResultProvider.overrideWith(
              (ref, id) => Stream.value({
                'totalVotes': 1,
                'entries': {
                  'a': {'points': 5},
                  'd': {'points': 0},
                },
              }),
            ),
          ],
          child: MaterialApp(home: TestMatchScreen(match: closed)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('5 pts'), 300);
      await tester.pumpAndSettle();
      expect(find.text('0 pts'), findsNothing);
      expect(find.text('5 pts'), findsOneWidget);
      final reopen = find.text('Rouvrir le vote de test');
      await tester.scrollUntilVisible(reopen, -300);
      await tester.ensureVisible(reopen);
      await tester.tap(reopen);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Les bulletins simulés seront conservés'),
        findsOneWidget,
      );
      await tester.tap(find.text('Rouvrir'));
      await tester.pumpAndSettle();
      expect(repo.calls, ['reopen:test:demo']);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [390.0, 1440.0]) {
    testWidgets('admin selects voter and top 3 then closes the test ($width)', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = RecordingMatches();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isAdminProvider.overrideWithValue(true),
            matchesRepositoryProvider.overrideWithValue(repo),
            testMatchesListProvider.overrideWith(
              (ref) => Stream.value([match]),
            ),
            membersListProvider.overrideWith(
              (ref, team) => Stream.value(members),
            ),
            testVotesProvider.overrideWith((ref, id) => Stream.value([])),
            matchResultProvider.overrideWith((ref, id) => Stream.value(null)),
          ],
          child: MaterialApp(home: TestMatchScreen(match: match)),
        ),
      );
      await tester.pumpAndSettle();
      final save = find.text('Enregistrer le bulletin de test');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(repo.ballot, isNull);
      await choose(tester, 'Joueur qui vote', 'Joueur D');
      await choose(tester, '1er choix', 'Joueur A');
      await choose(tester, '2e choix', 'Joueur B');
      await choose(tester, '3e choix', 'Joueur C');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(repo.ballot, ['test:demo', 'd', 'a', 'b', 'c']);
      final close = find.text('Clôturer et calculer les résultats');
      await tester.ensureVisible(close);
      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(repo.calls, ['close:test:demo', 'recompute:test:demo']);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('simulation is inaccessible to a member and for a real match', (
    tester,
  ) async {
    for (final admin in [false, true]) {
      await tester.pumpWidget(
        ProviderScope(
          key: ValueKey(admin),
          overrides: [isAdminProvider.overrideWithValue(admin)],
          child: MaterialApp(
            home: TestMatchScreen(
              match: admin ? match.copyWith(id: 'real') : match,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Réservé aux administrateurs.'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    }
  });

  testWidgets('creation switch saves a test with the selected players', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = RecordingMatches();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          matchesRepositoryProvider.overrideWithValue(repo),
          membersListProvider.overrideWith(
            (ref, team) => Stream.value(members),
          ),
          teamsListProvider.overrideWith(
            (ref) => Stream.value([const TeamModel(id: 's', name: 'Seniors')]),
          ),
          opponentsListProvider.overrideWith(
            (ref) =>
                Stream.value([const OpponentModel(id: 'r', name: 'Rennes')]),
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MatchFormScreen()),
                ),
                child: const Text('Nouveau'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Nouveau'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SwitchListTile, 'Match de test'));
    await tester.pumpAndSettle();
    await choose(tester, 'Adversaire', 'Rennes');
    await choose(tester, 'Équipe concernée', 'Seniors');
    for (final member in members) {
      final chip = find.widgetWithText(FilterChip, member.fullName);
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pumpAndSettle();
    }
    final save = find.text('Créer le match');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(repo.createdTest, isTrue);
    expect(repo.present, containsAll(['a', 'b', 'c', 'd']));
    expect(find.text('Nouveau'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
