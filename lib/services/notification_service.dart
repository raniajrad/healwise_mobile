import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Africa/Tunis'));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);

    // ✅ Plugin Android dans une variable
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    // ✅ Demander permissions
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    // ✅ Créer le canal
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'medication_channel',
      'Rappels Médicaments',
      description: 'Ce canal envoie des alertes sonores pour vos médicaments',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('medical_beep'),
    );

    await androidPlugin?.createNotificationChannel(channel);
  }

  static Future<void> scheduleNotification(
    int id,
    String title,
    String body,
    DateTime scheduledTime,
  ) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_channel',
          'Rappels Médicaments',
          channelDescription: 'Canal pour les alertes médicales',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('medical_beep'),
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
