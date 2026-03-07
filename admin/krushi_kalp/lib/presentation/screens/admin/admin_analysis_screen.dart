import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:krushi_kalp_admin/presentation/providers/admin_provider.dart';
import 'package:krushi_kalp_admin/data/services/admin_service.dart';
import 'package:krushi_kalp_admin/presentation/widgets/common/network_error_state.dart';
import 'package:krushi_kalp_admin/core/theme/app_spacing.dart';
import 'package:krushi_kalp_admin/presentation/widgets/common/modern_card.dart';
import 'admin_offer_list_screen.dart';
import 'admin_store_screen.dart';
import 'revenue_details_screen.dart';

class AdminAnalysisScreen extends StatefulWidget {
  const AdminAnalysisScreen({super.key});

  @override
  State<AdminAnalysisScreen> createState() => _AdminAnalysisScreenState();
}

class _AdminAnalysisScreenState extends State<AdminAnalysisScreen> {
  late Stream<Map<String, dynamic>> _statsStream;

  @override
  void initState() {
    super.initState();
    _statsStream = AdminService.streamDashboardStats();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _statsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return NetworkErrorState(
              message: isNetworkError(snapshot.error)
                  ? 'Unable to load analytics. Check your connection.'
                  : 'Error: ${snapshot.error}',
              onRetry: () => setState(() {
                _statsStream = AdminService.streamDashboardStats();
              }),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = snapshot.data ??
              {
                'totalTests': 0,
                'totalResources': 0,
                'totalUsers': 0,
                'testSales': 0,
                'resourceSales': 0,
                'revenue': 0.0,
                'activeOffers': 0,
              };

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context, 'REVENUE & USERS'),
                const SizedBox(height: AppSpacing.md),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.1,
                  children: [
                    _buildStatCard(
                      context,
                      'Total Users',
                      '${stats['totalUsers']}',
                      Icons.people_rounded,
                      const Color(0xFF3B82F6), // Blue
                      onTap: () => context.read<AdminProvider>().setNavIndex(2),
                    ),
                    _buildStatCard(
                      context,
                      'Revenue',
                      '₹${(stats['revenue'] as double).toStringAsFixed(0)}',
                      Icons.payments_rounded,
                      const Color(0xFF10B981), // Emerald
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RevenueDetailsScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                _buildSectionHeader(context, 'CONTENT METRICS'),
                const SizedBox(height: AppSpacing.md),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.1,
                  children: [
                    _buildStatCard(
                      context,
                      'Mock Tests',
                      '${stats['totalTests']}',
                      Icons.quiz_rounded,
                      const Color(0xFFF59E0B), // Amber
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminStoreScreen()),
                      ),
                    ),
                    _buildStatCard(
                      context,
                      'Test Sales',
                      '${stats['testSales']}',
                      Icons.shopping_cart_checkout_rounded,
                      const Color(0xFF6366F1), // Indigo
                    ),
                    _buildStatCard(
                      context,
                      'Active Offers',
                      '${stats['activeOffers']}',
                      Icons.local_offer_rounded,
                      const Color(0xFFA855F7), // Purple
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const AdminOfferListScreen(showOnlyActive: true),
                        ),
                      ),
                    ),
                    _buildStatCard(
                      context,
                      'Resources',
                      '${stats['totalResources']}',
                      Icons.library_books_rounded,
                      const Color(0xFF2DD4BF), // Teal
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Text(
      title,
      style: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: colorScheme.onSurfaceVariant,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
