import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Global navigator key used for notification-based deep linking.
/// Must be the same key passed to GoRouter's navigatorKey.
final GlobalKey<NavigatorState> notificationNavigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInit = false;
  StreamSubscription<String>? _tokenRefreshSub;

  Future<void> initialize() async {
    if (_isInit) return;

    // Request permissions
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Set background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize local notifications for foreground display
    const AndroidInitializationSettings initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: initSettingsAndroid);

    await _localNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          _handleNotificationClick(response.payload!);
        }
      },
    );

    // Create high importance channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Foreground message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotificationsPlugin.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: android.smallIcon ?? '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          payload: json.encode(message.data),
        );
      }
    });

    // Handle notification tap when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(json.encode(message.data));
    });

    // Handle notification tap that launched the app from terminated state
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      // Delay slightly to ensure router is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationClick(json.encode(initialMessage.data));
      });
    }

    _isInit = true;
  }

  Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint("Failed to get FCM token: $e");
      return null;
    }
  }

  /// Subscribe to token refresh and call [onNewToken] whenever it rotates.
  void listenToTokenRefresh(Future<void> Function(String token) onNewToken) {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _firebaseMessaging.onTokenRefresh.listen((newToken) {
      onNewToken(newToken);
    });
  }

  /// Navigate to the appropriate screen based on the notification payload.
  void _handleNotificationClick(String payload) {
    try {
      final data = json.decode(payload) as Map<String, dynamic>;
      final type = data['type'] as String?;
      final context = notificationNavigatorKey.currentContext;
      if (context == null) return;

      switch (type) {
        case 'session_saved':
        case 'coach_feedback':
        case 'new_note':
          final sessionId = data['session_id'] as String?;
          if (sessionId != null) {
            GoRouter.of(context).push('/session-history/$sessionId');
          }
          break;
        case 'drill_assigned':
          GoRouter.of(context).go('/home');
          break;
        case 'weekly_summary':
          GoRouter.of(context).go('/analytics');
          break;
        case 'practice_reminder':
          GoRouter.of(context).go('/home');
          break;
        default:
          debugPrint("Unknown notification type: $type");
          break;
      }
    } catch (e) {
      debugPrint("Error handling notification click: $e");
    }
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
  }
}
