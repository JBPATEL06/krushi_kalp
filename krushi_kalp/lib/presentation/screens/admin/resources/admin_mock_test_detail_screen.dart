import 'package:flutter/material.dart';
import 'package:krushi_kalp/utils/responsive.dart';
import 'package:krushi_kalp/core/theme/app_spacing.dart';
import 'package:krushi_kalp/core/theme/app_radius.dart';
import 'package:krushi_kalp/data/services/test_service.dart';
import 'package:krushi_kalp/data/services/admin_service.dart';
import 'package:krushi_kalp/domain/models/mock_test.dart';
import 'package:krushi_kalp/utils/supabase_url_helper.dart';
import 'package:krushi_kalp/utils/network_utils.dart';

import '../mock_test_edit_screen.dart';
import '../../../../utils/crashlytics_service.dart';
import '../../../../utils/error_utils.dart';
import '../admin_grant_access_screen.dart' as admin_grant;
import '../admin_user_list_screen.dart' as admin_user_list;

class AdminMockTestDetailScreen extends StatefulWidget {
  final MockTest test;

  const AdminMockTestDetailScreen({super.key, required this.test});

  @override
  State<AdminMockTestDetailScreen> createState() =>
      _AdminMockTestDetailScreenState();
}

class _AdminMockTestDetailScreenState extends State<AdminMockTestDetailScreen> {
  late MockTest _test;
  Map<String, dynamic>? _stats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _test = widget.test;
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await AdminService.getMockTestItemStats(_test.id);
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'admin_mock_test_detail_screen');
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  Future<void> _deleteTest() async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
            'Are you sure you want to delete this mock test? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await TestService.instance.deleteMockTest(_test.id);
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e, stack) {
        CrashlyticsService.instance.recordError(e, stack, reason: 'admin_mock_test_detail_screen');
        if (mounted) {
          ErrorUtils.showError(context, e);
        }
      }
    }
  }

  Future<void> _downloadQuestions() async {
    if (_test.filePath.isEmpty) return;

    try {
      const bucket = 'mock_test';
      final path = SupabaseUrlHelper.extractPathFromUrl(_test.filePath, bucket);
      final signedUrl = await SupabaseUrlHelper().getFreshSignedUrl(bucket, path);
      
      if (signedUrl.isEmpty || !signedUrl.startsWith('http')) {
        throw Exception('File does not exist in Cloud Storage. You may need to re-upload it.');
      }

      await NetworkUtils.downloadAndOpen(
        url: signedUrl,
        fileName: '${_test.title.replaceAll(' ', '_')}.json',
        onStatus: (status) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(status), duration: const Duration(seconds: 1)),
            );
          }
        },
      );
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'admin_mock_test_detail_screen');
      if (mounted) {
        ErrorUtils.showError(context, e);
      }
    }
  }

  void _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MockTestEditScreen(test: _test),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Mock Test Details',
            style: TextStyle(fontSize: context.sp(20))), // FIXED
        actions: [
          IconButton(
            icon: const Icon(Icons.card_giftcard),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => admin_user_list.AdminUserListScreen(
                    isPickerMode: true,
                    onUsersSelected: (users) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => admin_grant.AdminGrantAccessScreen(
                            initialSelectedUsers: users,
                            initialItemContext: admin_grant.AccessItemContext(
                              id: _test.id,
                              title: _test.title,
                              type: 'mock_test',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
            tooltip: 'Gift Access',
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: _navigateToEdit,
            tooltip: 'Edit',
          ),
          IconButton(
            icon: Icon(Icons.delete_rounded, color: colorScheme.error),
            onPressed: _deleteTest,
            tooltip: 'Delete',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail
                  Container(
                    width: context.sp(100), // FIXED
                    height: context.sp(100), // FIXED
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: _test.signedUrl != null && _test.signedUrl!.startsWith('http')
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Image.network(
                              _test.signedUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(Icons.assignment_rounded,
                            size: context.sp(40), // FIXED
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5)),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _test.category.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _test.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: context.sp(24)), // FIXED
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _test.language,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Text(
                              _test.price == 0
                                  ? 'FREE'
                                  : '₹${_test.price.toStringAsFixed(0)}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: _test.price == 0
                                    ? const Color(0xFF10B981)
                                    : colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: context.sp(20), // FIXED
                              ),
                            ),
                            if (_test.mrp != null &&
                                _test.mrp! > _test.price) ...[
                              const SizedBox(width: 8),
                              Text(
                                '₹${_test.mrp!.toStringAsFixed(0)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Key Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildInfoBox(
                    context,
                    label: 'QUESTIONS',
                    value: '${_test.totalQuestions}',
                    icon: Icons.help_outline_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildInfoBox(
                    context,
                    label: 'DURATION',
                    value: _test.time,
                    icon: Icons.timer_outlined,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildInfoBox(
                    context,
                    label: 'TOTAL MARKS',
                    value: '${_test.totalMarks}',
                    icon: Icons.emoji_events_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Performance Stats
            _buildSectionHeader(context, "PERFORMANCE STATS"),
            const SizedBox(height: AppSpacing.sm),
            _buildStatCard(
              context,
              label: 'Total Sales',
              value: _isLoadingStats ? '...' : '${_stats?['salesCount'] ?? 0}',
              icon: Icons.shopping_cart_rounded,
              color: Colors.blue,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Settings Section
            _buildSectionHeader(context, "TEST SETTINGS"),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  _buildSettingRow(
                    context,
                    label: 'Negative Marking',
                    value: _test.negativeMarking ? 'Enabled' : 'Disabled',
                    icon: Icons.remove_circle_outline_rounded,
                    color: _test.negativeMarking
                        ? Colors.orange
                        : colorScheme.onSurfaceVariant,
                  ),
                  if (_test.negativeMarking) ...[
                    const Divider(height: 1),
                    _buildSettingRow(
                      context,
                      label: 'Marks per Incorrect',
                      value: '-${_test.negativeMarksPerQ}',
                      icon: Icons.trending_down_rounded,
                      color: Colors.red,
                    ),
                  ],
                  const Divider(height: 1),
                  _buildSettingRow(
                    context,
                    label: 'Created On',
                    value: _formatDate(_test.createdAt),
                    icon: Icons.calendar_today_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Content Files section
            _buildSectionHeader(context, "CONTENT FILES"),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: ListTile(
                leading: Icon(Icons.description_outlined,
                    color: colorScheme.primary),
                title: const Text('Questions File (JSON)'),
                subtitle: Text(_test.filePath.split('/').last),
                trailing: IconButton(
                  icon: const Icon(Icons.download_for_offline_outlined),
                  onPressed: _downloadQuestions,
                  color: colorScheme.primary,
                  tooltip: 'Download original JSON',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Description
            _buildSectionHeader(context, "DESCRIPTION"),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Text(
                _test.description.isEmpty
                    ? 'No description provided.'
                    : _test.description,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
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
          fontSize: context.sp(12), // FIXED
        ),
      ),
    );
  }

  Widget _buildInfoBox(BuildContext context,
      {required String label, required String value, required IconData icon}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, size: context.sp(20), color: colorScheme.primary), // FIXED
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold, fontSize: context.sp(16)), // FIXED
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: context.sp(8), // FIXED
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: context.sp(24)), // FIXED
          ),
          const SizedBox(width: AppSpacing.lg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: context.sp(24)), // FIXED
              ),
              Text(
                label,
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(BuildContext context,
      {required String label,
      required String value,
      required IconData icon,
      required Color color}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(icon, size: context.sp(20), color: color), // FIXED
          const SizedBox(width: AppSpacing.md),
          Text(label, style: theme.textTheme.bodyMedium),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
