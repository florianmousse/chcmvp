import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chc_mvp/core/services/server_client.dart';
import 'package:chc_mvp/core/services/audited_data.dart';
import 'package:chc_mvp/core/models/team_model.dart';

class TeamsRepository {
  TeamsRepository(this._firestore, [ServerClient? server])
    : _server = server ?? ServerClient();
  final ServerClient _server;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _teams =>
      _firestore.collection('teams');

  Stream<List<TeamModel>> watchTeams() {
    return _teams
        .orderBy('name')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => TeamModel.fromJson({...d.data(), 'id': d.id}))
              .toList(),
        );
  }

  Future<void> createTeam(String name) =>
      writeAuditedData(_server, _teams.doc().path, 'create', {'name': name});

  Future<void> renameTeam(String id, String name) =>
      writeAuditedData(_server, _teams.doc(id).path, 'update', {'name': name});

  /// Ne supprime que l'équipe elle-même - les membres et matchs qui la
  /// référencent encore gardent l'ancien nom en texte jusqu'à modification
  /// manuelle (pas de suppression en cascade, pour éviter de casser
  /// l'historique des matchs déjà joués).
  Future<void> deleteTeam(String id) =>
      writeAuditedData(_server, _teams.doc(id).path, 'delete');
}
