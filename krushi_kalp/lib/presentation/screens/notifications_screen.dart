import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/auth_service.dart';
import '../widgets/common/network_error_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Stream<List<Map<String, dynamic>>> _notificationsStream;

  @override
  void initState() {
    super.initState();
    _setupStream();
  }

  void _setupStream() {
    final user = AuthService().currentUser;

    if (user != null) {
      // Need integer user_id. Fetch it first or use a FutureBuilder wrapper?
      // Better: Stream query relies on 'id' -> wait.
      // The 'notifications' table uses 'user_id' (int).
      // We must map Auth ID (uuid) to User ID (int).
      // Doing this inside a Stream is tricky.
      // Alternative: Use Future to get ID, then Stream.
      // For now, I'll allow a loading state.
      _notificationsStream = Stream.empty();
      _fetchUserIdAndStream(user.id);
    } else {
      _notificationsStream = Stream.value([]);
    }
  }

  Future<void> _fetchUserIdAndStream(String authId) async {
    final supabase = Supabase.instance.client;
    try {
      final userResponse = await supabase
          .from('users')
          .select('user_id')
          .eq('id', authId)
          .maybeSingle();

      if (userResponse != null && mounted) {
        final intDbId = userResponse['user_id'] as int;
        setState(() {
          _notificationsStream = supabase
              .from('notifications')
              .stream(primaryKey: ['notification_id'])
              .eq('user_id', intDbId)
              .order('created_at', ascending: false);
        });
      }
    } catch (e) {
      debugPrint("Error fetching user ID for notifications: $e");
    }
  }

  Future<void> _deleteNotification(int id) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .eq('notification_id', id);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Notification removed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return NetworkErrorState(
              message: isNetworkError(snapshot.error)
                  ? 'Unable to load notifications.'
                  : 'Error: ${snapshot.error}',
              onRetry: _setupStream,
            );
          }
          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 64, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(
                    "No notifications yet",
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _setupStream();
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final id = notif['notification_id'] as int;
                final title = notif['title'] ?? 'Notification';
                final message = notif['message'] ?? '';
                final type = notif['type'] ?? 'General';

                return Dismissible(
                  key: Key(id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: theme.colorScheme.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: Icon(Icons.delete, color: theme.colorScheme.onError),
                  ),
                  onDismissed: (_) {
                    _deleteNotification(id);
                  },
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.2),
                        child: Icon(_getIconForType(type),
                            color: theme.colorScheme.primary),
                      ),
                      title: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(message),
                      trailing: Text(
                        _formatDate(notif['created_at']),
                        style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 10),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'feedback':
        return Icons.chat_bubble_outline;
      case 'offer':
        return Icons.local_offer_outlined;
      case 'purchase':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return '';
    }
  }
}
