import 'package:aqi_app/configs/navigationservices.dart';
import 'package:aqi_app/main.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

// Must be a top-level function, NOT inside a class
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("📩 Background message received: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Call this from `main.dart` during app initialization
  Future<void> init() async {
    // Initialize Firebase
    await Firebase.initializeApp();
    // await generateToken();
    // Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission (iOS & Android 13+)
    await _requestPermission();

    // Print FCM token

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("📩 Foreground notification: ${message.notification}");
      localNotificationService.showNotification(
        title: message.notification!.title!,
        body: message.notification!.body!,
      );
      // _showSnackBar(message);
    });

    // App opened via notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("📩 Notification clicked: ${message.notification?.title}");
    });
  }

  generateToken() async {
    String mytoken = "";
    debugPrint("before FCM Token: $mytoken");
    try {
      await _messaging.getToken().then((token) {
        debugPrint("📱 FCM Token: $token");
        mytoken = token!;
      });
    } catch (e) {
      // String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      // debugPrint("APNS token: $apnsToken");
      debugPrint("Error getting FCM token: $e");
    }

    return mytoken;
  }

  /// Request user permission for notifications
  Future<void> _requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint("🔔 Permission status: ${settings.authorizationStatus}");
  }

  /// Subscribe to a topic (for campaigns)
  Future<void> subscribeToCampaign() async {
    await _messaging.subscribeToTopic("campaign");
    debugPrint("✅ Subscribed to 'campaign' topic");
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromCampaign() async {
    await _messaging.unsubscribeFromTopic("campaign");
    debugPrint("❌ Unsubscribed from 'campaign' topic");
  }

  /// Simple example: show notification using SnackBar (replace with local_notifications if needed)
  void _showSnackBar(RemoteMessage message) {
    final context = NavigationService.navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${message.notification?.title ?? "No Title"}\n${message.notification?.body ?? "No Body"}",
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

/// Global navigator key (add this in `main.dart`)
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
