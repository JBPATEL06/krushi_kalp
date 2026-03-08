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

  /// Expose the underlying notifications plugin for use by other specialized
  /// notification services (e.g., TransferNotificationService) to avoid
  /// double-initialization issues.
  FlutterLocalNotificationsPlugin get plugin => _notificationsPlugin;

  final _supabase = Supabase.instance.client;

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
    _initTimezones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // Request Permissions (Android 13+) - ONLY IN FOREGROUND
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        
      },
    );

    _isInitialized = true;
    
  }

  /// Initialize without permission requests (Safe for Background Isolates)
  Future<void> initializeBackground() async {
    if (_isInitialized) return;

    _initTimezones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);

    _isInitialized = true;
    
  }

  void _initTimezones() {
    try {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('UTC'));
    } catch (e) {
      
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  // Renamed from _listenForPublicUpdates and made public for BackgroundService
  Future<void> connectBackground(SupabaseClient supabase) async {
    // 1. Listen for NEW MOCK TESTS
    try {
      
      supabase
          .channel('public:mock_tests:updates')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'mock_tests',
            callback: (payload) {
              final newTest = payload.newRecord;
              
              showLocalNotification(
                id: _generalIdBase + (newTest['test_id'] as int? ?? 0),
                title: "New Mock Test Added!",
                body: "Check out: ${newTest['title']}",
              );

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
        
      });
    } catch (e) {
      
    }

    // 2. Listen for NEW OFFERS
    try {
      
      supabase
          .channel('public:offers:updates')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'offers',
            callback: (payload) {
              final newOffer = payload.newRecord;
              
              showLocalNotification(
                id: _generalIdBase + (newOffer['id'] as int? ?? 0),
                title: "New Offer Available!",
                body:
                    "${newOffer['title']} - ${newOffer['discount_percentage']}% OFF!",
              );
            },
          )
          .subscribe((status, error) {
        
      });
    } catch (e) {
      
    }
  }

  bool _isConnected = false;

  Future<void> connectUser() async {
    await initialize(); // MUST init plugin before listening
    if (_isConnected) {
      
      return;
    }

    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      
      _isConnected = true;
      await _listenForPersonalNotifications(supabase, userId);
      await _listenForBroadcastNotifications(
          supabase); // â† ADDED: Global admin broadcasts
      await connectBackground(supabase); // Public (Offers/MockTests)
      await _listenForChatMessages(supabase, userId, isUser: true); // User Mode
    }
  }

  Future<void> connectAdmin() async {
    await initialize(); // MUST init plugin before listening
    if (_isConnected) {
      
      return;
    }

    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      
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
    
  }

  Future<void> cancelPurchaseReminder() async {
    await _notificationsPlugin.cancel(_purchaseReminderId);
    
  }

  // 1. Personal Notifications
  Future<void> _listenForPersonalNotifications(
    SupabaseClient supabase,
    String authId,
  ) async {
    try {
      
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
              
              final newNotif = payload.newRecord;

              // Suppress CHAT reply notifications if chat screen is currently open
              final String? notifType = newNotif['type'] as String?;
              if (NotificationService.currentChatUserId ==
                      'admin_support_chat' &&
                  notifType == 'chat') {
                
                return;
              }

              showLocalNotification(
                id: _generalIdBase + (newNotif['notification_id'] as int? ?? 0),
                title: newNotif['title'] ?? 'New Notification',
                body: newNotif['message'] ?? 'You have a new update.',
              );
            },
          )
          .subscribe((status, error) {
        
      });
    } catch (e) {
      
    }
  }

  // 2. Broadcast Notifications
  Future<void> _listenForBroadcastNotifications(SupabaseClient supabase) async {
    try {
      
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
        
      });
    } catch (e) {
      
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
                  // User notifications for admin replies are handled exclusively by
                  // _listenForPersonalNotifications via sendChatReply() DB insert.
                  // This avoids double-notifications.
                  // No local notification shown here.
                  return;
                } else {
                  // Admin: Only notify if From User (Not From Admin)
                  if (!isFromAdmin) {
                    if (currentChatUserId == msgUserId) {
                      
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
                
              }
            },
          )
          .subscribe();
    } catch (e) {
      
    }
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel', // FIXED: Sync with Manifest & FCM
      'High Importance Notifications',
      importance: Importance.high,
      priority: Priority.high,
      color: Colors.white,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(id, title, body, details);
  }

  Stream<List<Map<String, dynamic>>> fetchNotificationsStream(int userDbId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['notification_id'])
        .eq('user_id', userDbId)
        .order('created_at', ascending: false);
  }

  Future<void> deleteNotification(int id) async {
    await _supabase.from('notifications').delete().eq('notification_id', id);
  }
}
