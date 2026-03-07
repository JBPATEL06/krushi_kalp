import 'package:flutter/material.dart';
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
  debugPrint("Handling a background message: ${message.messageId}");

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

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Background Handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // 3. Foreground Handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null || message.data.isNotEmpty) {
          debugPrint('Message contained a notification or data payload.');
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
          debugPrint("Subscribed to 'admin_updates' topic (Admin Mode)");
        } else {
          await _firebaseMessaging.unsubscribeFromTopic('admin_updates');
          debugPrint("Unsubscribed from 'admin_updates' topic (User Mode)");
        }
      }

      debugPrint("Subscribed to 'all_users' topic");

      // 5. Get Token
      String? token = await _firebaseMessaging.getToken();
      debugPrint("FCM Token: $token");

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
      // We might keep 'all_users' or unsubscribe, but usually better to unsubscribe
      // if we want to stop notifications on logout.
      // However, 'all_users' might be relevant for general app updates?
      // Let's unsubscribe from personal topics surely.
      // But FCM topics are device-based.
      debugPrint(
          "FCMService: Handling Logout - Unsubscribing from restricted topics.");
    } catch (e) {
      debugPrint("Error handling FCM logout: $e");
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      try {
        // We need to store this in a 'users' table.
        // Use update instead of upsert to avoid accidentally wiping other columns (like username)
        // or failing not-null constraints if the row is treated as new.
        await AuthService.instance.updateProfile(user.id, {
          'fcm_token': token,
        });

        debugPrint("FCM Token Saved to Database");
      } catch (e) {
        debugPrint("Error saving FCM Token: $e");
      }
    }
  }

  // ignore: unused_element
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    // 0. Suppress if Chat is OPEN
    // Access current chat user ID (set in ChatScreen/AdminChatDetailScreen)
    final currentChatUserId = NotificationService.currentChatUserId;
    if (currentChatUserId != null) {
      final data = message.data;
      final isFromAdmin =
          data['is_from_admin'] == 'true' || data['is_from_admin'] == true;
      final msgUserId = data['user_id'];

      // Scenario A: User is chatting with Admin (currentChat = 'admin_support_chat')
      // If notification is from Admin -> Suppress it.
      if (currentChatUserId == 'admin_support_chat') {
        if (isFromAdmin) {
          debugPrint(
              "🚫 Suppressing FCM notification: User is chatting with Admin");
          return;
        }
      }

      // Scenario B: Admin is chatting with User X (currentChat = 'user_x_id')
      // If notification is from User X -> Suppress it.
      else {
        // Only suppress if message is FROM that user (not from another admin/system)
        // And ensure it's NOT from admin (which would be weird self-notification, but good check)
        if (!isFromAdmin && msgUserId == currentChatUserId) {
          debugPrint(
              "🚫 Suppressing FCM notification: Admin is chatting with User $msgUserId");
          return;
        }
      }
    }

    // Reuse the Local Notification setup from NotificationService for consistent icon/channel
    await NotificationService().showLocalNotification(
      id: message.hashCode,
      title: message.notification?.title ?? 'New Message',
      body: message.notification?.body ?? '',
    );
  }
}
