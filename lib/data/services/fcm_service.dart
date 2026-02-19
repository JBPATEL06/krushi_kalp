import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

// Background Handler (Must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need Supabase in background, init here (optional for just showing notification)
  // await Firebase.initializeApp(); // Usually needed
  debugPrint("Handling a background message: ${message.messageId}");

  // Note: Firebase Messaging automatically shows a notification if "notification" payload is present.
  // If "data" only, we might need to show it manually.
}

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 0. Setup Local Notifications Channel (Important for Android)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description:
          'This channel is used for important notifications.', // description
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

        if (message.notification != null) {
          debugPrint(
              'Message also contained a notification: ${message.notification}');
          // Show Local Notification
          // CRITICAL FIX: Commenting this out to preventing DUPLICATE notifications.
          // NotificationService already listens to Supabase Realtime in the foreground
          // and shows local notifications.
          // _showForegroundNotification(message);
        }
      });

      // 4. Subscribe to "all_users" topic for Broadcasts
      await _firebaseMessaging.subscribeToTopic('all_users');

      // 4b. Subscribe to "admin_updates" ONLY if Admin
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await Supabase.instance.client
            .from('users')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();

        if (profile != null && profile['role'] == 'Admin') {
          await _firebaseMessaging.subscribeToTopic('admin_updates');
          debugPrint("Subscribed to 'admin_updates' topic (Admin Mode)");
        } else {
          // CRITICAL FIX: Explicitly unsubscribe if NOT admin
          // This prevents "User" accounts on a device previously used by "Admin"
          // from receiving admin notifications.
          await _firebaseMessaging.unsubscribeFromTopic('admin_updates');
          debugPrint("Unsubscribed from 'admin_updates' topic (User Mode)");
        }
      }

      debugPrint("Subscribed to 'all_users' topic");

      // 5. Get Token
      String? token = await _firebaseMessaging.getToken();
      debugPrint("FCM Token: $token");

      if (token != null) {
        await _saveTokenToDatabase(token);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);
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
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        // We need to store this in a 'users' table.
        // Use update instead of upsert to avoid accidentally wiping other columns (like username)
        // or failing not-null constraints if the row is treated as new.
        await Supabase.instance.client.from('users').update({
          'fcm_token': token,
        }).eq('id', user.id);

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
