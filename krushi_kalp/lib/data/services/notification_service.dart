import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../../utils/crashlytics_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FlutterLocalNotificationsPlugin get plugin => _notificationsPlugin;

  // ignore: unused_field
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

  Future<void> initialize({bool skipPermissions = false}) async {
    if (_isInitialized) return;

    // 1. Initialize Timezones
    _initTimezones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // Request Permissions (Android 13+) - ONLY IN FOREGROUND
    // Background isolates do not have an Activity and will crash if this is called.
    if (!skipPermissions) {
      try {
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } catch (e) {
        debugPrint('Notification Permission Request Failed: $e');
      }
    }

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        
      },
    );

    // Initialize the unified transfer notification service using our plugin instance
    TransferNotificationService().initialize(_notificationsPlugin);
    await TransferNotificationService().setupChannel();

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
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'Timezone initialization failed');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  // Renamed from _listenForPublicUpdates and made public for BackgroundService
  Future<void> connectBackground(SupabaseClient supabase) async {
    // Automatic listeners for mock_tests and offers removed.
    // Notifications for these items are now handled manually by AdminService toggles
    // to prevent alerts firing before items are marked as Public.
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
          supabase); // ← ADDED: Global admin broadcasts
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
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'Personal notifications subscription failed');
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
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'Broadcast notifications subscription failed');
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
              } catch (e, stack) {
                CrashlyticsService.instance.recordError(e, stack, reason: 'Chat message processing failed');
              }
            },
          )
          .subscribe();
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'Listen for chat messages failed');
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

  Stream<List<Map<String, dynamic>>> fetchNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', whereIn: [userId, null])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'notification_id': doc.id,
                'title': data['title'],
                'message': data['message'],
                'type': data['type'],
                'is_read': data['isRead'] ?? false,
                'created_at': data['createdAt'] is Timestamp 
                    ? (data['createdAt'] as Timestamp).toDate().toIso8601String()
                    : data['createdAt']?.toString(),
                'userId': data['userId'],
              };
            }).toList());
  }

  Future<void> deleteNotification(String id) async {
    await _firestore.collection('notifications').doc(id).delete();
  }

  Future<void> markAsRead(String id) async {
    await _firestore.collection('notifications').doc(id).update({'isRead': true});
  }
}
