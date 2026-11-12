import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:chc_mvp/core/services/push_token_store.dart';
import 'package:chc_mvp/core/services/notification_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chc_mvp/core/services/local_notifications_service.dart';

String? notificationTarget(Map<String, dynamic> data) =>
    data['ceremonyId'] is String
    ? 'ceremony:${data['ceremonyId']}'
    : data['matchId'] is String
    ? data['matchId'] as String
    : null;

class MessagingService {
  MessagingService(
    FirebaseMessaging messaging,
    FirebaseFirestore firestore,
    this._localNotifications,
  ) {
    _session = NotificationSession(
      prepare: () async {
        await _localNotifications.init(onTap: (target) => _onTap?.call(target));
        final permission = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        return permission.authorizationStatus != AuthorizationStatus.denied;
      },
      getToken: messaging.getToken,
      tokens: messaging.onTokenRefresh,
      saveToken: (uid, token) async {
        if (FirebaseAuth.instance.currentUser?.uid != uid) return;
        await storePushToken(firestore, uid, token);
      },
      onError: () => debugPrint(
        'Notifications : synchronisation indisponible. Réessayer à la prochaine connexion.',
      ),
    );
    _messages = FirebaseMessaging.onMessage.listen((message) async {
      if (_session.uid == null ||
          FirebaseAuth.instance.currentUser?.uid != _session.uid) {
        return;
      }
      final notification = message.notification;
      if (notification == null) return;
      try {
        await _localNotifications.show(
          title: notification.title ?? 'CHC MVP',
          body: notification.body ?? '',
          payload: notificationTarget(message.data),
        );
      } catch (_) {
        debugPrint('Notifications : affichage local indisponible.');
      }
    });
  }
  final LocalNotificationsService _localNotifications;
  late final NotificationSession _session;
  late final StreamSubscription<RemoteMessage> _messages;
  void Function(String?)? _onTap;
  Future<void> initForUser(
    String uid, {
    void Function(String? matchId)? onNotificationTap,
  }) {
    _onTap = onNotificationTap;
    return _session.start(uid);
  }

  Future<void> clearTokenForUser(String uid) async {
    // AuthService invalidates delivery before sign-out. Do not write to a
    // protected profile after authentication has disappeared.
    _onTap = null;
    await _session.stop();
  }

  Future<void> dispose() async {
    _onTap = null;
    await _session.stop();
    await _messages.cancel();
  }
}
