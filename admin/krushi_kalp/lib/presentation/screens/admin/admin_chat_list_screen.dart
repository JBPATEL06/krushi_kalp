import 'package:flutter/material.dart';
import 'package:krushi_kalp_admin/core/theme/app_spacing.dart';
import 'package:krushi_kalp_admin/data/services/chat_service.dart';
import 'package:krushi_kalp_admin/presentation/widgets/common/modern_card.dart';
import '../../widgets/common/network_error_state.dart';
import 'admin_chat_detail_screen.dart';

class AdminChatListScreen extends StatefulWidget {
  const AdminChatListScreen({super.key});

  @override
  State<AdminChatListScreen> createState() => _AdminChatListScreenState();
}

class _AdminChatListScreenState extends State<AdminChatListScreen> {
  final ChatService _chatService = ChatService();
  Stream<List<Map<String, dynamic>>>? _conversationsStream;

  @override
  void initState() {
    super.initState();
    _conversationsStream = _chatService.getConversationsStream();
  }

  void _refresh() {
    setState(() {
      _conversationsStream = _chatService.getConversationsStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Inbox'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded,
                color: colorScheme.onSurfaceVariant),
            onPressed: _refresh,
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _conversationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return NetworkErrorState(
              message: isNetworkError(snapshot.error)
                  ? 'Unable to load conversations. Check your connection.'
                  : 'Error: ${snapshot.error}',
              onRetry: _refresh,
            );
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 64,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.3)),
                  const SizedBox(height: AppSpacing.md),
                  Text('No active conversations.',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: conversations.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final chat = conversations[index];
              final username = chat['username'] ?? 'User';
              final firstChar = username.isNotEmpty
                  ? (username as String)[0].toUpperCase()
                  : '?';

              return ModernCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: colorScheme.primary.withOpacity(0.1),
                    child: Text(
                      firstChar,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  title: Text(
                    username,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      chat['email'] ?? 'No Email',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                      size: 20),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminChatDetailScreen(
                          userId: chat['user_id'],
                          userName: chat['username'],
                        ),
                      ),
                    );
                    _refresh();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
