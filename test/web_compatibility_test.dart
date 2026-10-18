import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chc_mvp/core/theme/app_theme.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'package:chc_mvp/features/auth/presentation/login_screen.dart';
import 'package:chc_mvp/features/voting/presentation/voting_controller.dart';

class TestUser extends Fake implements User {
  @override
  String get uid => 'voter';
}

class TestAuth extends Fake implements FirebaseAuth {
  @override
  User get currentUser => TestUser();
}

class VoteDocument extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  VoteDocument(this.reject);
  final bool reject;
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      VoteCollection(reject);
  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    if (reject)
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
  }
}

class VoteCollection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  VoteCollection(this.reject);
  final bool reject;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      VoteDocument(reject);
}

class TestFirestore extends Fake implements FirebaseFirestore {
  TestFirestore(this.reject);
  final bool reject;
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      VoteCollection(reject);
}

void main() {
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

  for (final reject in [false, true]) {
    test(
      'Un vote ${reject ? "refusé est propagé à l'écran" : 'accepté se termine sans erreur'}',
      () async {
        final container = ProviderContainer(
          overrides: [
            firebaseAuthProvider.overrideWithValue(TestAuth()),
            firestoreProvider.overrideWithValue(TestFirestore(reject)),
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
