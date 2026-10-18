import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chc_mvp/core/models/opponent_model.dart';

class OpponentsRepository {
  OpponentsRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('opponents');

  /// Stream de tous les adversaires triés par nom.
  Stream<List<OpponentModel>> watchOpponents() {
    return _col.orderBy('name').snapshots().map(
          (snap) => snap.docs
              .map(
                (d) => OpponentModel.fromJson({...d.data(), 'id': d.id}),
              )
              .toList(),
        );
  }

  /// Crée un nouvel adversaire et retourne son ID.
  Future<String> addOpponent({
    required String name,
    String? logoAsset,
  }) async {
    final doc = await _col.add({
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
    return _col.doc(id).update({
      'name': name,
      'logoAsset': logoAsset,
    });
  }

  /// Supprime un adversaire.
  Future<void> deleteOpponent(String id) => _col.doc(id).delete();
}
