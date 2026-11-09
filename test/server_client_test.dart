import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:chc_mvp/core/config/server_config.dart';
import 'package:chc_mvp/core/services/server_client.dart';

void main() {
  test('missing configuration never defaults to production', () {
    for (final url in [
      '',
      'http://example.test',
      'https://user:pass@example.test',
      'https://example.test?q=x',
    ]) {
      expect(() => configuredServerUri(url), throwsStateError);
    }
    expect(configuredServerUri('http://127.0.0.1:8080').host, '127.0.0.1');
    expect(configuredServerUri('https://example.test').scheme, 'https');
  });
  for (final method in ['GET', 'POST', 'DELETE']) {
    test('$method times out without replaying the request', () async {
      var calls = 0;
      final pending = Completer<http.Response>();
      final client = ServerClient(
        baseUrl: 'https://example.test',
        timeout: const Duration(milliseconds: 10),
        tokenProvider: () async => 'synthetic',
        clientFactory: () => MockClient((request) {
          calls++;
          return pending.future;
        }),
      );
      final request = switch (method) {
        'POST' => client.post('/data', {}),
        'DELETE' => client.delete('/data'),
        _ => client.get('/data'),
      };
      await expectLater(request, throwsA(isA<ServerException>()));
      expect(calls, 1);
      pending.complete(http.Response('{}', 200));
    });
  }
  test('late authentication cannot send an expired write', () async {
    final token = Completer<String?>();
    var calls = 0;
    final client = ServerClient(
      baseUrl: 'https://example.test',
      timeout: const Duration(milliseconds: 10),
      tokenProvider: () => token.future,
      clientFactory: () => MockClient((_) async {
        calls++;
        return http.Response('{}', 200);
      }),
    );
    await expectLater(
      client.post('/data', {}),
      throwsA(isA<ServerException>()),
    );
    token.complete('synthetic');
    await Future<void>.delayed(Duration.zero);
    expect(calls, 0);
  });
  test('HTML error responses become an actionable error', () async {
    final client = ServerClient(
      baseUrl: 'https://example.test',
      tokenProvider: () async => null,
      clientFactory: () => MockClient(
        (_) async => http.Response('<html>proxy error</html>', 502),
      ),
    );
    await expectLater(client.get('/data'), throwsA(isA<ServerException>()));
  });
}
