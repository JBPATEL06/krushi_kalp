import 'package:flutter/material.dart';
import 'package:krushi_kalp/utils/responsive.dart';
import 'package:krushi_kalp/data/services/admin_service.dart';
import 'package:krushi_kalp/core/theme/app_spacing.dart';
import 'package:krushi_kalp/core/theme/app_radius.dart';
import 'package:krushi_kalp/presentation/widgets/common/modern_card.dart';
import 'package:krushi_kalp/data/services/performance_service.dart';
import 'package:krushi_kalp/presentation/widgets/admin_performance_card.dart';

import 'admin_offer_list_screen.dart';
import 'resources/admin_resources_dashboard.dart';
import 'admin_store_screen.dart';
import 'admin_reviews_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late Stream<List<Map<String, dynamic>>> _topTestsStream;
  late Stream<List<Map<String, dynamic>>> _topUsersStream;
  Future<Map<String, dynamic>>? _adminPerformanceFuture;
  Key _refreshKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _adminPerformanceFuture = PerformanceService.instance.getAdminPerformance();
    _initStreams();
  }

  void _initStreams() {
    _topTestsStream = AdminService.streamTopTests();
    _topUsersStream = AdminService.streamTopUsers();
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _initStreams();
        _adminPerformanceFuture =
            PerformanceService.instance.getAdminPerformance();
        _refreshKey = UniqueKey();
      });
    }
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon,
                    color: color,
                    size: context.sp(36)), // FIXED: context.sp(36)
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        displacement: context.h(20), // FIXED: context.h(20)
        color: colorScheme.primary,
        backgroundColor: theme.scaffoldBackgroundColor,
        child: LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth;
          final crossAxisCount = width > 1400
              ? 6
              : width > 1024
                  ? 4
                  : width > 700
                      ? 3
                      : 2;

          return SingleChildScrollView(
            key: _refreshKey,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<Map<String, dynamic>>(
                  future: _adminPerformanceFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: AdminPerformanceCard(
                            data: const {}, isLoading: true),
                      );
                    }
                    if (!snapshot.hasData ||
                        snapshot.hasError ||
                        snapshot.data!.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: AdminPerformanceCard(data: snapshot.data!),
                    );
                  },
                ),
                _buildSectionHeader(context, 'MANAGEMENT QUICK ACCESS'),
                const SizedBox(height: AppSpacing.sm),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio:
                      width > 1024 ? 2.0 : (width > 700 ? 1.5 : 1.3),
                  children: [
                    _buildDashboardCard(
                      context,
                      title: 'Store',
                      icon: Icons.storefront_rounded,
                      color: const Color(0xFF3B82F6),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminStoreScreen()),
                      ),
                    ),
                    _buildDashboardCard(
                      context,
                      title: 'Offers',
                      icon: Icons.local_offer_rounded,
                      color: const Color(0xFFA855F7),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminOfferListScreen()),
                      ),
                    ),
                    _buildDashboardCard(
                      context,
                      title: 'Resources',
                      icon: Icons.library_books_rounded,
                      color: const Color(0xFF6366F1),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminResourcesDashboard()),
                      ),
                    ),
                    _buildDashboardCard(
                      context,
                      title: 'Reviews',
                      icon: Icons.rate_review_rounded,
                      color: const Color(0xFFF59E0B),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminReviewsScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildSectionHeader(context, 'TOP PERFORMING TESTS'),
                const SizedBox(height: AppSpacing.sm),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _topTestsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _LoadingState();
                    }
                    if (snapshot.hasError) {
                      return _buildErrorState(context, "Something went wrong.");
                    }
                    final tests = snapshot.data ?? [];
                    return _buildTopTestsList(context, tests, width);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildSectionHeader(context, 'TOP RANKED USERS'),
                const SizedBox(height: AppSpacing.sm),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _topUsersStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _LoadingState();
                    }
                    if (snapshot.hasError) {
                      return _buildErrorState(context, "Something went wrong.");
                    }
                    final users = snapshot.data ?? [];
                    return _buildTopUsersList(users, width);
                  },
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding:
          const EdgeInsets.only(bottom: AppSpacing.xs), // FIXED: AppSpacing.xs
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
          fontSize: context.sp(12), // FIXED: context.sp(12)
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return ModernCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: colorScheme.error),
            const SizedBox(width: AppSpacing.sm),
            Text(message, style: TextStyle(color: colorScheme.error)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTestsList(
      BuildContext context, List<Map<String, dynamic>> tests, double width) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculate dynamic height based on orientation and screen size
    final listHeight =
        width > 1024 ? context.h(300.0) : context.h(260.0); // FIXED
    final itemWidth = width > 1024 ? width * 0.2 : width * 0.45;

    if (tests.isEmpty) {
      return ModernCard(
        height: context.h(150), // FIXED
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bar_chart_rounded,
                  size: context.sp(40), // FIXED
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
              const SizedBox(height: AppSpacing.sm),
              Text('No data yet',
                  style: TextStyle(
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.5))),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: listHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tests.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final test = tests[index];
          return Container(
            width: itemWidth,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppRadius.lg)),
                    child: test['image_url'] != null
                        ? Image.network(
                            test['image_url'],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                child: Center(
                                  child: Icon(Icons.broken_image_rounded,
                                      color: colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.3)),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: colorScheme.primary.withValues(alpha: 0.05),
                            child: Center(
                              child: Icon(Icons.book_rounded,
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.3),
                                  size: context.sp(40)), // FIXED
                            ),
                          ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          test['title'] ?? 'Untitled',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${test['sales'] ?? 0} Sold',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: context.sp(11), // FIXED
                              ),
                            ),
                            Text(
                              '₹${test['price'] ?? 0}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                                fontSize: context.sp(11), // FIXED
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopUsersList(List<Map<String, dynamic>> users, double width) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLarge = width > 900;

    if (users.isEmpty) {
      return ModernCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Text(
            'No active users found.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final displayUsers = users.take(5).toList();

    Widget userList = Column(
      children: displayUsers.map((user) {
        final totalMax = (user['totalMax'] as num).toDouble();
        final totalScore = (user['totalScore'] as num).toDouble();
        final percentage = totalMax > 0 ? (totalScore / totalMax) * 100 : 0.0;
        final firstChar = (user['username'] as String).isNotEmpty
            ? (user['username'] as String)[0].toUpperCase()
            : '?';

        return ModernCard(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            leading: CircleAvatar(
              radius: context.sp(20), // FIXED
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              child: Text(
                firstChar,
                style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: context.sp(14)), // FIXED
              ),
            ),
            title: Text(
              user['username'],
              style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: context.sp(14)), // FIXED
            ),
            subtitle: Text(
              '${user['testsTaken']} Tests Attempted',
              style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: context.sp(11)), // FIXED
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colorScheme.primary,
                    fontFamily: 'Inter',
                    fontSize: context.sp(16), // FIXED
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.emoji_events_rounded,
                    size: context.sp(18),
                    color: const Color(0xFFF59E0B)), // FIXED
              ],
            ),
          ),
        );
      }).toList(),
    );

    if (isLarge) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: userList),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: ModernCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.insights_rounded,
                      size: context.sp(48),
                      color:
                          colorScheme.primary.withValues(alpha: 0.2)), // FIXED
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'User Performance Metrics',
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: context.sp(16)), // FIXED
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Showing top 5 users based on accuracy and test volume across the platform.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: context.sp(12)), // FIXED
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return userList;
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: CircularProgressIndicator(strokeWidth: context.w(2.5)), // FIXED
      ),
    );
  }
}
