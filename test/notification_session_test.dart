import 'dart:async';
import 'package:chc_mvp/core/services/notification_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'reconnection replaces the old token subscriber and stop cancels it',
    () async {
      final tokens = StreamController<String>.broadcast();
      final saved = <String>[];
      var errors = 0;
      final session = NotificationSession(
        prepare: () async => true,
        getToken: () async => 'initial',
        tokens: tokens.stream,
        saveToken: (uid, token) async => saved.add('$uid:$token'),
        onError: () => errors++,
      );
      await session.start('first');
      await session.start('second');
      tokens.add('rotated');
      await Future<void>.delayed(Duration.zero);
      expect(saved, ['first:initial', 'second:initial', 'second:rotated']);
      await session.stop();
      tokens.add('after-logout');
      await Future<void>.delayed(Duration.zero);
      expect(saved.length, 3);
      expect(tokens.hasListener, false);
      expect(errors, 0);
      await tokens.close();
    },
  );

  test('logout overtakes an unfinished permission or token request', () async {
    final permission = Completer<bool>();
    final tokens = StreamController<String>.broadcast();
    final saved = <String>[];
    final session = NotificationSession(
      prepare: () => permission.future,
      getToken: () async => 'late',
      tokens: tokens.stream,
      saveToken: (uid, token) async => saved.add(token),
      onError: () {},
    );
    final starting = session.start('first');
    await Future<void>.delayed(Duration.zero);
    await session.stop();
    permission.complete(true);
    await starting;
    expect(saved, isEmpty);
    expect(tokens.hasListener, false);
    await tokens.close();
  });

  test(
    'a failed token write reports a diagnostic and later rotations still work',
    () async {
      final tokens = StreamController<String>.broadcast();
      var errors = 0;
      final saved = <String>[];
      final session = NotificationSession(
        prepare: () async => true,
        getToken: () async => null,
        tokens: tokens.stream,
        saveToken: (_, token) async {
          if (token == 'bad') throw StateError('synthetic');
          saved.add(token);
        },
        onError: () => errors++,
      );
      await session.start('user');
      tokens.add('bad');
      tokens.add('good');
      await Future<void>.delayed(Duration.zero);
      expect(errors, 1);
      expect(saved, ['good']);
      await session.stop();
      await tokens.close();
    },
  );
}
