import 'package:supabase_flutter/supabase_flutter.dart';

class AdminNotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Send a broadcast notification to ALL users
  Future<void> sendBroadcast({
    required String title,
    required String body,
  }) async {
    try {
      // 1. Insert into Database (Record Keeping)
      final record = await _supabase
          .from('notifications')
          .insert({
            'user_id': null, // Indicates Broadcast
            'title': title,
            'message': body,
            'type': 'broadcast',
            'is_read': false,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select()
          .single();

      // 2. Call Edge Function (The Actual Push)
      await _callEdgeFunction(
          title: title,
          body: body,
          topic: 'all_users', // Broadcast Topic
          data: {
            'type': 'broadcast',
            'notification_id': record['id'].toString(),
          });
    } catch (e) {
      
      // throw Exception("Failed to send broadcast: $e");
    }
  }

  // Send a notification to a SPECIFIC user
  Future<void> sendToUser({
    required String userId,
    required String title,
    required String body,
  }) async {
    try {
      // 1. Get User's Token (Optional - Function can do it if logic moved, but we pass it for now)
      // Actually, to keep function stateless, we pass token if we have it.
      final userData = await _supabase
          .from('users')
          .select('fcm_token')
          .eq('id', userId)
          .maybeSingle();

      final String? token = userData?['fcm_token'];

      // 2. Insert into Database
      final record = await _supabase
          .from('notifications')
          .insert({
            'user_id': userId,
            'title': title,
            'message': body,
            'type': 'personal',
            'is_read': false,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select()
          .single();

      // 3. Call Edge Function
      if (token != null) {
        await _callEdgeFunction(title: title, body: body, token: token, data: {
          'type': 'personal', // Important for routing
          'notification_id': record['id'].toString(),
        });
      } else {
        
      }
    } catch (e) {
      
    }
  }

  // Send a CHAT REPLY notification (type = 'chat' so it can be suppressed when chat is open)
  Future<void> sendChatReply({
    required String userId,
    required String title,
    required String body,
  }) async {
    try {
      final userData = await _supabase
          .from('users')
          .select('fcm_token')
          .eq('id', userId)
          .maybeSingle();

      final String? token = userData?['fcm_token'];

      final record = await _supabase
          .from('notifications')
          .insert({
            'user_id': userId,
            'title': title,
            'message': body,
            'type': 'chat', // <- distinguishable from general 'personal'
            'is_read': false,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select()
          .single();

      if (token != null) {
        await _callEdgeFunction(title: title, body: body, token: token, data: {
          'type': 'chat',
          'notification_id': record['id'].toString(),
        });
      } else {
        
      }
    } catch (e) {
      
    }
  }

  // Send to Generic Topic (e.g. Admin Updates)
  Future<void> sendToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _callEdgeFunction(
        title: title,
        body: body,
        topic: topic,
        data: data,
      );
    } catch (e) {
      
    }
  }

  Future<void> _callEdgeFunction({
    required String title,
    required String body,
    String? token,
    String? topic,
    Map<String, dynamic>? data,
  }) async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        
        return;
      }

      final response = await _supabase.functions.invoke(
        'send-fcm',
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: {
          'title': title,
          'body': body,
          if (token != null) 'token': token,
          if (topic != null) 'topic': topic,
          if (data != null) 'data': data,
        },
      );

      
    } catch (e) {
      
      // Optional: Check if token is expired and force refresh?
      // _supabase.auth.refreshSession();
    }
  }
}
