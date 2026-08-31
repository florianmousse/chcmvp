import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chc_mvp/core/models/user_model.dart';
import 'package:chc_mvp/core/services/server_client.dart';
import 'package:chc_mvp/core/utils/firestore_json.dart';

/// Les lectures et la mise à jour de son propre profil passent par Firestore
/// direct (autorisé par les règles). Les opérations sensibles (créer un
/// compte, désactiver, changer de rôle, supprimer) passent par le serveur du
/// VPS (server/src/routes/members.ts) — impossible à faire depuis le client
/// avec le SDK Auth seul sans déconnecter l'admin.
class MembersRepository {
  MembersRepository(this._firestore, this._server);

  final FirebaseFirestore _firestore;
  final ServerClient _server;

  Stream<List<UserModel>> watchMembers({String? team}) {
    Query<Map<String, dynamic>> query = _firestore.collection('users');
    if (team != null) query = query.where('team', isEqualTo: team);
    return query
        .orderBy('lastName')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) => UserModel.fromJson(
                  sanitizeFirestoreJson({...d.data(), 'uid': d.id}),
                ),
              )
              .toList(),
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

  /// Modification des champs non sensibles (nom, équipe, numéro, photo) —
  /// autorisée directement par les règles Firestore pour un admin.
  Future<void> updateProfile(String uid, Map<String, dynamic> fields) {
    return _firestore.collection('users').doc(uid).update(fields);
  }

  Future<void> setActive(String uid, bool isActive) {
    return _server.post('/members/$uid/active', {'isActive': isActive});
  }

  Future<void> setRole(String uid, UserRole role) {
    return _server.post('/members/$uid/role', {'role': role.name});
  }

  Future<void> deleteMember(String uid) {
    return _server.delete('/members/$uid');
  }
}
