import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:chc_mvp/core/config/server_config.dart';

/// One bounded request, including authentication. Writes are never retried.
class ServerClient {
  ServerClient({
    this.reviewSpace,
    this.baseUrl = serverBaseUrl,
    this.timeout = const Duration(seconds: 20),
    http.Client Function()? clientFactory,
    Future<String?> Function()? tokenProvider,
  }) : _clientFactory = clientFactory ?? http.Client.new,
       _tokenProvider =
           tokenProvider ??
           (() async => FirebaseAuth.instance.currentUser?.getIdToken());

  final String? Function()? reviewSpace;
  final String baseUrl;
  final Duration timeout;
  final http.Client Function() _clientFactory;
  final Future<String?> Function() _tokenProvider;

  Future<Map<String, dynamic>> get(String path) => _request('GET', path);
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) =>
      _request('POST', path, body);
  Future<Map<String, dynamic>> delete(String path) => _request('DELETE', path);

  Future<Map<String, dynamic>> _request(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final base = configuredServerUri(baseUrl);
    if (!path.startsWith('/') || path.startsWith('//')) {
      throw ArgumentError('Chemin serveur invalide.');
    }
    final uri = base.resolve(path);
    if (uri.origin != base.origin) {
      throw ArgumentError('Origine serveur invalide.');
    }
    final client = _clientFactory();
    var ended = false;
    Future<Map<String, dynamic>> execute() async {
      final token = await _tokenProvider();
      // A token refresh completing after timeout must never start a late write.
      if (ended) throw const ServerException('Requête expirée.');
      final scope = reviewSpace?.call();
      final request = http.Request(method, uri)
        ..headers.addAll({
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          if (token != null && scope != null) 'X-Review-Space': scope,
        });
      if (body != null) request.body = jsonEncode(body);
      return _handle(
        await http.Response.fromStream(await client.send(request)),
      );
    }

    try {
      return await execute().timeout(timeout);
    } on TimeoutException {
      throw const ServerException(
        'Le serveur ne répond pas. Vérifiez le résultat avant de réessayer cette action.',
      );
    } on http.ClientException {
      throw const ServerException(
        'Connexion au serveur interrompue. Vérifiez le résultat avant de réessayer.',
      );
    } finally {
      ended = true;
      client.close();
    }
  }

  Map<String, dynamic> _handle(http.Response response) {
    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const ServerException(
        'Réponse du serveur invalide. Réessayez plus tard.',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const ServerException('Réponse du serveur invalide.');
    }
    if (response.statusCode >= 400) {
      throw ServerException(
        decoded['error'] is String
            ? decoded['error'] as String
            : 'Erreur serveur (${response.statusCode})',
      );
    }
    return decoded;
  }
}

class ServerException implements Exception {
  const ServerException(this.message);
  final String message;
  @override
  String toString() => message;
}
