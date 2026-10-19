import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chc_mvp/core/config/team_logos_catalog.dart';
import 'package:chc_mvp/core/models/opponent_model.dart';
import 'package:chc_mvp/features/matches/presentation/match_form_screen.dart';
import 'package:chc_mvp/features/members/presentation/members_providers.dart';
import 'package:chc_mvp/features/opponents/data/opponents_repository.dart';
import 'package:chc_mvp/features/opponents/presentation/opponents_providers.dart';
import 'package:chc_mvp/features/teams/presentation/teams_providers.dart';

class RecordingOpponents extends Fake implements OpponentsRepository {
  int calls = 0;
  String? name;
  String? logo;
  final result = Completer<String>();
  @override
  Future<String> addOpponent({required String name, String? logoAsset}) {
    calls++;
    this.name = name;
    logo = logoAsset;
    return result.future;
  }
}

Future<void> openForm(WidgetTester tester, RecordingOpponents repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        opponentsRepositoryProvider.overrideWithValue(repo),
        opponentsListProvider.overrideWith(
          (ref) => Stream.value([
            const OpponentModel(id: 'old', name: 'Ancien adversaire'),
          ]),
        ),
        teamsListProvider.overrideWith((ref) => Stream.value([])),
        membersListProvider.overrideWith((ref, team) => Stream.value([])),
      ],
      child: const MaterialApp(home: MatchFormScreen()),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Ajouter un adversaire'));
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'plus opens and selects new opponent before the stream updates ($width)',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final repo = RecordingOpponents();
        await openForm(tester, repo);
        expect(tester.takeException(), isNull);
        expect(find.text('Nouvel adversaire'), findsOneWidget);
        await tester.tap(find.text('Ajouter'));
        await tester.pumpAndSettle();
        expect(find.text('Champ requis'), findsOneWidget);
        expect(repo.calls, 0);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nom'),
          '  Nouveau club  ',
        );
        final logo = teamLogosCatalog.firstWhere((l) => l.name != 'CHC');
        await tester.tap(find.byTooltip(logo.name));
        await tester.tap(find.text('Ajouter'));
        await tester.pump();
        expect(repo.calls, 1);
        expect(repo.logo, logo.assetPath);
        expect(repo.name, 'Nouveau club');
        expect(
          tester
              .widget<FilledButton>(find.widgetWithText(FilledButton, 'Ajout…'))
              .onPressed,
          isNull,
        );
        repo.result.complete('new');
        await tester.pumpAndSettle();
        expect(find.text('Nouvel adversaire'), findsNothing);
        final field = tester.widget<DropdownButtonFormField<String>>(
          find.byType(DropdownButtonFormField<String>).first,
        );
        expect(field.initialValue, 'new');
        expect(find.text('Nouveau club'), findsWidgets);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets(
    'creation error stays in dialog and cancel safely disposes inputs',
    (tester) async {
      final repo = RecordingOpponents();
      await openForm(tester, repo);
      await tester.enterText(find.widgetWithText(TextFormField, 'Nom'), 'Club');
      await tester.tap(find.text('Ajouter'));
      await tester.pump();
      repo.result.completeError(StateError('permission refusée'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Ajout impossible'), findsOneWidget);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(find.text('Nouvel adversaire'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
