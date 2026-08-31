import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:chc_mvp/core/services/local_notifications_service.dart';

/// Gère la demande de permission et la synchronisation du token FCM sur le
/// profil Firestore du membre connecté (users/{uid}.fcmTokens, un tableau
/// car un membre peut être connecté sur plusieurs appareils).
class MessagingService {
  MessagingService(this._messaging, this._firestore, this._localNotifications);

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final LocalNotificationsService _localNotifications;

  /// À appeler juste après la connexion réussie d'un membre. [onNotificationTap]
  /// reçoit le matchId (payload) quand l'utilisateur tape une notification
  /// affichée pendant que l'app est déjà ouverte au premier plan — les deux
  /// autres cas (app en arrière-plan / fermée) sont gérés séparément via
  /// FirebaseMessaging.onMessageOpenedApp et getInitialMessage (voir
  /// messaging_providers.dart, qui a accès à `ref` contrairement à ce service).
  Future<void> initForUser(
    String uid, {
    void Function(String? matchId)? onNotificationTap,
  }) async {
    await _localNotifications.init(onTap: onNotificationTap);

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return; // l'utilisateur a refusé, on ne bloque pas l'app pour autant
    }

    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(uid, token);
    }

    // Si le token est renouvelé pendant que l'app tourne (rotation FCM),
    // on le remet à jour sans action de l'utilisateur.
    _messaging.onTokenRefresh.listen((newToken) => _saveToken(uid, newToken));

    // Affichage natif quand l'app est déjà ouverte : FCM ne le fait pas
    // automatiquement dans ce cas, contrairement au cas app fermée/arrière-plan.
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _localNotifications.show(
        title: notification.title ?? 'CHC MVP',
        body: notification.body ?? '',
        payload: message.data['matchId'],
      );
    });
  }

  /// À appeler à la déconnexion, pour ne pas continuer à notifier un appareil
  /// où plus personne n'est connecté sous ce compte.
  Future<void> clearTokenForUser(String uid) async {
    final token = await _messaging.getToken();
    if (token == null) return;
    await _firestore.collection('users').doc(uid).update({
      'fcmTokens': FieldValue.arrayRemove([token]),
    });
  }

  Future<void> _saveToken(String uid, String token) async {
    await _firestore.collection('users').doc(uid).update({
      'fcmTokens': FieldValue.arrayUnion([token]),
    });
  }
}
