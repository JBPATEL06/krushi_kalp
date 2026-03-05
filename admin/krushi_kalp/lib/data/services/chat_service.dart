import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/message.dart';
import 'auth_service.dart';
import 'admin_notification_service.dart'; // NEW
import '../../utils/network_utils.dart'; // Import NetworkUtils

class ChatService {
  // Singleton
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;

  // --- CONTROLLERS ---

  // 1. Admin Conversation List
  final StreamController<List<Map<String, dynamic>>> _conversationsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  bool _isRealtimeConnected = false;

  ChatService._internal() {
    debugPrint("ChatService: Singleton Initialized");
  }

  // ==========================================
  //         ADMIN: CONVERSATION LIST
  // ==========================================

  Stream<List<Map<String, dynamic>>> getConversationsStream() {
    debugPrint("ChatService: getConversationsStream called");
    _ensureRealtimeListener();
    refreshConversations();
    return _conversationsController.stream;
  }

  void _ensureRealtimeListener() {
    if (_isRealtimeConnected) return;

    debugPrint("ChatService: Setting up Global Realtime Listener...");

    // Listen to ALL messages table changes
    final channel = _supabase.channel('public:messages:global');
    channel
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        debugPrint("ChatService: Realtime Event! ${payload.eventType}");

        // 1. Refresh Conversation List
        Future.delayed(const Duration(milliseconds: 500), () {
          refreshConversations();

          // 2. Refresh Open Chat Details if applicable
          _refreshAllOpenChats();

          // 3. Refresh User Messages if applicable
          _refreshUserMessages();
        });
      },
    )
        .subscribe((status, error) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        debugPrint("ChatService: Connected to Realtime!");
        _isRealtimeConnected = true;
      }
    });
  }

  Future<void> refreshConversations() async {
    try {
      final data = await getConversations();
      if (!_conversationsController.isClosed) {
        _conversationsController.add(data);
      }
    } catch (e) {
      if (NetworkUtils.isNetworkError(e)) return;
      debugPrint("ChatService: Refresh Error: $e");
    }
  }

  void _refreshAllOpenChats() {
    // Deprecated for Admin: Admin detail now uses native Supabase streams
  }

  void _refreshUserMessages() {
    // Deprecated: User stream now uses native Supabase streams
  }

  // ==========================================
  //         ADMIN: CHAT DETAIL STREAM
  // ==========================================

  Stream<List<Message>> getAdminMessagesStream(String userId) {
    debugPrint(
        "ChatService: getAdminMessagesStream for $userId (Using Native Stream)");

    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: true)
        .map((events) => events.map((json) => Message.fromJson(json)).toList());
  }

  Future<void> sendMessageAsAdmin(String text, String targetUserId) async {
    await _supabase.from('messages').insert({
      'user_id': targetUserId,
      'message': text,
      'is_from_admin': true,
    });

    // FORCE REFRESH IMMEDIATELY
    // 1. Refresh the conversation list
    await refreshConversations();

    // 3. Send Notification to User
    AdminNotificationService().sendToUser(
      userId: targetUserId,
      title: 'New Message from Support',
      body: text,
    );
  }

  // ==========================================
  //         USER: CHAT STREAM
  // ==========================================

  Stream<List<Message>> getMessagesStream() {
    final user = AuthService().currentUser;
    if (user == null) return Stream.value([]);

    debugPrint(
        "ChatService: getMessagesStream (User) called (Using Native Stream)");

    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: true)
        .map((events) => events.map((json) => Message.fromJson(json)).toList());
  }

  Future<void> sendMessage(String text) async {
    final user = AuthService().currentUser;
    if (user == null) return;

    await _supabase.from('messages').insert({
      'user_id': user.id,
      'message': text,
      'is_from_admin': false,
    });

    // Native stream auto-updates.
    // OPTIONAL: Refresh admin conversations list too if we were logged in as both (unlikely)
    // But helpful if testing on same device or simulator.
    refreshConversations();

    // 3. Notify Admin (via Topic 'admin_updates')
    AdminNotificationService().sendToTopic(
      topic: 'admin_updates',
      title: 'New User Message',
      body: text,
      data: {'type': 'personal', 'user_id': user.id},
    );
  }

  // ==========================================
  //         DELETE MESSAGE
  // ==========================================

  Future<void> deleteMessage(String messageId) async {
    debugPrint("ChatService: Deleting single message: $messageId");
    try {
      await deleteMessages([messageId]);
    } catch (e) {
      debugPrint("ChatService: Delete Single Error: $e");
      rethrow;
    }
  }

  Future<void> deleteMessages(List<String> messageIds) async {
    if (messageIds.isEmpty) return;
    debugPrint(
        "ChatService: Deleting ${messageIds.length} messages: $messageIds");
    try {
      // Note: checking count might be good but requires different syntax
      final response = await _supabase
          .from('messages')
          .delete()
          .inFilter('id', messageIds)
          .select();
      debugPrint(
          "ChatService: Deleted ${response.length} messages successfully.");
      _notifyRefresh();
    } catch (e) {
      debugPrint("ChatService: Delete Error: $e");
      // If error is RLS related, it often throws or returns 0 rows if using select()
      // Note: .delete() by itself returns void/dynamic, adding .select() returns deleted rows.
      // If RLS blocks it, response might be empty.
      rethrow;
    }
  }

  Future<void> clearChat() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    // Delete all messages where user_id matches OR message is SENT to this user?
    // Usually "Clear Chat" clears history.
    // Based on RLS, user can only delete where user_id = auth.uid().
    // So they can only delete THEIR sent messages?
    // Or if we want to just "hide" them?
    // For now, let's implement "Delete All My Sent Messages".
    // If we want to clear conversation, usually we delete local copy or set a "deleted_at" flag.
    // The user said "clear from user side".
    // Let's assume hard delete for now as per "allow bulk delete".

    await _supabase.from('messages').delete().eq('user_id', user.id);
    _notifyRefresh();
  }

  // ==========================================
  //         ADMIN: DELETE CONVERSATION
  // ==========================================

  Future<void> deleteConversation(String userId) async {
    // Delete all messages where user_id matches
    await _supabase.from('messages').delete().eq('user_id', userId);
    _notifyRefresh();
  }

  void _notifyRefresh() {
    refreshConversations();
    _refreshUserMessages();
    _refreshAllOpenChats();
  }

  // ==========================================
  //         HELPER: GET CONVERSATIONS
  // ==========================================
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final messagesResponse = await _supabase
          .from('messages')
          .select('user_id, created_at')
          .order('created_at', ascending: false)
          .limit(100);

      final Set<String> userIds = {};
      final List<Map<String, dynamic>> tempConversations = [];

      for (final record in (messagesResponse as List)) {
        final userId = record['user_id'] as String;
        if (!userIds.contains(userId)) {
          userIds.add(userId);
          tempConversations.add({
            'user_id': userId,
            'last_active': record['created_at'],
            'email': 'Loading...',
            'username': 'User',
          });
        }
      }

      if (userIds.isEmpty) return [];

      final usersResponse = await _supabase
          .from('users')
          .select('id, email, username')
          .inFilter('id', userIds.toList());

      final Map<String, Map<String, dynamic>> userMap = {};
      for (final user in (usersResponse as List)) {
        userMap[user['id'] as String] = user as Map<String, dynamic>;
      }

      return tempConversations.map((conv) {
        final userId = conv['user_id'] as String;
        final userDetails = userMap[userId];
        return {
          ...conv,
          'email': userDetails?['email'] ?? 'Unknown Email',
          'username': userDetails?['username'] ?? 'User',
        };
      }).toList();
    } catch (e) {
      if (NetworkUtils.isNetworkError(e)) return [];
      print("ChatService Error: $e");
      return [];
    }
  }
}
