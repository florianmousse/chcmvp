import 'package:cloud_firestore/cloud_firestore.dart';

/// À appeler sur tout Map<String, dynamic> issu de `doc.data()` avant de le
/// passer à un `fromJson` généré par freezed/json_serializable. Les champs
/// Firestore de type Timestamp doivent être convertis en String ISO8601 —
/// TimestampConverter (core/models) sait lire les deux formats, mais le code
/// généré par json_serializable pour un champ DateTime *non-nullable* insère
/// parfois un cast implicite qui échoue si la valeur brute est un Timestamp
/// plutôt qu'un String. Convertir ici, une fois pour toutes, évite le souci
/// quel que soit le champ concerné.
Map<String, dynamic> sanitizeFirestoreJson(Map<String, dynamic> data) {
  return data.map((key, value) {
    if (value is Timestamp) {
      return MapEntry(key, value.toDate().toIso8601String());
    }
    if (value is Map<String, dynamic>) {
      return MapEntry(key, sanitizeFirestoreJson(value));
    }
    return MapEntry(key, value);
  });
}
