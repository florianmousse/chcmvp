import 'dart:async';
import 'package:chc_mvp/core/services/paged_firestore.dart';
import 'package:chc_mvp/core/services/scoped_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chc_mvp/core/services/audited_data.dart';
import 'package:chc_mvp/core/models/user_model.dart';
import 'package:chc_mvp/core/services/server_client.dart';
import 'package:chc_mvp/core/utils/firestore_json.dart';

/// L'annuaire passe par une projection serveur ; les admins lisent les fiches complètes.
/// Toutes les modifications du profil
/// passent par le serveur et son journal. Les opérations sensibles (créer un
/// compte, désactiver, changer de rôle, supprimer) passent par le serveur du
/// VPS (server/src/routes/members.ts) - impossible à faire depuis le client
/// avec le SDK Auth seul sans déconnecter l'admin.
class MembersRepository {
  MembersRepository(
    FirebaseFirestore firestore,
    this._server, {
    String? reviewSpaceUid,
  }) : _firestore = ScopedFirestore(firestore, reviewSpaceUid);

  final ScopedFirestore _firestore;
  final ServerClient _server;

  Stream<List<UserModel>> watchMembers({String? team}) {
    late StreamController<List<UserModel>> controller;
    Timer? timer;
    var disposed = false, busy = false;
    Future<void> refresh() async {
      if (disposed || busy) return;
      busy = true;
      try {
        final members = <UserModel>[];
        String? cursor;
        do {
          final page = await _server.get(
            '/members/directory${cursor == null ? '' : '?cursor=${Uri.encodeQueryComponent(cursor)}'}',
          );
          if (disposed) return;
          for (final value in page['members'] as List) {
            final member = UserModel.fromJson(
              Map<String, dynamic>.from(value as Map),
            );
            if (team == null || member.team == team) members.add(member);
          }
          cursor = page['nextCursor'] as String?;
        } while (cursor != null);
        members.sort((a, b) => a.lastName.compareTo(b.lastName));
        controller.add(members);
      } catch (error, stack) {
        if (!disposed) controller.addError(error, stack);
      } finally {
        busy = false;
      }
    }

    controller = StreamController<List<UserModel>>(
      onListen: () {
        unawaited(refresh());
        timer = Timer.periodic(const Duration(minutes: 1), (_) => refresh());
      },
      onCancel: () {
        disposed = true;
        timer?.cancel();
      },
    );
    return controller.stream;
  }

  /// Management list also includes isolated review accounts.
  Stream<List<UserModel>> watchAllMembers({String? team}) {
    Query<Map<String, dynamic>> query = _firestore.collection('users');
    if (team != null) query = query.where('team', isEqualTo: team);
    return watchPagedQuery(query).map(
      (snap) =>
          snap
              .map(
                (d) => UserModel.fromJson(
                  sanitizeFirestoreJson({...d.data(), 'uid': d.id}),
                ),
              )
              .toList()
            ..sort((a, b) => a.lastName.compareTo(b.lastName)),
    );
  }

  Future<void> inviteMember({
    required String email,
    required String firstName,
    required String lastName,
    required String team,
    int? jerseyNumber,
  }) {
    return _server.post('/members/invite', {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'team': team,
      'jerseyNumber': jerseyNumber,
    });
  }

  /// Modification des champs non sensibles (nom, équipe, numéro, photo) -
  /// autorisée et journalisée par le serveur.
  Future<void> updateProfile(String uid, Map<String, dynamic> fields) {
    return writeAuditedData(_server, 'users/$uid', 'update', fields);
  }

  Future<void> changeEmail(String uid, Map<String, dynamic> fields) =>
      _server.post('/members/$uid/email', fields);

  Future<void> setActive(String uid, bool isActive) {
    return _server.post('/members/$uid/active', {'isActive': isActive});
  }

  Future<void> inviteExistingMember(String uid, Map<String, dynamic> fields) {
    return _server.post('/members/$uid/invite', fields);
  }

  Future<void> setRole(String uid, UserRole role) {
    return _server.post('/members/$uid/role', {'role': role.name});
  }

  Future<void> deleteMember(String uid) {
    return _server.delete('/members/$uid');
  }
}
