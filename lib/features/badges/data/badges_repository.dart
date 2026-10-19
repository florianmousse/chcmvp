import 'package:cloud_firestore/cloud_firestore.dart';

/// Repository pour les badges stockés dans Firestore.
/// Collection : `userBadges/{userId}` - un document par utilisateur.
class BadgesRepository {
  BadgesRepository(this._firestore);
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String userId) =>
      _firestore.collection('userBadges').doc(userId);

  /// Stream des badges gagnés par un utilisateur.
  /// Retourne un `Map<String, DateTime>` - clé = BadgeType.name, valeur = date d'obtention.
  Stream<Map<String, DateTime>> watchBadges(String userId) {
    return _doc(userId).snapshots().map((snap) {
      final data = snap.data();
      if (data == null || data['earned'] == null) return {};
      final earned = data['earned'] as Map<String, dynamic>;
      return earned.map(
        (key, value) => MapEntry(key, (value as Timestamp).toDate()),
      );
    });
  }

  /// Lecture ponctuelle des badges gagnés.
  Future<Map<String, DateTime>> getBadges(String userId) async {
    final snap = await _doc(userId).get();
    final data = snap.data();
    if (data == null || data['earned'] == null) return {};
    final earned = data['earned'] as Map<String, dynamic>;
    return earned.map(
      (key, value) => MapEntry(key, (value as Timestamp).toDate()),
    );
  }
}
