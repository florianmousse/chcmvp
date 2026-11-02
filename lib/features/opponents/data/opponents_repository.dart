import 'package:chc_mvp/core/services/scoped_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chc_mvp/core/services/server_client.dart';
import 'package:chc_mvp/core/services/audited_data.dart';
import 'package:chc_mvp/core/models/opponent_model.dart';

class OpponentsRepository {
  OpponentsRepository(
    FirebaseFirestore firestore, [
    ServerClient? server,
    String? reviewSpaceUid,
  ]) : _firestore = ScopedFirestore(firestore, reviewSpaceUid),
       _server = server ?? ServerClient();
  final ServerClient _server;
  final ScopedFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('opponents');

  /// Stream de tous les adversaires triés par nom.
  Stream<List<OpponentModel>> watchOpponents() {
    return _col
        .orderBy('name')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => OpponentModel.fromJson({...d.data(), 'id': d.id}))
              .toList(),
        );
  }

  /// Crée un nouvel adversaire et retourne son ID.
  Future<String> addOpponent({required String name, String? logoAsset}) async {
    final doc = _col.doc();
    await writeAuditedData(_server, doc.path, 'create', {
      'name': name,
      if (logoAsset != null) 'logoAsset': logoAsset,
    });
    return doc.id;
  }

  /// Met à jour un adversaire existant.
  Future<void> updateOpponent({
    required String id,
    required String name,
    String? logoAsset,
  }) {
    return writeAuditedData(_server, _col.doc(id).path, 'update', {
      'name': name,
      'logoAsset': logoAsset,
    });
  }

  /// Supprime un adversaire.
  Future<void> deleteOpponent(String id) =>
      writeAuditedData(_server, _col.doc(id).path, 'delete');
}
