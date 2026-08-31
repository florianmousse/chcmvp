import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:chc_mvp/core/config/server_config.dart';

/// Remplace les appels `cloud_functions` httpsCallable : chaque méthode fait
/// une requête HTTP normale vers le serveur du VPS, avec le token Firebase
/// de l'admin connecté en en-tête (vérifié côté serveur par requireAuth +
/// requireAdmin, voir server/src/middleware/auth.ts).
class ServerClient {
  Future<Map<String, String>> _authHeaders() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$serverBaseUrl$path'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    return _handle(response);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final response = await http.delete(
      Uri.parse('$serverBaseUrl$path'),
      headers: await _authHeaders(),
    );
    return _handle(response);
  }

  Map<String, dynamic> _handle(http.Response response) {
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw ServerException(
        decoded['error'] as String? ??
            'Erreur serveur (${response.statusCode})',
      );
    }
    return decoded;
  }
}

class ServerException implements Exception {
  ServerException(this.message);
  final String message;
  @override
  String toString() => message;
}
