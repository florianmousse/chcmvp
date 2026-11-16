import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

import 'web_app_version.dart';

Future<String?> availableWebVersion() async {
  // The running version must be compiled into the bundle, not read from the
  // server at startup: that file may already describe a newer deployment.
  const runningVersion = String.fromEnvironment('APP_BUILD_VERSION');
  if (runningVersion.isEmpty) {
    throw StateError('APP_BUILD_VERSION manquant dans le build web');
  }
  final uri = Uri.base
      .resolve('version.json')
      .replace(
        queryParameters: {'check': '${DateTime.now().millisecondsSinceEpoch}'},
      );
  final client = http.Client();
  try {
    final response = await client.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200 || response.body.length > 4096) {
      throw const FormatException('Version web indisponible');
    }
    final data = jsonDecode(response.body);
    return newerWebVersion(runningVersion, data);
  } finally {
    client.close();
  }
}

void reloadApp() => web.window.location.reload();
