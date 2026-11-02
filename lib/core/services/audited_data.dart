import 'package:cloud_firestore/cloud_firestore.dart';
import 'server_client.dart';

/// Server-authorized writes with an atomic audit entry.
Future<void> writeAuditedData(
  ServerClient server,
  String path,
  String operation, [
  Map<String, dynamic> data = const {},
]) async {
  Object? encode(Object? value) {
    if (value is Timestamp) return value.toDate().toUtc().toIso8601String();
    if (value is DateTime) return value.toUtc().toIso8601String();
    if (value is Map) return value.map((k, v) => MapEntry(k, encode(v)));
    if (value is List) return value.map(encode).toList();
    return value;
  }

  await server.post('/data', {
    'path': path.startsWith('review_spaces/')
        ? path.split('/').skip(2).join('/')
        : path,
    'operation': operation,
    'data': encode(data),
  });
}
