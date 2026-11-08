import 'dart:async';
import 'package:chc_mvp/core/models/match_model.dart';
import 'package:chc_mvp/core/models/team_model.dart';
import 'package:chc_mvp/features/matches/domain/championship_numbering.dart';
import 'package:chc_mvp/features/matches/presentation/match_form_screen.dart';
import 'package:chc_mvp/features/matches/presentation/matches_providers.dart';
import 'package:chc_mvp/features/members/presentation/members_providers.dart';
import 'package:chc_mvp/features/opponents/presentation/opponents_providers.dart';
import 'package:chc_mvp/features/teams/presentation/teams_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

MatchModel fixture(DateTime date, {int? day, int? number}) => MatchModel(
  id: 'fixture',
  date: date,
  time: '09:00',
  opponent: 'Rennes',
  isHome: true,
  team: 'Seniors',
  matchDay: day,
  matchNumber: number,
);

void main() {
  final date = DateTime(2026, 11, 8);
  ({int day, int match}) suggest(List<MatchModel> matches) =>
      suggestChampionshipNumbers(matches: matches, team: 'Seniors', date: date);

  test('first fixture, next date and multiple matches on the same date', () {
    expect(suggest([]), (day: 1, match: 1));
    expect(suggest([fixture(DateTime(2026, 11, 1), day: 3, number: 2)]), (
      day: 4,
      match: 3,
    ));
    expect(suggest([fixture(date, day: 4, number: 1)]), (day: 4, match: 2));
    expect(
      suggest([
        fixture(date, day: 4, number: 1),
        fixture(date, day: 4, number: 2),
      ]),
      (day: 4, match: 3),
    );
    expect(suggest([fixture(date, day: 4, number: 5)]), (day: 4, match: 6));
  });

  test('J1 M1 and J1 M2 are followed by J2 M3 then J2 M4', () {
    final firstDay = DateTime(2026, 11, 1);
    final matches = [
      fixture(firstDay, day: 1, number: 1),
      fixture(firstDay, day: 1, number: 2),
    ];
    expect(suggest(matches), (day: 2, match: 3));
    matches.add(fixture(date, day: 2, number: 3));
    expect(suggest(matches), (day: 2, match: 4));
  });

  test(
    'uses calendar dates and infers legacy fixtures without changing them',
    () {
      final old = fixture(DateTime(2026, 11, 1));
      expect(suggest([old, fixture(DateTime(2026, 11, 8, 15))]), (
        day: 2,
        match: 3,
      ));
      expect(old.matchDay, isNull);
    },
  );

  test(
    'isolates teams, seasons, tests and competitions and ignores later dates',
    () {
      final existing = fixture(date, day: 8, number: 9);
      expect(
        suggest([
          existing.copyWith(team: 'Juniors'),
          existing.copyWith(date: DateTime(2026, 8, 1)),
          existing.copyWith(date: DateTime(2026, 11, 15)),
          existing.copyWith(id: 'test:fixture'),
          existing.copyWith(matchType: MatchType.friendly),
          existing.copyWith(matchType: MatchType.tournament),
          existing.copyWith(matchType: MatchType.playoff),
        ]),
        (day: 1, match: 1),
      );
      expect(
        suggestChampionshipNumbers(
          matches: [
            existing,
            existing.copyWith(id: 'test:fixture'),
          ],
          team: 'Seniors',
          date: date,
          isTest: true,
        ),
        (day: 8, match: 10),
      );
    },
  );

  testWidgets(
    'prefills from loaded fixtures and preserves manual corrections',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final stream = StreamController<List<MatchModel>>();
      addTearDown(stream.close);
      final now = DateTime.now();
      final days = (DateTime.sunday - now.weekday) % 7;
      final nextSunday = now.add(Duration(days: days == 0 ? 7 : days));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchesListProvider.overrideWith((ref, team) => stream.stream),
            membersListProvider.overrideWith((ref, team) => Stream.value([])),
            teamsListProvider.overrideWith(
              (ref) =>
                  Stream.value([const TeamModel(id: 's', name: 'Seniors')]),
            ),
            opponentsListProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(home: MatchFormScreen()),
        ),
      );
      await tester.pumpAndSettle();
      final team = find.widgetWithText(
        DropdownButtonFormField<String>,
        'Équipe concernée',
      );
      await tester.ensureVisible(team);
      await tester.tap(team);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Seniors').last);
      await tester.pumpAndSettle();
      stream.add([fixture(nextSunday, day: 3, number: 1)]);
      await tester.pumpAndSettle();
      final day = find.widgetWithText(TextFormField, 'Journée');
      await tester.ensureVisible(day);
      await tester.pumpAndSettle();
      final number = find.widgetWithText(TextFormField, 'Match dans la saison');
      expect(tester.widget<TextFormField>(day).controller!.text, '3');
      expect(tester.widget<TextFormField>(number).controller!.text, '2');
      await tester.enterText(day, '7');
      await tester.enterText(number, '4');
      stream.add([fixture(nextSunday, day: 8, number: 9)]);
      await tester.pumpAndSettle();
      expect(tester.widget<TextFormField>(day).controller!.text, '7');
      expect(tester.widget<TextFormField>(number).controller!.text, '4');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
