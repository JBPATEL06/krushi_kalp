import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Track currently active chat (User ID) to suppress notifications
  static String? currentChatUserId;

  // Notification IDs
  static const int _purchaseReminderId = 101;
  // static const int _newTestIdBase = 200;
  static const int _generalIdBase = 300;
  static const int _chatMessageIdBase = 400;
  // static const int _offerIdBase = 500; // NEW
  static const int _broadcastIdBase = 600; // NEW

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Initialize Timezones
    try {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('UTC'));
    } catch (e) {
      debugPrint("Timezone Init Error: $e");
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // Request Permissions (Android 13+)
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint("Notification Tapped: ${details.payload}");
        // TODO: Navigation logic based on payload
      },
    );

    _isInitialized = true;
    _isInitialized = true;
    debugPrint("NotificationService Initialized (Listeners waiting for Auth)");
  }

  // Renamed from _listenForPublicUpdates and made public for BackgroundService
  Future<void> connectBackground(SupabaseClient supabase) async {
    // 1. Listen for NEW MOCK TESTS
    try {
      debugPrint("📡 Setup MockTest Listener (Background)");
      supabase
          .channel('public:mock_tests:updates')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'mock_tests',
            callback: (payload) {
              final newTest = payload.newRecord;
              debugPrint("📝 New Mock Test: ${newTest['title']}");
//              showLocalNotification(
//                id: _newTestIdBase + (newTest['test_id'] as int? ?? 0),
//                title: "New Mock Test Added!",
//                body: "Check out: ${newTest['title']}",
//              );

// ... (In Broadcast)
//                showLocalNotification(
//                  id: _broadcastIdBase +
//                      (newNotif['notification_id'] as int? ?? 0),
//                  title: newNotif['title'] ?? 'Announcement',
//                  body: newNotif['message'] ?? 'Check the app for updates.',
//                );
            },
          )
          .subscribe((status, error) {
        debugPrint("📝 MockTest Listener Status: $status, Error: $error");
      });
    } catch (e) {
      debugPrint("Error setup MockTest listener: $e");
    }

    // 2. Listen for NEW OFFERS
    try {
      debugPrint("📡 Setup Offer Listener");
      supabase
          .channel('public:offers:updates')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'offers',
            callback: (payload) {
              final newOffer = payload.newRecord;
              debugPrint("🏷️ New Offer: ${newOffer['title']}");
//              showLocalNotification(
//                id: _offerIdBase + (newOffer['id'] as int? ?? 0),
//                title: "New Offer Available!",
//                body:
//                    "${newOffer['title']} - ${newOffer['discount_percentage']}% OFF!",
//              );
            },
          )
          .subscribe((status, error) {
        debugPrint("🏷️ Offer Listener Status: $status, Error: $error");
      });
    } catch (e) {
      debugPrint("Error setup Offer listener: $e");
    }
  }

  bool _isConnected = false;

  Future<void> connectUser() async {
    if (_isConnected) {
      debugPrint("NotificationService: Already Connected. Skipping.");
      return;
    }

    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      debugPrint("NotificationService: Connecting User $userId");
      _isConnected = true;
      await _listenForPersonalNotifications(supabase, userId);
      await connectBackground(supabase); // Public (Offers/MockTests)
      await _listenForChatMessages(supabase, userId, isUser: true); // User Mode
    }
  }

  Future<void> connectAdmin() async {
    if (_isConnected) {
      debugPrint("NotificationService: Already Connected (Admin). Skipping.");
      return;
    }

    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      debugPrint("NotificationService: Connecting Admin $userId");
      _isConnected = true;
      // Admin also gets broadcasts/personal notifs
      await _listenForPersonalNotifications(supabase, userId);
      await _listenForBroadcastNotifications(supabase);
      await connectBackground(supabase); // Public (Offers/MockTests)

      await _listenForChatMessages(supabase, userId,
          isUser: false); // Admin Mode
    }
  }

  // --- 6-DAY REMINDER ---
  Future<void> schedulePurchaseReminder() async {
    await _notificationsPlugin.zonedSchedule(
      _purchaseReminderId,
      'Complete Your Purchase!',
      'It\'s been a while. Don\'t miss out on the latest mock tests!',
      tz.TZDateTime.now(tz.local).add(const Duration(days: 6)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'purchase_reminders',
          'Purchase Reminders',
          channelDescription: 'Reminders to complete purchases',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    debugPrint("Scheduled Purchase Reminder for 6 days from now.");
  }

  Future<void> cancelPurchaseReminder() async {
    await _notificationsPlugin.cancel(_purchaseReminderId);
    debugPrint("Cancelled Purchase Reminder.");
  }

  // 1. Personal Notifications
  Future<void> _listenForPersonalNotifications(
    SupabaseClient supabase,
    String authId,
  ) async {
    try {
      debugPrint("🔔 Setup Personal Listener for $authId");
      supabase
          .channel('public:notifications:personal:$authId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: authId,
            ),
            callback: (payload) {
              print("📩 Personal Payload Received: ${payload.newRecord}");
              final newNotif = payload.newRecord;
              showLocalNotification(
                id: _generalIdBase + (newNotif['notification_id'] as int? ?? 0),
                title: newNotif['title'] ?? 'New Notification',
                body: newNotif['message'] ?? 'You have a new update.',
              );
            },
          )
          .subscribe((status, error) {
        print("🔔 Personal Listener Status: $status, Error: $error");
      });
    } catch (e) {
      print("Error setting up personal listener: $e");
    }
  }

  // 2. Broadcast Notifications
  Future<void> _listenForBroadcastNotifications(SupabaseClient supabase) async {
    try {
      print("📡 Setup Broadcast Listener (No Filter)");
      supabase
          .channel('public:notifications:broadcast_secure')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            // REMOVED FILTER: Rely on RLS to deliver Broadcasts (user_id is NULL)
            // Filtering by 'null' in the SDK can sometimes be flaky.
            // RLS ensures we only see our own (handled by other listener) or Broadcasts.
            callback: (payload) {
              final newNotif = payload.newRecord;

              // Only process if it is actually a broadcast (user_id is null)
              // to avoid duplicates if RLS sends us our own personal notifs here too.
              if (newNotif['user_id'] == null) {
                print("📢 Broadcast Payload Received: $newNotif");
                showLocalNotification(
                  id: _broadcastIdBase +
                      (newNotif['notification_id'] as int? ?? 0),
                  title: newNotif['title'] ?? 'Announcement',
                  body: newNotif['message'] ?? 'Check the app for updates.',
                );
              }
            },
          )
          .subscribe((status, error) {
        print("📡 Broadcast Listener Status: $status, Error: $error");
      });
    } catch (e) {
      print("Error setting up broadcast listener: $e");
    }
  }

  // Chat Listener
  Future<void> _listenForChatMessages(
    SupabaseClient supabase,
    String authId, {
    required bool isUser,
  }) async {
    try {
      // Define a unique channel name per usage to avoid conflicts
      final channelName =
          'public:messages:$authId:${isUser ? "user" : "admin"}';

      supabase
          .channel(channelName)
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'messages',
            // Note: PostgresChangeFilter limited to single column equality usually.
            // For User: filter user_id=authId.
            // For Admin: we want ALL messages where is_from_admin=false.
            // Filtering by is_from_admin=false is possible if column is indexed/allowed.
            filter: isUser
                ? PostgresChangeFilter(
                    type: PostgresChangeFilterType.eq,
                    column: 'user_id',
                    value: authId,
                  )
                : PostgresChangeFilter(
                    type: PostgresChangeFilterType.eq,
                    column: 'is_from_admin',
                    value:
                        false, // Admin listens for User messages (is_from_admin = false)
                  ),
            callback: (payload) {
              try {
                final newMsg = payload.newRecord;
                final bool isFromAdmin =
                    newMsg['is_from_admin'] as bool? ?? false;
                final String msgUserId = newMsg['user_id'] as String;

                // ID is likely a UUID (String), so we must use hashCode for Notification ID (int)
                final msgIdValue = newMsg['id'];
                final int msgIdHash = msgIdValue.hashCode;

                // User Message Handler
                if (isUser) {
                  // User: Only notify if From Admin
                  if (isFromAdmin && msgUserId == authId) {
                    // Suppress if chat with Admin is open
                    if (currentChatUserId == 'admin_support_chat') {
                      print(
                          "Suppressing notification: User is chatting with Admin");
                      return;
                    }

                    showLocalNotification(
                      id: _chatMessageIdBase + msgIdHash, // FIXED: Use hashCode
                      title: 'New Reply',
                      body: newMsg['message'] ?? 'New message from support',
                    );
                  }
                } else {
                  // Admin: Only notify if From User (Not From Admin)
                  if (!isFromAdmin) {
                    if (currentChatUserId == msgUserId) {
                      print(
                          "Suppressing notification: Admin is chatting with User $msgUserId");
                      return;
                    }

                    showLocalNotification(
                      id: _chatMessageIdBase + msgIdHash, // FIXED: Use hashCode
                      title: 'New User Message',
                      body: 'User sent: ${newMsg['message']}',
                    );
                  }
                }
              } catch (e) {
                print("Error inside chat listener callback: $e");
              }
            },
          )
          .subscribe();
    } catch (e) {
      print("Error setting up chat listener: $e");
    }
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'general_channel',
      'General Notifications',
      importance: Importance.high,
      priority: Priority.high,
      color: const Color(0xFF4CAF50), // Green for notification icon background
    );
    const details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(id, title, body, details);
  }
}
