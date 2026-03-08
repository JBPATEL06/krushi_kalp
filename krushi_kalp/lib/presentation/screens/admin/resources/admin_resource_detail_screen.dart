import 'dart:io';
import 'package:flutter/material.dart';
import 'package:krushi_kalp/utils/responsive.dart';
import 'package:flutter/foundation.dart';
import 'package:krushi_kalp/core/theme/app_spacing.dart';
import 'package:krushi_kalp/core/theme/app_radius.dart';
import 'package:krushi_kalp/data/services/resource_service.dart';
import 'package:krushi_kalp/data/services/admin_service.dart';
import 'package:krushi_kalp/domain/models/resource.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:krushi_kalp/presentation/screens/pdf_viewer_screen.dart';
import 'admin_resource_form.dart';
import '../../../../utils/error_utils.dart';

class AdminResourceDetailScreen extends StatefulWidget {
  final Resource resource;

  const AdminResourceDetailScreen({super.key, required this.resource});

  @override
  State<AdminResourceDetailScreen> createState() =>
      _AdminResourceDetailScreenState();
}

class _AdminResourceDetailScreenState extends State<AdminResourceDetailScreen> {
  final ResourceService _resourceService = ResourceService.instance;
  late Resource _resource;
  Map<String, dynamic>? _stats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _resource = widget.resource;
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await AdminService.getResourceItemStats(_resource.id);
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  Future<void> _deleteResource() async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this item?'),
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
        await _resourceService.deleteResource(_resource.id);
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ErrorUtils.showError(context, e);
        }
      }
    }
  }

  void _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminResourceForm(
          type: _resource.type,
          resource: _resource,
        ),
      ),
    );

    if (result == true) {
      final updated = await _resourceService.getResourceById(_resource.id);
      if (updated != null && mounted) {
        setState(() {
          _resource = updated;
        });
        _loadStats();
      }
    }
  }

  Future<void> _handlePdfAction({bool isDownload = false}) async {
    if (_resource.fileUrl == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      final HttpClient httpClient = HttpClient();
      final HttpClientRequest request =
          await httpClient.getUrl(Uri.parse(_resource.fileUrl!));
      final HttpClientResponse response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch file: HTTP ${response.statusCode}');
      }

      final Uint8List bytes =
          await consolidateHttpClientResponseBytes(response);
      final dir = await getTemporaryDirectory();
      final fileName = _resource.title.replaceAll(' ', '_');
      final file = File('${dir.path}/$fileName.pdf');
      await file.writeAsBytes(bytes);

      if (mounted) {
        Navigator.pop(context); // Close loader

        if (isDownload) {
          final xFile = XFile(file.path,
              name: '$fileName.pdf', mimeType: 'application/pdf');
          await Share.shareXFiles([xFile],
              text: 'Download PDF: ${_resource.title}');
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PdfViewerScreen(file: file, title: _resource.title),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorUtils.showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Resource Details',
            style: TextStyle(fontSize: context.sp(20))), // FIXED
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: _navigateToEdit,
            tooltip: 'Edit',
          ),
          IconButton(
            icon: Icon(Icons.delete_rounded, color: colorScheme.error),
            onPressed: _deleteResource,
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
                    height: context.sp(140), // FIXED
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: _resource.thumbnailUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Image.network(
                              _resource.thumbnailUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(Icons.insert_drive_file_rounded,
                            size: context.sp(48), // FIXED
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
                            _resource.type.name.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _resource.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: context.sp(24)), // FIXED
                        ),
                        if (_resource.category != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _resource.category!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Text(
                              '₹${_resource.price.toStringAsFixed(0)}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: context.sp(20), // FIXED
                              ),
                            ),
                            if (_resource.mrp != null &&
                                _resource.mrp! > _resource.price) ...[
                              const SizedBox(width: 8),
                              Text(
                                '₹${_resource.mrp!.toStringAsFixed(0)}',
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

            // Statistics Section
            _buildSectionHeader(context, "PERFORMANCE STATS"),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    label: 'Total Sales',
                    value: _isLoadingStats
                        ? '...'
                        : '${_stats?['salesCount'] ?? 0}',
                    icon: Icons.shopping_cart_rounded,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildStatCard(
                    context,
                    label: 'Visibility',
                    value: _resource.isActive ? 'Visible' : 'Hidden',
                    icon: _resource.isActive
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: _resource.isActive
                        ? const Color(0xFF10B981)
                        : Colors.orange,
                  ),
                ),
              ],
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
                _resource.description ?? 'No description provided.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Actions Section
            _buildSectionHeader(context, "ACTIONS"),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handlePdfAction(isDownload: false),
                    icon: const Icon(Icons.visibility_rounded),
                    label: Text('VIEW PDF',
                        style: TextStyle(fontSize: context.sp(14))), // FIXED
                    style: ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handlePdfAction(isDownload: true),
                    icon: const Icon(Icons.share_rounded),
                    label: Text('SHARE',
                        style: TextStyle(fontSize: context.sp(14))), // FIXED
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    ),
                  ),
                ),
              ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: context.sp(20)), // FIXED
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold, fontSize: context.sp(20)), // FIXED
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
