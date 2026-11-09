import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chc_mvp/core/theme/app_theme.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'package:chc_mvp/features/auth/presentation/login_screen.dart';
import 'package:chc_mvp/features/voting/presentation/voting_controller.dart';
import 'package:chc_mvp/features/voting/presentation/vote_screen.dart';
import 'package:chc_mvp/core/models/user_model.dart';
import 'package:chc_mvp/core/models/match_model.dart';

class TestUser extends Fake implements User {
  @override
  String get uid => 'voter';
}

class TestAuth extends Fake implements FirebaseAuth {
  @override
  User get currentUser => TestUser();
}

void main() {
  testWidgets(
    'Leaving a pending vote does not use the disposed screen on failure',
    (tester) async {
      final pending = Completer<void>();
      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(TestAuth()),
          reviewSpaceUidProvider.overrideWithValue(null),
          voteWriterProvider.overrideWithValue((_, __) => pending.future),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: VoteScreen(
              match: MatchModel(
                id: 'match',
                date: DateTime(2026, 11, 9),
                time: '15:00',
                opponent: 'Demo',
                isHome: true,
                team: 'Demo',
              ),
              candidates: [
                for (final uid in ['a', 'b', 'c'])
                  UserModel(
                    uid: uid,
                    firstName: uid,
                    lastName: 'Demo',
                    email: '',
                    team: 'Demo',
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      for (var i = 0; i < 3; i++) {
        tester
            .widget<DropdownButtonFormField<String>>(
              find.byType(DropdownButtonFormField<String>).at(i),
            )
            .onChanged!(['a', 'b', 'c'][i]);
        await tester.pump();
      }
      await tester.tap(find.text('Valider mon vote'));
      await tester.pump();
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();
      pending.completeError(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
      await tester.pump();
      // Let Riverpod's zero-delay disposal scheduler release the completed vote.
      await tester.pump(const Duration(milliseconds: 1));
      expect(tester.takeException(), isNull);
    },
  );
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('Connexion sans débordement à ${width}px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(theme: AppTheme.light, home: const LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Se connecter'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final namespace in [null, 'voter']) {
    for (final reject in [false, true]) {
      test(
        'Espace $namespace : un vote ${reject ? "refusé est propagé à l'écran" : 'accepté se termine sans erreur'}',
        () async {
          String? writtenPath;
          final container = ProviderContainer(
            overrides: [
              firebaseAuthProvider.overrideWithValue(TestAuth()),
              voteWriterProvider.overrideWithValue((path, data) async {
                writtenPath = path;
                if (reject) {
                  throw FirebaseException(
                    plugin: 'cloud_firestore',
                    code: 'permission-denied',
                  );
                }
              }),
              reviewSpaceUidProvider.overrideWithValue(namespace),
            ],
          );
          addTearDown(container.dispose);
          final subscription = container.listen(
            voteSubmissionControllerProvider,
            (_, __) {},
          );
          addTearDown(subscription.close);
          await container.read(voteSubmissionControllerProvider.future);
          final submission = container
              .read(voteSubmissionControllerProvider.notifier)
              .submit(
                matchId: 'match',
                firstPlaceUid: 'a',
                secondPlaceUid: 'b',
                thirdPlaceUid: 'c',
              );
          expect(
            writtenPath,
            namespace == null
                ? 'matches/match/votes/voter'
                : 'review_spaces/voter/matches/match/votes/voter',
          );
          if (reject) {
            await expectLater(submission, throwsA(isA<FirebaseException>()));
            expect(
              container.read(voteSubmissionControllerProvider).hasError,
              isTrue,
            );
          } else {
            await submission;
            expect(
              container.read(voteSubmissionControllerProvider).hasError,
              isFalse,
            );
          }
        },
      );
    }
  }
}
