import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// FCM n'affiche rien automatiquement quand l'app Flutter est au premier
/// plan (comportement normal du SDK, pas un bug) : ce service reçoit les
/// messages foreground depuis MessagingService et les affiche lui-même via
/// une notification locale, avec le même rendu qu'en arrière-plan.
class LocalNotificationsService {
  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'club_hockey_default',
    'Notifications du club',
    description: 'Ouverture des votes, rappels, résultats',
    importance: Importance.high,
  );

  Future<void> init({void Function(String? payload)? onTap}) async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      // Notification locale tapée pendant que l'app est déjà ouverte (premier
      // plan) — le seul des 3 cas qui ne passe pas par les callbacks FCM
      // classiques (onMessageOpenedApp / getInitialMessage), puisque ce n'est
      // pas FCM qui affiche la notif dans ce cas, mais nous.
      onDidReceiveNotificationResponse: (response) =>
          onTap?.call(response.payload),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  Future<void> show({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }
}
