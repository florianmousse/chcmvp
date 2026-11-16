import 'package:chc_mvp/core/models/match_model.dart';
import 'package:chc_mvp/core/models/user_model.dart';
import 'package:chc_mvp/features/voting/presentation/vote_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [390.0, 1280.0]) {
    testWidgets('Retirer et replacer un joueur du top 3 ($width)', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 950);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: VoteScreen(
              match: MatchModel(
                id: 'synthetic',
                date: DateTime(2026, 10, 10),
                time: '19:50',
                opponent: 'Club test',
                isHome: true,
                team: 'Seniors',
                allowSelfVote: true,
              ),
              candidates: [
                for (var i = 1; i <= 3; i++)
                  UserModel(
                    uid: 'p$i',
                    firstName: 'Joueur',
                    lastName: '$i',
                    email: 'p$i@example.test',
                    team: 'Seniors',
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final fields = find.byType(DropdownButtonFormField<String>);
      Future<void> select(int rank, String name) async {
        await tester.tap(fields.at(rank));
        await tester.pumpAndSettle();
        await tester.tap(find.text(name).last);
        await tester.pumpAndSettle();
      }

      await select(0, 'Joueur 1');
      await select(1, 'Joueur 2');
      await select(2, 'Joueur 3');
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      for (var rank = 0; rank < 3; rank++) {
        await tester.tap(
          find.descendant(
            of: fields.at(rank),
            matching: find.byType(IconButton),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.state<FormFieldState<String>>(fields.at(rank)).value,
          isNull,
        );
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
      }
      await select(0, 'Joueur 3');
      await select(1, 'Joueur 1');
      await select(2, 'Joueur 2');
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
