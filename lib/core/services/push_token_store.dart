import 'package:cloud_firestore/cloud_firestore.dart';

List<String> updatedPushTokens(
  Object? existing,
  String token, {
  required bool remove,
}) {
  final tokens = <String>{
    if (existing is List)
      for (final value in existing)
        if (value is String &&
            value.isNotEmpty &&
            value.length <= 4096 &&
            !RegExp(r'\s').hasMatch(value) &&
            value != token)
          value,
  }.toList();
  if (!remove) {
    if (token.isEmpty || token.length > 4096 || RegExp(r'\s').hasMatch(token)) {
      throw ArgumentError('Jeton de notification invalide.');
    }
    tokens.add(token);
  }
  return tokens.skip(tokens.length > 10 ? tokens.length - 10 : 0).toList();
}

/// Atomically retain the ten most recently registered devices and repair legacy data.
Future<void> storePushToken(
  FirebaseFirestore firestore,
  String uid,
  String token, {
  bool remove = false,
}) => firestore.runTransaction((transaction) async {
  final reference = firestore.collection('users').doc(uid);
  final profile = await transaction.get(reference);
  if (!profile.exists) throw StateError('Profil introuvable.');
  transaction.update(reference, {
    'fcmTokens': updatedPushTokens(
      profile.data()?['fcmTokens'],
      token,
      remove: remove,
    ),
  });
});
