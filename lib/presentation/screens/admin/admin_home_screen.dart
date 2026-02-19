import 'package:flutter/material.dart';
import 'package:krushi_kalp/data/services/admin_service.dart';
import 'package:krushi_kalp/utils/network_utils.dart';
import 'package:krushi_kalp/core/theme/app_colors.dart';
import 'package:krushi_kalp/core/theme/app_spacing.dart';
import 'package:krushi_kalp/presentation/widgets/common/modern_card.dart';

import 'admin_offer_list_screen.dart';
import 'admin_chat_list_screen.dart';
import 'admin_profile_screen.dart';
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
  Key _refreshKey = UniqueKey();

  @override
  void initState() {
    super.initState();
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
    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminProfileScreen()),
            );
          },
          icon: const Icon(Icons.person, color: AppColors.textPrimary),
        ),
        title: Text(
          'Admin Dashboard',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminChatListScreen()),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline_rounded,
                color: AppColors.textPrimary),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        child: SingleChildScrollView(
          key: _refreshKey,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Management',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _buildDashboardCard(
                      context,
                      title: 'Manage Store',
                      icon: Icons.storefront_rounded,
                      color: AppColors.info,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AdminStoreScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildDashboardCard(
                      context,
                      title: 'Manage Offers',
                      icon: Icons.local_offer_rounded,
                      color: Colors.purple, // Kept distinct color
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AdminOfferListScreen())),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _buildDashboardCard(
                      context,
                      title: 'Resources',
                      icon: Icons.library_books,
                      color: Colors.deepPurple, // Kept distinct color
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AdminResourcesDashboard(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildDashboardCard(
                      context,
                      title: 'Reviews',
                      icon: Icons.rate_review,
                      color: AppColors.warning,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminReviewsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Top Tests Stream
              Text(
                'Top Performing Mock Tests',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _topTestsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    if (!NetworkUtils.isNetworkError(snapshot.error)) {
                      debugPrint("Stream Error (Tests): ${snapshot.error}");
                    }
                    return _buildErrorState("Unable to load tests.");
                  }
                  final tests = snapshot.data ?? [];
                  return _buildTopTestsList(tests);
                },
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Top Users Stream
              Text(
                'Top Performing Users',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _topUsersStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    if (!NetworkUtils.isNetworkError(snapshot.error)) {
                      debugPrint("Stream Error (Users): ${snapshot.error}");
                    }
                    return _buildErrorState("Unable to load users.");
                  }
                  final users = snapshot.data ?? [];
                  return _buildTopUsersList(users);
                },
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return ModernCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error),
            const SizedBox(width: AppSpacing.sm),
            Text(message, style: const TextStyle(color: AppColors.error)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTestsList(List<Map<String, dynamic>> tests) {
    if (tests.isEmpty) {
      return const ModernCard(
        height: 150,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bar_chart_rounded,
                  size: 40, color: AppColors.neutral300),
              SizedBox(height: AppSpacing.sm),
              Text('No data yet',
                  style: TextStyle(color: AppColors.neutral400)),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tests.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final test = tests[index];
          return Container(
            width: 180,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.neutral200),
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppSpacing.radiusLg)),
                    child: test['image_url'] != null
                        ? Image.network(
                            test['image_url'],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.neutral100,
                                child: const Center(
                                    child: Icon(Icons.broken_image_rounded,
                                        color: AppColors.neutral400)),
                              );
                            },
                          )
                        : Container(
                            color: AppColors.neutral100,
                            child: const Center(
                                child: Icon(Icons.book,
                                    color: AppColors.primary, size: 40)),
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
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${test['sales'] ?? 0} Sold',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              '₹${test['price'] ?? 0}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
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

  Widget _buildTopUsersList(List<Map<String, dynamic>> users) {
    if (users.isEmpty) {
      return ModernCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Text(
            'No active users found.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final displayUsers = users.take(3).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayUsers.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final user = displayUsers[index];
        final totalMax = user['totalMax'] as double;
        final totalScore = user['totalScore'] as double;
        final percentage = totalMax > 0 ? (totalScore / totalMax) * 100 : 0.0;
        final firstChar = (user['username'] as String).isNotEmpty
            ? (user['username'] as String)[0].toUpperCase()
            : '?';

        return ModernCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                firstChar,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              user['username'],
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const Icon(Icons.emoji_events_rounded,
                    size: 18, color: AppColors.warning),
              ],
            ),
          ),
        );
      },
    );
  }
}
