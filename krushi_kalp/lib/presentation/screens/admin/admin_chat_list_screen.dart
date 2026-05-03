import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krushi_kalp/presentation/providers/admin_notifier.dart';
import 'package:krushi_kalp/core/theme/app_spacing.dart';
import 'package:krushi_kalp/data/services/chat_service.dart';
import 'package:krushi_kalp/presentation/widgets/common/modern_card.dart';
import '../../widgets/common/network_error_state.dart';
import 'admin_chat_detail_screen.dart';

class AdminChatListScreen extends ConsumerStatefulWidget {
  const AdminChatListScreen({super.key});

  @override
  ConsumerState<AdminChatListScreen> createState() => _AdminChatListScreenState();
}

class _AdminChatListScreenState extends ConsumerState<AdminChatListScreen> {
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final adminState = ref.watch(adminProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CONVERSATIONS',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => ref.read(adminProvider.notifier).triggerRefresh(),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh'),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    textStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              key: ValueKey('inbox_stream_${adminState.refreshCounter}'),
              stream: _chatService.getConversationsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return NetworkErrorState(
                    message: isNetworkError(snapshot.error)
                        ? 'Unable to load conversations. Check connection.'
                        : 'Something went wrong.',
                    onRetry: () => ref.read(adminProvider.notifier).triggerRefresh(),
                  );
                }

                final conversations = snapshot.data ?? [];

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.read(adminProvider.notifier).triggerRefresh();
                    await Future.delayed(const Duration(milliseconds: 600));
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      left: AppSpacing.md,
                      right: AppSpacing.md,
                      top: AppSpacing.md,
                      bottom: AppSpacing.md +
                          MediaQuery.of(context).padding.bottom,
                    ),
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
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.sm),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                colorScheme.primary.withValues(alpha: 0.1),
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
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant),
                            ),
                          ),
                          trailing: Icon(Icons.chevron_right_rounded,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
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
                            ref.read(adminProvider.notifier).triggerRefresh();
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
