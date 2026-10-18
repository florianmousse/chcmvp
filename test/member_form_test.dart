import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chc_mvp/core/models/team_model.dart';
import 'package:chc_mvp/core/models/user_model.dart';
import 'package:chc_mvp/features/members/data/members_repository.dart';
import 'package:chc_mvp/features/members/presentation/member_form_screen.dart';
import 'package:chc_mvp/features/members/presentation/members_providers.dart';
import 'package:chc_mvp/features/teams/presentation/teams_providers.dart';

class RecordingMembers extends Fake implements MembersRepository {
  Map<String, dynamic>? created;
  String? invitedUid;
  Map<String, dynamic>? invited;
  @override
  Future<void> inviteMember({
    required String email,
    required String firstName,
    required String lastName,
    required String team,
    int? jerseyNumber,
  }) async {
    created = {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'team': team,
    };
  }

  @override
  Future<void> inviteExistingMember(
    String uid,
    Map<String, dynamic> fields,
  ) async {
    invitedUid = uid;
    invited = fields;
  }
}

void main() {
  testWidgets('Ajouter un joueur sans e-mail depuis le formulaire', (
    tester,
  ) async {
    final repo = RecordingMembers();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          membersRepositoryProvider.overrideWithValue(repo),
          teamsListProvider.overrideWith(
            (ref) =>
                Stream.value([const TeamModel(id: 'seniors', name: 'Seniors')]),
          ),
        ],
        child: const MaterialApp(home: MemberFormScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Prénom'),
      'Alex',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Nom'), 'Martin');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seniors').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ajouter le joueur'));
    await tester.tap(find.text('Ajouter le joueur'));
    await tester.pumpAndSettle();
    expect(repo.created, {
      'email': '',
      'firstName': 'Alex',
      'lastName': 'Martin',
      'team': 'Seniors',
    });
  });
  testWidgets('Inviter un joueur existant conserve son identifiant', (
    tester,
  ) async {
    final repo = RecordingMembers();
    const player = UserModel(
      uid: 'guest-42',
      firstName: 'Alex',
      lastName: 'Martin',
      email: '',
      team: 'Seniors',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          membersRepositoryProvider.overrideWithValue(repo),
          teamsListProvider.overrideWith(
            (ref) =>
                Stream.value([const TeamModel(id: 'seniors', name: 'Seniors')]),
          ),
        ],
        child: const MaterialApp(home: MemberFormScreen(existing: player)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'E-mail (facultatif)'),
      'alex@example.test',
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Enregistrer et inviter'));
    await tester.tap(find.text('Enregistrer et inviter'));
    await tester.pumpAndSettle();
    expect(repo.invitedUid, 'guest-42');
    expect(repo.invited?['email'], 'alex@example.test');
    expect(repo.created, isNull);
  });
}
