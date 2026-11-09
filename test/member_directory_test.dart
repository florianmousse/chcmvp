import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chc_mvp/core/services/server_client.dart';
import 'package:chc_mvp/features/members/data/members_repository.dart';

class _Firestore extends Fake implements FirebaseFirestore {}

class _DirectoryServer extends Fake implements ServerClient {
  final paths = <String>[];
  bool fail = false;
  @override
  Future<Map<String, dynamic>> get(String path) async {
    paths.add(path);
    if (fail) throw const ServerException('Annuaire indisponible.');
    final second = path.contains('cursor=');
    return {
      'members': [
        {
          'uid': second ? 'b' : 'a',
          'firstName': 'Camille',
          'lastName': second ? 'Alpha' : 'Zulu',
          'team': second ? 'B' : 'A',
          'email': '',
          'isActive': true,
          'role': 'member',
        },
      ],
      'nextCursor': second ? null : 'page-one',
    };
  }
}

void main() {
  test(
    'directory loads every page and filters without exposing contacts',
    () async {
      final server = _DirectoryServer();
      final repository = MembersRepository(
        _Firestore(),
        server,
        reviewSpaceUid: 'review',
      );
      final members = await repository.watchMembers().first;
      expect(members.map((m) => m.uid), ['b', 'a']);
      expect(members.every((m) => m.email.isEmpty), isTrue);
      expect(server.paths, [
        '/members/directory',
        '/members/directory?cursor=page-one',
      ]);
      final team = await repository.watchMembers(team: 'A').first;
      expect(team.map((m) => m.uid), ['a']);
    },
  );
  test('directory failure is surfaced instead of an empty list', () async {
    final server = _DirectoryServer()..fail = true;
    final repository = MembersRepository(_Firestore(), server);
    await expectLater(
      repository.watchMembers().first,
      throwsA(isA<ServerException>()),
    );
  });
}
