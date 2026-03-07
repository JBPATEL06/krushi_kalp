import 'package:flutter/material.dart';
import '../../../../data/services/admin_service.dart';
import '../../widgets/common/network_error_state.dart';
import 'admin_user_details_screen.dart';
import 'package:krushi_kalp/core/theme/app_spacing.dart';
import 'package:krushi_kalp/core/theme/app_radius.dart';

class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  String _selectedFilter = 'All'; // All, New, Active
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late Stream<List<Map<String, dynamic>>> _usersStream;

  @override
  void initState() {
    super.initState();
    _usersStream = AdminService.streamUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>>? _cachedAllUsers;
  List<Map<String, dynamic>>? _cachedFilteredUsers;
  String? _lastSearch;
  String? _lastFilter;

  List<Map<String, dynamic>> _applyFilters(
      List<Map<String, dynamic>> allUsers) {
    if (identical(allUsers, _cachedAllUsers) &&
        _searchQuery == _lastSearch &&
        _selectedFilter == _lastFilter &&
        _cachedFilteredUsers != null) {
      return _cachedFilteredUsers!;
    }

    final query = _searchQuery.toLowerCase().trim();
    final now = DateTime.now();

    final filtered = allUsers.where((user) {
      final username = (user['username'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      final matchesSearch =
          query.isEmpty || username.contains(query) || email.contains(query);

      if (!matchesSearch) return false;

      if (_selectedFilter == 'New') {
        final createdAtStr = user['created_at'] as String?;
        if (createdAtStr == null) return false;
        final createdAt = DateTime.tryParse(createdAtStr);
        if (createdAt == null) return false;
        return now.difference(createdAt).inDays <= 30;
      } else if (_selectedFilter == 'Active') {
        final lastActiveStr = user['last_active'] as String?;
        if (lastActiveStr == null) return false;
        final lastActive = DateTime.tryParse(lastActiveStr);
        if (lastActive == null) return false;
        return now.difference(lastActive).inDays <= 15;
      }

      return true;
    }).toList();

    _cachedAllUsers = allUsers;
    _cachedFilteredUsers = filtered;
    _lastSearch = _searchQuery;
    _lastFilter = _selectedFilter;

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _usersStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  snapshot.data == null) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return NetworkErrorState(
                  message: isNetworkError(snapshot.error)
                      ? 'Unable to load users. Check your connection.'
                      : 'Error: ${snapshot.error}',
                  onRetry: () => setState(() {
                    _usersStream = AdminService.streamUsers();
                  }),
                );
              }

              final allUsers = snapshot.data ?? [];
              final filteredUsers = _applyFilters(allUsers);

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      border: Border(
                        bottom: BorderSide(color: colorScheme.outlineVariant),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(context, 'SEARCH & FILTER'),
                const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search by name or email...',
                            prefixIcon: Icon(Icons.search_rounded,
                                color: colorScheme.primary),
                            filled: true,
                            fillColor: colorScheme.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md, vertical: 0),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            _buildFilterChip(context, 'All'),
                            const SizedBox(width: AppSpacing.sm),
                            _buildFilterChip(context, 'New'),
                            const SizedBox(width: AppSpacing.sm),
                            _buildFilterChip(context, 'Active'),
                            const Spacer(),
                            Text(
                              '${filteredUsers.length} Users',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filteredUsers.isEmpty
                        ? _buildEmptyState(context)
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              return _buildUserRow(context, user);
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 0.0), // Reduced
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_rounded,
              size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.2)),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No matching users found',
            style: TextStyle(
                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                fontWeight: FontWeight.w500),
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
      onSelected: (bool selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
      backgroundColor: Colors.transparent,
      selectedColor: colorScheme.primary.withOpacity(0.1),
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.3)
              : colorScheme.outline.withOpacity(0.2),
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
          bottom:
              BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminUserDetailsScreen(
                userId: user['id'],
                username: username,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colorScheme.primary.withOpacity(0.08),
                child: Text(
                  firstChar,
                  style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
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
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user['email'] ?? 'No Email',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
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
                  size: 20,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.3)),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 9,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
