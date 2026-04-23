import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/notification_service.dart';
import '../../utils/error_utils.dart';
import '../widgets/common/network_error_state.dart';
import '../../utils/crashlytics_service.dart';

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
    final user = AuthService.instance.currentUser;

    if (user != null) {
      // Now using String userId (Auth ID) directly for Firestore
      _notificationsStream = NotificationService().fetchNotificationsStream(user.id);
    } else {
      _notificationsStream = Stream.value([]);
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await NotificationService().deleteNotification(id);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Notification removed')));
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'notifications_screen_delete');
      if (mounted) {
        ErrorUtils.showError(context, e);
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
                  : 'Something went wrong.',
              onRetry: () {
                setState(() {
                  _setupStream();
                });
              },
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
              setState(() {
                _setupStream();
              });
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.separated(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(context).padding.bottom,
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final id = notif['notification_id']?.toString() ?? '';
                final title = notif['title'] ?? 'Notification';
                final message = notif['message'] ?? '';
                final type = notif['type'] ?? 'General';
                final isRead = notif['is_read'] ?? false;

                return Dismissible(
                  key: Key(id),
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
                    elevation: isRead ? 1 : 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      onTap: () {
                        if (!isRead) {
                          NotificationService().markAsRead(id);
                        }
                      },
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.2),
                        child: Icon(_getIconForType(type),
                            color: theme.colorScheme.primary),
                      ),
                      title: Text(
                        title,
                        style: TextStyle(
                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        ),
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
