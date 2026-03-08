import 'package:flutter/material.dart';
import 'package:krushi_kalp/utils/responsive.dart';
import 'package:krushi_kalp/core/theme/app_radius.dart';
import '../../../../data/services/resource_service.dart';
import '../../../../domain/models/resource.dart';
import 'package:krushi_kalp/core/theme/app_spacing.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../pdf_viewer_screen.dart';
import 'admin_resource_form.dart';
import 'admin_resource_detail_screen.dart';
import '../../../../../utils/error_utils.dart';
import '../../../utils/ui_helpers.dart';

class AdminResourceList extends StatefulWidget {
  final ResourceType type;

  const AdminResourceList({super.key, required this.type});

  @override
  State<AdminResourceList> createState() => _AdminResourceListState();
}

class _AdminResourceListState extends State<AdminResourceList> {
  final ResourceService _resourceService = ResourceService.instance;
  late Future<List<Resource>> _futureResources;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _futureResources =
        _resourceService.fetchResources(type: widget.type, isAdmin: true);
  }

  Future<void> _refresh() async {
    setState(() {
      _loadData();
    });
  }

  Future<void> _deleteResource(int id) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      title: 'Delete Item',
      content: const Text(
          'Are you sure you want to delete this item? This cannot be undone.'),
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        await _resourceService.deleteResource(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Item deleted successfully')));
          _refresh();
        }
      } catch (e) {
        if (mounted) {
          ErrorUtils.showError(context, e);
        }
      }
    }
  }

  void _navigateToForm([Resource? resource]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminResourceForm(
          type: widget.type,
          resource: resource,
        ),
      ),
    );

    if (result == true) {
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        elevation: 2,
        child: const Icon(Icons.add_rounded),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: colorScheme.primary,
        child: FutureBuilder<List<Resource>>(
          future: _futureResources,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        color: colorScheme.error,
                        size: context.sp(48)), // FIXED
                    const SizedBox(height: AppSpacing.md),
                    Text('Something went wrong. Please try again.',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }

            final items = snapshot.data!;
            return ListView.builder(
              padding: EdgeInsets.only(
                top: AppSpacing.md,
                bottom: AppSpacing.md + MediaQuery.of(context).padding.bottom,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _buildResourceRow(context, items[index]);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildResourceRow(BuildContext context, Resource item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminResourceDetailScreen(resource: item),
            ),
          );
          if (result == true) {
            _refresh();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5))),
          ),
          child: Row(
            children: [
              // Thumbnail/Icon
              Container(
                width: context.sp(48), // FIXED
                height: context.sp(48), // FIXED
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: item.thumbnailUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                              Icons.image_not_supported_rounded,
                              size: context.sp(20), // FIXED
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5)),
                        ),
                      )
                    : Icon(Icons.insert_drive_file_rounded,
                        size: context.sp(24), // FIXED
                        color: colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5)),
              ),
              const SizedBox(width: AppSpacing.md),
              // Name and Category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: context.sp(14)), // FIXED
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (item.category != null) ...[
                          Text(
                            item.category!.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: context.sp(9), // FIXED
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                  color: colorScheme.outline,
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          item.isActive ? "Visible" : "Hidden",
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: item.isActive
                                ? const Color(0xFF10B981)
                                : colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.5),
                            fontWeight: FontWeight.bold,
                            fontSize: context.sp(10), // FIXED
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.fileUrl != null &&
                      item.fileUrl!.toLowerCase().endsWith('.pdf')) ...[
                    _buildActionIcon(
                      icon: Icons.visibility_rounded,
                      onPressed: () => _viewPdf(item.fileUrl!, item.title),
                      tooltip: "View PDF",
                    ),
                    const SizedBox(width: 8),
                    _buildActionIcon(
                      icon: Icons.download_rounded,
                      onPressed: () =>
                          _downloadAndSharePdf(item.fileUrl!, item.title),
                      tooltip: "Share PDF",
                      color: const Color(0xFF10B981),
                    ),
                  ],
                  const SizedBox(width: 8),
                  _buildActionIcon(
                    icon: Icons.edit_rounded,
                    onPressed: () => _navigateToForm(item),
                    tooltip: "Edit details",
                  ),
                  const SizedBox(width: 8),
                  _buildActionIcon(
                    icon: Icons.delete_rounded,
                    onPressed: () => _deleteResource(item.id),
                    color: colorScheme.error,
                    tooltip: "Delete",
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
    required String tooltip,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(context.sp(8)), // FIXED
          decoration: BoxDecoration(
            color: (color ?? colorScheme.primary).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.sm), // FIXED
          ),
          child: Icon(icon,
              color: color ?? colorScheme.primary,
              size: context.sp(18)), // FIXED
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: context.sp(64), // FIXED
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: AppSpacing.md),
          Text('No items found. Add one!',
              style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: context.sp(14))), // FIXED
        ],
      ),
    );
  }

  Future<void> _viewPdf(String url, String title) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      final HttpClient httpClient = HttpClient();
      final HttpClientRequest request = await httpClient.getUrl(Uri.parse(url));
      final HttpClientResponse response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Failed to download: HTTP ${response.statusCode}');
      }

      final Uint8List bytes =
          await consolidateHttpClientResponseBytes(response);
      final dir = await getTemporaryDirectory();
      final fileName = title.replaceAll(' ', '_');
      final file = File('${dir.path}/$fileName.pdf');
      await file.writeAsBytes(bytes);

      if (mounted) {
        Navigator.pop(context); // Close loader
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewerScreen(file: file, title: title),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loader
        ErrorUtils.showError(context, e);
      }
    }
  }

  Future<void> _downloadAndSharePdf(String url, String title) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      final HttpClient httpClient = HttpClient();
      final HttpClientRequest request = await httpClient.getUrl(Uri.parse(url));
      final HttpClientResponse response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Failed to download: HTTP ${response.statusCode}');
      }

      final Uint8List bytes =
          await consolidateHttpClientResponseBytes(response);
      final dir = await getTemporaryDirectory();
      final fileName = title.replaceAll(' ', '_');
      final file = File('${dir.path}/$fileName.pdf');
      await file.writeAsBytes(bytes);

      if (mounted) {
        Navigator.pop(context); // Close loader
        final xFile = XFile(file.path,
            name: '$fileName.pdf', mimeType: 'application/pdf');
        await Share.shareXFiles([xFile], text: 'Download PDF: $title');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loader
        ErrorUtils.showError(context, e);
      }
    }
  }
}
