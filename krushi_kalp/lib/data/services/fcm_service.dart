import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../utils/crashlytics_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'auth_service.dart';
import 'notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Background Handler (Must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // MUST initialize Firebase in the background isolate before anything else
  await Firebase.initializeApp();

  // 1. Initialize Local Notifications Plugin in the background isolate
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@drawable/ic_notification');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // 2. Define High Importance Channel uniquely for User App
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'krushi_kalp_user_channel',
    'Krushi Kalp User Notifications',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@drawable/ic_notification',
    color: Colors.white, // Requested white icon background
  );
  const NotificationDetails details =
      NotificationDetails(android: androidDetails);

  // 3. Show Notification (User App Offset: +0)
  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    message.notification?.title ?? message.data['title'] ?? 'Krushi Kalp',
    message.notification?.body ?? message.data['body'] ?? '',
    details,
  );
}

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 0. Setup Local Notifications Channel (Important for Android)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'krushi_kalp_user_channel', // id
      'Krushi Kalp User Notifications', // title
      description:
          'This channel is used for important user notifications.', // description
      importance: Importance.max,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Background Handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // 3. Foreground Handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null || message.data.isNotEmpty) {
          // 3. Show Notification (User App Offset: +0)
          final AndroidNotificationDetails androidDetails =
              AndroidNotificationDetails(
            'krushi_kalp_user_channel',
            'Krushi Kalp User Notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
            color: Colors.white, // Requested white icon background
          );
          final NotificationDetails details =
              NotificationDetails(android: androidDetails);

          _flutterLocalNotificationsPlugin.show(
            message.hashCode,
            message.notification?.title ??
                message.data['title'] ??
                'Krushi Kalp',
            message.notification?.body ?? message.data['body'] ?? '',
            details,
          );
        }
      });

      // 4. Subscribe to "all_users" topic for Broadcasts
      await _firebaseMessaging.subscribeToTopic('all_users');

      // 4b. Subscribe to "admin_updates" ONLY if Admin
      final user = AuthService.instance.currentUser;
      if (user != null) {
        final role = await AuthService.instance.getUserRole();

        if (role == 'Admin') {
          await _firebaseMessaging.subscribeToTopic('admin_updates');
        } else {
          await _firebaseMessaging.unsubscribeFromTopic('admin_updates');
        }
      }

      // 5. Get Token
      String? token = await _firebaseMessaging.getToken();

      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        final savedToken = prefs.getString('fcm_token_saved');
        if (savedToken != token) {
          await _saveTokenToDatabase(token);
          await prefs.setString('fcm_token_saved', token);
        }
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        await _saveTokenToDatabase(newToken);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token_saved', newToken);
      });
    }
  }

  Future<void> handleLogout() async {
    try {
      // Unsubscribe from topics on logout to be safe
      await _firebaseMessaging.unsubscribeFromTopic('admin_updates');
    } catch (e, stack) {
      CrashlyticsService.instance
          .recordError(e, stack, reason: 'FCM logout unsubscription failed');
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      try {
        // Save to Firestore under users/{userId}
        await _firestore.collection('users').doc(user.id).set({
          'fcm_token': token,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Also keep it in Supabase for now
        await AuthService.instance.updateProfile(user.id, {
          'fcm_token': token,
        });
      } catch (e, stack) {
        CrashlyticsService.instance
            .recordError(e, stack, reason: 'Save FCM token failed');
      }
    }
  }

  // ignore: unused_element
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final currentChatUserId = NotificationService.currentChatUserId;
    if (currentChatUserId != null) {
      final data = message.data;
      final isFromAdmin =
          data['is_from_admin'] == 'true' || data['is_from_admin'] == true;
      final msgUserId = data['user_id'];

      if (currentChatUserId == 'admin_support_chat') {
        if (isFromAdmin) {
          return;
        }
      } else {
        if (!isFromAdmin && msgUserId == currentChatUserId) {
          return;
        }
      }
    }

    await NotificationService().showLocalNotification(
      id: message.hashCode,
      title: message.notification?.title ?? 'New Message',
      body: message.notification?.body ?? '',
    );
  }
}
