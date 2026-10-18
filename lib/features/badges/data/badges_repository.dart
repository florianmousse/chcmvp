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

  /// Synchronise les badges calculés avec Firestore.
  /// N'écrase jamais les dates d'obtention existantes - ne fait qu'ajouter
  /// les nouveaux badges avec la date courante.
  /// Retourne la liste des badges nouvellement ajoutés.
  Future<List<String>> syncBadges({
    required String userId,
    required List<String> computedBadgeTypes,
  }) async {
    final existing = await getBadges(userId);
    final newBadges = <String>[];
    final updates = <String, Timestamp>{};

    for (final type in computedBadgeTypes) {
      if (!existing.containsKey(type)) {
        updates[type] = Timestamp.now();
        newBadges.add(type);
      }
    }

    if (updates.isNotEmpty) {
      await _doc(userId).set({
        'earned': {
          // Préserver les badges existants
          for (final entry in existing.entries)
            entry.key: Timestamp.fromDate(entry.value),
          // Ajouter les nouveaux
          ...updates,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return newBadges;
  }
}
