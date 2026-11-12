import 'dart:async';

/// Owns one user's token subscription and cancels stale initialization.
class NotificationSession {
  NotificationSession({
    required this.prepare,
    required this.getToken,
    required this.tokens,
    required this.saveToken,
    required this.onError,
  });
  final Future<bool> Function() prepare;
  final Future<String?> Function() getToken;
  final Stream<String> tokens;
  final Future<void> Function(String uid, String token) saveToken;
  final void Function() onError;
  StreamSubscription<String>? _subscription;
  int _generation = 0;
  String? _uid;
  String? get uid => _uid;

  Future<void> start(String uid) async {
    final generation = ++_generation;
    _uid = uid;
    final old = _subscription;
    _subscription = null;
    await old?.cancel();
    bool current() => generation == _generation;
    try {
      if (!current() || !await prepare() || !current()) return;
      final token = await getToken();
      if (!current()) return;
      if (token != null) await saveToken(uid, token);
      if (!current()) return;
      _subscription = tokens.listen(
        (token) async {
          if (!current()) return;
          try {
            await saveToken(uid, token);
          } catch (_) {
            if (current()) onError();
          }
        },
        onError: (Object _) {
          if (current()) onError();
        },
      );
    } catch (_) {
      if (current()) onError();
    }
  }

  Future<void> stop() async {
    ++_generation;
    _uid = null;
    final old = _subscription;
    _subscription = null;
    await old?.cancel();
  }
}
