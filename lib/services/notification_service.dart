import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:buyeasy_retailer/services/api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging? _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Stream for silent updates
  final _updateController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get updateStream => _updateController.stream;

  Future<void> initialize() async {
    _fcm = FirebaseMessaging.instance;
    // Request permissions
    NotificationSettings settings = await _fcm!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      print('User granted permission: ${settings.authorizationStatus}');
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: DarwinInitializationSettings(),
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification click while app is open (Foreground)
        if (details.payload != null) {
          _handleLocalNotificationTap(details.payload);
        }
      },
    );

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }

    // Check for initial message (Terminated state)
    _fcm?.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleMessageTap(message);
      }
    });

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen(_handleMessage);

    // Listen for background message clicks
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
  }

  Future<String?> getToken() async {
    if (_fcm == null) return null;
    try {
      return await _fcm!.getToken();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
      return null;
    }
  }

  void _handleMessageTap(RemoteMessage message) {
    if (kDebugMode) {
      print('Message clicked: ${message.data}');
    }
    _navigateToOrder(message.data);
  }

  void _handleLocalNotificationTap(String? payload) {
    if (payload != null) {
      _navigateToOrder({'order_id': payload});
    }
  }

  void _navigateToOrder(Map<String, dynamic> data) {
    final orderId = data['order_id'] ?? data['id'];
    if (orderId != null) {
      int? parsedId = int.tryParse(orderId.toString());
      if (parsedId != null) {
        ApiService().navigatorKey.currentState?.pushNamed(
          '/order-detail',
          arguments: parsedId,
        );
      }
    }
  }

  void _handleMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('Handling foreground message: ${message.messageId}');
    }

    if (message.data['is_silent'] == 'true' ||
        message.data['event'] != null ||
        message.data['type'] == 'order_chat') {
      _updateController.add(Map<String, dynamic>.from(message.data));
      if (message.data['is_silent'] == 'true') return;
    }

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null && !kIsWeb) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload:
            message.data['order_id']?.toString() ??
            message.data['id']?.toString(),
      );
    }
  }
}
