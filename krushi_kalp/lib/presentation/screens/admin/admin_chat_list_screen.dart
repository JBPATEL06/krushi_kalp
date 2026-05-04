import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krushi_kalp/core/theme/app_spacing.dart';
import 'package:krushi_kalp/data/services/chat_service.dart';
import 'package:krushi_kalp/presentation/widgets/common/modern_card.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '../../../utils/crashlytics_service.dart';
import 'admin_chat_detail_screen.dart';

class AdminChatListScreen extends ConsumerStatefulWidget {
  const AdminChatListScreen({super.key});

  @override
  ConsumerState<AdminChatListScreen> createState() => _AdminChatListScreenState();
}

class _AdminChatListScreenState extends ConsumerState<AdminChatListScreen> {
  static const _pageSize = 20;
  final PagingController<int, Map<String, dynamic>> _pagingController =
      PagingController(firstPageKey: 0);

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems = await ChatService.instance.getPaginatedConversations(
        offset: pageKey,
        limit: _pageSize,
      );

      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error, stack) {
      CrashlyticsService.instance.recordError(error, stack, reason: 'admin_chat_list_fetch');
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                  onPressed: () => _pagingController.refresh(),
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
            child: RefreshIndicator(
              onRefresh: () async => _pagingController.refresh(),
              child: PagedListView<int, Map<String, dynamic>>.separated(
                pagingController: _pagingController,
                padding: EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  top: AppSpacing.md,
                  bottom: AppSpacing.md +
                      MediaQuery.of(context).padding.bottom,
                ),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.md),
                builderDelegate: PagedChildBuilderDelegate<Map<String, dynamic>>(
                  itemBuilder: (context, chat, index) {
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
                          _pagingController.refresh();
                        },
                      ),
                    );
                  },
                  firstPageProgressIndicatorBuilder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                  newPageProgressIndicatorBuilder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                  noItemsFoundIndicatorBuilder: (_) => _buildEmptyState(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 48, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'No conversations found',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
