import 'package:flutter/material.dart';
import 'package:krushi_kalp/utils/responsive.dart';
import '../../../../data/services/admin_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../domain/models/resource.dart';
import 'admin_resource_list.dart';
import '../../../widgets/common/category_card.dart';
import 'admin_generic_resource_screen.dart';
import '../admin_store_screen.dart'; // CHANGED

class AdminResourcesDashboard extends StatelessWidget {
  const AdminResourcesDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Manage Resources',
            style: TextStyle(fontSize: context.sp(20))), // FIXED
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 1200
            ? 5
            : width > 900
                ? 4
                : width > 600
                    ? 3
                    : 2;

        return RefreshIndicator(
          onRefresh: () async {
            // Dashboard is a menu, but we keep refresh for consistency/animation
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: width > 600 ? 1.5 : 1.1,
                  children: [
                    CategoryCard(
                      title: 'Current Affairs',
                      icon: Icons.newspaper_rounded,
                      color: const Color(0xFFF97316), // Premium Orange
                      onTap: () => _navigateTo(
                        context,
                        'Current Affairs',
                        const AdminResourceList(
                            type: ResourceType.currentAffair),
                      ),
                      onLongPress: () => _showTypeStats(
                          context, 'current_affair', 'Current Affairs'),
                    ),
                    CategoryCard(
                      title: 'Quiz & Tests',
                      icon: Icons.quiz_rounded,
                      color: const Color(0xFF3B82F6), // Premium Blue
                      onTap: () {
                        // Navigate to Admin Store screen // CHANGED
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AdminStoreScreen()),
                        );
                      },
                      onLongPress: () =>
                          _showTypeStats(context, 'test_series', 'Test Series'),
                    ),
                    CategoryCard(
                      title: 'E-Books',
                      icon: Icons.menu_book_rounded,
                      color: const Color(0xFF10B981), // Premium Green
                      onTap: () => _navigateTo(
                        context,
                        'E-Books',
                        const AdminResourceList(type: ResourceType.eBook),
                      ),
                      onLongPress: () =>
                          _showTypeStats(context, 'ebook', 'E-Books'),
                    ),
                    CategoryCard(
                      title: 'Study Material',
                      icon: Icons.description_rounded,
                      color: const Color(0xFF8B5CF6), // Premium Purple
                      onTap: () => _navigateTo(
                        context,
                        'Study Material',
                        const AdminResourceList(
                            type: ResourceType.studyMaterial),
                      ),
                      onLongPress: () => _showTypeStats(
                          context, 'study_material', 'Study Material'),
                    ),
                    CategoryCard(
                      title: 'PYQs',
                      icon: Icons.history_edu_rounded,
                      color: const Color(0xFFEF4444), // Premium Red
                      onTap: () => _navigateTo(
                        context,
                        'PYQs',
                        const AdminResourceList(type: ResourceType.pyq),
                      ),
                      onLongPress: () => _showTypeStats(context, 'pyq', 'PYQs'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  void _showTypeStats(BuildContext context, String type, String title) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final stats = await AdminService.getResourceTypeStats(type);

    if (context.mounted) {
      Navigator.pop(context); // Close loader
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: Text('$title Analytics',
              style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: context.sp(20))), // FIXED
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatRow(
                  context, 'Total Inventory', '${stats['totalCount']} Items'),
              const Divider(height: 24),
              _buildStatRow(
                  context, 'Total Sold', '${stats['salesCount']} Units'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close',
                  style: TextStyle(
                      color: colorScheme.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStatRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: context.sp(14))), // FIXED
          Text(value,
              style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  fontSize: context.sp(16))), // FIXED
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, String title, Widget child) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminGenericResourceScreen(
          title: title,
          child: child,
        ),
      ),
    );
  }
}
