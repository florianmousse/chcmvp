/// Required for every build; never fall back to the club production backend.
const String serverBaseUrl = String.fromEnvironment('SERVER_BASE_URL');

Uri configuredServerUri(String value) {
  final uri = Uri.tryParse(value);
  final local =
      uri != null && ['localhost', '127.0.0.1', '::1'].contains(uri.host);
  if (uri == null ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      (uri.path.isNotEmpty && uri.path != '/') ||
      (uri.scheme != 'https' && !(local && uri.scheme == 'http'))) {
    throw StateError(
      'SERVER_BASE_URL manquant ou invalide. Configurez une URL HTTPS (HTTP uniquement en local).',
    );
  }
  return uri;
}
