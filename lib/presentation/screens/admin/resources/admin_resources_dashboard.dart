import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../../../../data/services/admin_service.dart';
import '../../../../presentation/providers/admin_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/models/resource.dart';
import 'admin_resource_list.dart';
import '../../../widgets/common/category_card.dart';

import 'admin_generic_resource_screen.dart';

class AdminResourcesDashboard extends StatelessWidget {
  const AdminResourcesDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Resources'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.5,
          children: [
            CategoryCard(
              title: 'Current Affairs',
              icon: Icons.newspaper,
              color: Colors.deepOrange,
              onTap: () => _navigateTo(
                context,
                'Current Affairs',
                const AdminResourceList(type: ResourceType.currentAffair),
              ),
              onLongPress: () =>
                  _showTypeStats(context, 'current_affair', 'Current Affairs'),
            ),
            CategoryCard(
              title: 'Test Series',
              icon: Icons.quiz_outlined,
              color: Colors.blue,
              onTap: () {
                // Navigate to Admin Store Tab (Index 1)
                Navigator.pop(context); // Close dashboard
                context.read<AdminProvider>().setNavIndex(1);
              },
              onLongPress: () =>
                  _showTypeStats(context, 'test_series', 'Test Series'),
            ),
            CategoryCard(
              title: 'E-Books',
              icon: Icons.menu_book_rounded,
              color: Colors.green,
              onTap: () => _navigateTo(
                context,
                'E-Books',
                const AdminResourceList(type: ResourceType.eBook),
              ),
              onLongPress: () => _showTypeStats(context, 'ebook', 'E-Books'),
            ),
            CategoryCard(
              title: 'Study Material',
              icon: Icons.description_rounded,
              color: Colors.purple,
              onTap: () => _navigateTo(
                context,
                'Study Material',
                const AdminResourceList(type: ResourceType.studyMaterial),
              ),
              onLongPress: () =>
                  _showTypeStats(context, 'study_material', 'Study Material'),
            ),
            CategoryCard(
              title: 'PYQs',
              icon: Icons.history_edu_rounded,
              color: Colors.red,
              onTap: () => _navigateTo(
                context,
                'PYQs',
                const AdminResourceList(type: ResourceType.pyq),
              ),
              onLongPress: () => _showTypeStats(context, 'pyq', 'PYQs'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTypeStats(BuildContext context, String type, String title) async {
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
          title: Text('$title Analytics'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatRow('Total Inventory', '${stats['totalCount']} Items'),
              const Divider(),
              _buildStatRow('Total Sold', '${stats['salesCount']} Units'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blue)),
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
