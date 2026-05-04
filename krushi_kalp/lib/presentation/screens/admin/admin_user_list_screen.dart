import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:krushi_kalp/utils/responsive.dart';
import '../../../../data/services/admin_service.dart';
import '../../widgets/common/network_error_state.dart';
import 'admin_user_details_screen.dart';
import 'package:krushi_kalp/core/theme/app_spacing.dart';
import 'package:krushi_kalp/core/theme/app_radius.dart';
import '../../widgets/common/debounced_search_bar.dart';

class AdminUserListScreen extends StatefulWidget {
  final void Function(String userId, String username)? onUserSelected;

  const AdminUserListScreen({
    super.key,
    this.onUserSelected,
  });


  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  static const _pageSize = 20;

  final PagingController<int, Map<String, dynamic>> _pagingController =
      PagingController(firstPageKey: 0);

  String _selectedFilter = 'All'; // All, New, Active
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems = await AdminService.getPaginatedUsers(
        offset: pageKey,
        limit: _pageSize,
        searchQuery: _searchQuery,
        statusFilter: _selectedFilter,
      );

      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  void _updateSearch(String query) {
    _searchQuery = query;
    _pagingController.refresh();
  }

  void _updateFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _pagingController.refresh();
  }

  @override
  void dispose() {
    _pagingController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(context, widget.onUserSelected != null ? "SELECT USER FOR GIFT" : "USER DIRECTORY"),
                    const SizedBox(height: AppSpacing.md),
                    _buildSearchBar(context, theme),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        _buildFilterChip(context, 'All'),
                        const SizedBox(width: AppSpacing.sm),
                        _buildFilterChip(context, 'New'),
                        const SizedBox(width: AppSpacing.sm),
                        _buildFilterChip(context, 'Active'),
                        const Spacer(),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _pagingController.refresh(),
                  child: PagedListView<int, Map<String, dynamic>>(
                    pagingController: _pagingController,
                    padding: EdgeInsets.only(
                      top: AppSpacing.sm,
                      bottom: MediaQuery.of(context).padding.bottom,
                    ),
                    builderDelegate: PagedChildBuilderDelegate<Map<String, dynamic>>(
                      itemBuilder: (context, user, index) => _buildUserRow(context, user),
                      firstPageErrorIndicatorBuilder: (context) => NetworkErrorState(
                        message: 'Failed to load users',
                        onRetry: () => _pagingController.refresh(),
                      ),
                      noItemsFoundIndicatorBuilder: (context) => _buildEmptyState(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: colorScheme.onSurfaceVariant,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, ThemeData theme) {
    return DebouncedSearchBar(
      hintText: 'Search by username or email...',
      controller: _searchController,
      onChanged: _updateSearch,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_rounded,
              size: context.sp(64), // FIXED
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No matching users found',
            style: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
                fontSize: context.sp(16)), // FIXED
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) => _updateFilter(label),
      backgroundColor: Colors.transparent,
      selectedColor: colorScheme.primary.withValues(alpha: 0.1),
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: context.sp(14), // FIXED
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildUserRow(BuildContext context, Map<String, dynamic> user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final username = user['username'] ?? 'Unknown';
    final firstChar = username.isNotEmpty ? username[0].toUpperCase() : '?';

    bool isNew = false;
    if (user['created_at'] != null) {
      final createdAt = DateTime.tryParse(user['created_at']);
      if (createdAt != null) {
        isNew = DateTime.now().difference(createdAt).inDays <= 30;
      }
    }

    bool isActive = false;
    if (user['last_active'] != null) {
      final lastActive = DateTime.tryParse(user['last_active']);
      if (lastActive != null) {
        isActive = DateTime.now().difference(lastActive).inDays <= 15;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: InkWell(
        onTap: () {
          if (widget.onUserSelected != null) {
            widget.onUserSelected!(user['id'], username);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminUserDetailsScreen(
                  userId: user['id'],
                  username: username,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                radius: context.sp(24), // FIXED
                backgroundColor: colorScheme.primary.withValues(alpha: 0.08),
                child: Text(
                  firstChar,
                  style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: context.sp(18)), // FIXED
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                        fontSize: context.sp(16), // FIXED
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user['email'] ?? 'No Email',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: context.sp(12), // FIXED
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              if (isNew || isActive)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isNew)
                      _buildStatusBadge(
                          context, 'NEW', const Color(0xFFA855F7)),
                    if (isNew && isActive) const SizedBox(width: 4),
                    if (isActive)
                      _buildStatusBadge(
                          context, 'ACTIVE', const Color(0xFF10B981)),
                  ],
                ),
              const SizedBox(width: AppSpacing.md),
              Icon(Icons.chevron_right_rounded,
                  size: context.sp(20), // FIXED
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: context.sp(9), // FIXED
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}


