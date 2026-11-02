import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chc_mvp/core/models/user_model.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'package:chc_mvp/features/ceremonies/ceremonies_providers.dart';
import 'package:chc_mvp/features/ceremonies/ceremonies_screen.dart';
import 'package:chc_mvp/features/ceremonies/ceremony_form.dart';
import 'package:chc_mvp/features/members/presentation/members_providers.dart';

const reviewer = UserModel(
  uid: 'review',
  firstName: 'Équipe',
  lastName: 'Validation',
  email: 'review@example.invalid',
  team: 'Équipe démo',
  role: UserRole.reviewer,
);

void main() {
  test('reviewer cannot select production or another review space', () async {
    final container = ProviderContainer(
      overrides: [
        accountProfileProvider.overrideWith((ref) => Stream.value(reviewer)),
        inspectedReviewSpaceProvider.overrideWith((ref) => 'other'),
      ],
    );
    addTearDown(container.dispose);
    await container.read(accountProfileProvider.future);
    expect(container.read(reviewSpaceUidProvider), 'review');
    container.read(inspectedReviewSpaceProvider.notifier).state = null;
    expect(container.read(reviewSpaceUidProvider), 'review');
  });

  test(
    'an in-flight server client retains its original space after admin navigation',
    () async {
      final container = ProviderContainer(
        overrides: [
          accountProfileProvider.overrideWith(
            (ref) => Stream.value(
              reviewer.copyWith(uid: 'admin', role: UserRole.admin),
            ),
          ),
          inspectedReviewSpaceProvider.overrideWith((ref) => 'review'),
        ],
      );
      addTearDown(container.dispose);
      await container.read(accountProfileProvider.future);
      final client = container.read(serverClientProvider);
      expect(client.reviewSpace!(), 'review');
      container.read(inspectedReviewSpaceProvider.notifier).state = null;
      expect(container.read(serverClientProvider).reviewSpace!(), isNull);
      expect(client.reviewSpace!(), 'review');
    },
  );

  test('normal members cannot select a review space', () async {
    final container = ProviderContainer(
      overrides: [
        accountProfileProvider.overrideWith(
          (ref) => Stream.value(reviewer.copyWith(role: UserRole.member)),
        ),
        inspectedReviewSpaceProvider.overrideWith((ref) => 'review'),
      ],
    );
    addTearDown(container.dispose);
    await container.read(accountProfileProvider.future);
    expect(container.read(reviewSpaceUidProvider), isNull);
  });

  testWidgets('reviewer can open the ordinary ceremony creation form', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(reviewer),
          ),
          ceremoniesProvider.overrideWith((ref) => Stream.value([])),
          membersListProvider.overrideWith(
            (ref, team) => Stream.value([
              reviewer,
              for (var i = 1; i <= 5; i++)
                reviewer.copyWith(
                  uid: 'demo$i',
                  firstName: 'Joueur $i',
                  role: UserRole.member,
                ),
            ]),
          ),
        ],
        child: const MaterialApp(home: CeremoniesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer une cérémonie'));
    await tester.pumpAndSettle();
    expect(find.byType(CeremonyForm), findsOneWidget);
    expect(find.text('Réservé aux admins.'), findsNothing);
    expect(find.byType(TextField), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
