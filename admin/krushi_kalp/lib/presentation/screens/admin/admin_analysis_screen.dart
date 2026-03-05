import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:krushi_kalp_admin/presentation/providers/admin_provider.dart';
import 'package:krushi_kalp_admin/data/services/admin_service.dart';
import 'package:krushi_kalp_admin/presentation/widgets/common/network_error_state.dart';
import 'package:krushi_kalp_admin/core/theme/app_colors.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Analytics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: AdminService.streamDashboardStats(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return NetworkErrorState(
              message: isNetworkError(snapshot.error)
                  ? 'Unable to load analytics. Check your connection.'
                  : 'Error: ${snapshot.error}',
              onRetry: () => setState(() {}),
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
                Text(
                  'Overview (Realtime)',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
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
                      Icons.people,
                      AppColors.info,
                      onTap: () => context.read<AdminProvider>().setNavIndex(2),
                    ),
                    _buildStatCard(
                      context,
                      'Revenue',
                      '₹${(stats['revenue'] as double).toStringAsFixed(2)}',
                      Icons.currency_rupee_rounded,
                      Colors.purple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RevenueDetailsScreen()),
                      ),
                    ),
                    _buildStatCard(
                      context,
                      'Mock Tests',
                      '${stats['totalTests']}',
                      Icons.quiz_rounded,
                      Colors.orange,
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
                      AppColors.success,
                    ),
                    _buildStatCard(
                      context,
                      'Active Offers',
                      '${stats['activeOffers']}',
                      Icons.local_offer_rounded,
                      Colors.pink,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const AdminOfferListScreen(showOnlyActive: true),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
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
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.2,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
