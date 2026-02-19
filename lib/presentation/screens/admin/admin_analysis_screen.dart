import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../../data/services/admin_service.dart';
import '../../widgets/common/network_error_state.dart';
import 'admin_offer_list_screen.dart';
import 'admin_store_screen.dart';
import 'revenue_details_screen.dart';
import '../../../../core/theme/app_colors.dart';

class AdminAnalysisScreen extends StatefulWidget {
  const AdminAnalysisScreen({super.key});

  @override
  State<AdminAnalysisScreen> createState() => _AdminAnalysisScreenState();
}

class _AdminAnalysisScreenState extends State<AdminAnalysisScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        // Refresh button is no longer needed for Realtime, but keeping it as a "Reconnect" or just removing it.
        // Let's remove it to imply "It's always up to date".
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overview (Realtime)',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _buildStatCard(
                      'Total Users',
                      '${stats['totalUsers']}',
                      Icons.people,
                      Colors.blue,
                      onTap: () => context.read<AdminProvider>().setNavIndex(2),
                    ),
                    _buildStatCard(
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
                      'Test Sales',
                      '${stats['testSales']}',
                      Icons.shopping_cart_checkout_rounded,
                      Colors.green,
                    ),
                    _buildStatCard(
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
