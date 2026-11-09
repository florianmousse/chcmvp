import 'package:chc_mvp/core/services/push_token_store.dart';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class WebPush {
  static final subscribedUid = ValueNotifier<String?>(null);
  static const _vapid = String.fromEnvironment(
    'WEB_PUSH_VAPID_KEY',
    defaultValue:
        'BNRbOhhjp2PU7vTaKPArxhcXcTsyZ-FfMwbaUCgxloXObVFXAEKKu1BjlrZiNT-2vtGJG3peNbNo6y4rsohcCMc',
  );
  static bool get configured => _vapid.isNotEmpty;
  static bool get needsInstall {
    final nav = web.window.navigator;
    final ios =
        RegExp(r'iPhone|iPad|iPod').hasMatch(nav.userAgent) ||
        (nav.platform == 'MacIntel' && nav.maxTouchPoints > 1);
    return ios && !web.window.matchMedia('(display-mode: standalone)').matches;
  }

  static String get permission {
    try {
      return web.Notification.permission;
    } catch (_) {
      return 'unsupported';
    }
  }

  static bool get dismissed {
    try {
      return web.window.localStorage.getItem(_dismissKey) == 'yes';
    } catch (_) {
      return false;
    }
  }

  static String get _dismissKey =>
      needsInstall ? 'chc-install-dismissed' : 'chc-push-dismissed';

  static void dismiss() {
    try {
      web.window.localStorage.setItem(_dismissKey, 'yes');
    } catch (_) {}
  }

  // Called directly from the button: no asynchronous work before the browser prompt.
  static Future<String> requestPermission() =>
      web.Notification.requestPermission().toDart.then((value) => value.toDart);
  static Future<bool> supported() async {
    if (needsInstall || !web.window.isSecureContext) return false;
    try {
      return await FirebaseMessaging.instance.isSupported();
    } catch (_) {
      return false;
    }
  }

  static Future<void> _pending = Future.value();
  static String? _token;
  static String? _uid;
  static Future<void> sync(String uid) {
    final task = _pending.then((_) async {
      if (!configured ||
          permission != 'granted' ||
          FirebaseAuth.instance.currentUser?.uid != uid ||
          !await supported()) {
        return;
      }
      final token = await FirebaseMessaging.instance.getToken(vapidKey: _vapid);
      if (token == null) throw StateError('Abonnement indisponible');
      if (FirebaseAuth.instance.currentUser?.uid != uid) return;
      if (_token == token && _uid == uid) return;
      await storePushToken(FirebaseFirestore.instance, uid, token);
      _token = token;
      _uid = uid;
      subscribedUid.value = uid;
    });
    _pending = task.catchError((Object _) {});
    return task;
  }

  static Future<void> disconnect() async {
    await _pending;
    if (!await supported() || permission != 'granted') return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final token =
        _token ??
        (configured
            ? await FirebaseMessaging.instance.getToken(vapidKey: _vapid)
            : null);
    // Invalidate delivery first, even if the subsequent Firestore write fails.
    await FirebaseMessaging.instance.deleteToken();
    _token = null;
    _uid = null;
    subscribedUid.value = null;
    if (uid != null && token != null) {
      try {
        await storePushToken(
          FirebaseFirestore.instance,
          uid,
          token,
          remove: true,
        );
      } catch (_) {
        /* The invalidated token is pruned by the sender. */
      }
    }
  }

  static String? takeTarget() {
    final uri = Uri.parse(web.window.location.href);
    final target = uri.queryParameters['notification'];
    if (target != null) {
      final query = Map<String, String>.from(uri.queryParameters)
        ..remove('notification');
      web.window.history.replaceState(
        null,
        '',
        uri.replace(queryParameters: query).toString(),
      );
    }
    return target;
  }
}
