import 'package:flutter_test/flutter_test.dart';
import 'package:chc_mvp/core/services/push_token_store.dart';

void main() {
  test('registration repairs legacy data and keeps the ten latest devices', () {
    expect(updatedPushTokens({}, 'new', remove: false), ['new']);
    expect(
      updatedPushTokens(
        [null, 'bad token', 123, 'valid', 'valid'],
        'new',
        remove: false,
      ),
      ['valid', 'new'],
    );
    final old = List.generate(10, (i) => 'token-$i');
    final updated = updatedPushTokens(old, 'new', remove: false);
    expect(updated, [...old.skip(1), 'new']);
    expect(
      updatedPushTokens(updated, 'new', remove: true),
      old.skip(1).toList(),
    );
    expect(updatedPushTokens(old, 'token-0', remove: false), [
      ...old.skip(1),
      'token-0',
    ]);
  });
  test('invalid registration is rejected', () {
    for (final token in ['', 'white space', 'x' * 4097]) {
      expect(
        () => updatedPushTokens([], token, remove: false),
        throwsArgumentError,
      );
    }
  });
}
