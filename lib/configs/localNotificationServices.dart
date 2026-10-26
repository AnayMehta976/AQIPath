import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// 🚀 Initialize notifications
  Future<void> create() async {
    await _requestPermissions();
    await _initializeNotifications();
  }

  /// 🔔 Show a notification
  Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'location_channel',
      'Location Updates',
      channelDescription: 'Shows continuous location updates',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      playSound: false,
      enableVibration: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: false,
      presentBadge: false,
    );

    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, platformDetails);
  }

  /// 🔁 Update existing notification (same ID)
  Future<void> updateNotification({
    required String title,
    required String body,
  }) async {
    await showNotification(title: title, body: body, id: 1);
  }

  /// 📲 Initialize plugin
  Future<void> _initializeNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _notifications.initialize(initSettings);
    print("🔔 Notification service initialized");
  }

  /// 🔐 Permissions
  Future<void> _requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }
}
