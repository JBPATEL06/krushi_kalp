import 'dart:io';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'pdf_viewer_screen.dart';
import '../../domain/models/resource.dart';
import '../../domain/models/mock_test.dart';
import 'package:provider/provider.dart';
import '../providers/resource_provider.dart';
import '../providers/test_provider.dart';
import '../../data/services/download_service.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';
import '../utils/exam_helper.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen>
    with WidgetsBindingObserver {
  Map<String, bool> _localStatus = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkDownloads();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDownloads();
    }
  }

  Set<int> _lastTestIds = {};
  Set<int> _lastResourceIds = {};

  Future<void> _checkDownloads() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final resourceProvider = context.read<ResourceProvider>();
    final testProvider = context.read<TestProvider>();

    final myResources = resourceProvider.purchasedResources;
    final myTests = testProvider.userTests;
    final purchasedResourceIds = resourceProvider.purchasedResourceIds;

    _lastTestIds = myTests.map((t) => t.id).toSet();
    _lastResourceIds = purchasedResourceIds;

    final downloadService = DownloadService();

    final resourceChecks =
        myResources.where((r) => r.fileUrl != null).map((r) async {
      final filename = 'resource_${r.id}.pdf';
      final exists = await downloadService.isFileDownloaded(filename);
      return MapEntry<String, bool>('res_${r.id}', exists);
    }).toList();

    final testChecks =
        myTests.where((t) => t.filePath.isNotEmpty).map((t) async {
      final exists =
          await downloadService.isFileDownloaded('mock_test_${t.id}.json');
      return MapEntry<String, bool>('test_${t.id}', exists);
    }).toList();

    final allChecks = [...resourceChecks, ...testChecks];
    final results = await Future.wait(allChecks);
    final newStatus = Map<String, bool>.fromEntries(results);

    if (mounted) {
      setState(() {
        _localStatus = newStatus;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final resourceProvider = context.watch<ResourceProvider>();
    final testProvider = context.watch<TestProvider>();

    final purchasedResourceIds = resourceProvider.purchasedResourceIds;
    final myTests = testProvider.userTests;
    final myResources = resourceProvider.purchasedResources;

    final currentTestIds = myTests.map((t) => t.id).toSet();
    if (!_isLoading &&
        (!SetEquality().equals(_lastTestIds, currentTestIds) ||
            !SetEquality().equals(_lastResourceIds, purchasedResourceIds))) {
      Future.microtask(() => _checkDownloads());
    }

    final displayItems = <dynamic>[];
    for (var r in myResources) {
      if (_localStatus['res_${r.id}'] == true) {
        displayItems.add(r);
      }
    }
    for (var t in myTests) {
      if (_localStatus['test_${t.id}'] == true) {
        displayItems.add(t);
      }
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Column(
          children: [
            const Text("Downloads"),
            if (!_isLoading && displayItems.isNotEmpty)
              Text(
                "${displayItems.length} item${displayItems.length == 1 ? '' : 's'}",
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
          ],
        ),
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        shape: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: _isLoading ? colorScheme.primary : colorScheme.onSurface,
            ),
            onPressed: _isLoading ? null : _checkDownloads,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : displayItems.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.file_download_outlined,
                            size: 56,
                            color:
                                colorScheme.onSurfaceVariant.withOpacity(0.3),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          "No Downloads Yet",
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          "Downloaded resources will appear here\nfor offline access",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: colorScheme.primary,
                  onRefresh: _checkDownloads,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemCount: displayItems.length,
                    itemBuilder: (context, index) {
                      final item = displayItems[index];
                      if (item is Resource) {
                        return _buildResourceCard(context, item);
                      } else if (item is MockTest) {
                        return _buildTestCard(context, item);
                      }
                      return const SizedBox();
                    },
                  ),
                ),
    );
  }

  Widget _buildResourceCard(BuildContext context, Resource resource) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filename = 'resource_${resource.id}.pdf';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outline.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final path = await DownloadService().getLocalPath(filename);
            if (await File(path).exists()) {
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfViewerScreen(
                        file: File(path), title: resource.title),
                  ),
                );
              }
            }
          },
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: resource.thumbnailUrl != null &&
                          resource.thumbnailUrl!.isNotEmpty
                      ? Image.network(
                          resource.thumbnailUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholderIcon(
                              context, Icons.picture_as_pdf_rounded),
                        )
                      : _buildPlaceholderIcon(
                          context, Icons.picture_as_pdf_rounded),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(Icons.folder_outlined,
                              size: 14, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              resource.category ?? resource.type.name,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.open_in_new_rounded,
                          color: colorScheme.primary, size: 20),
                      onPressed: () async {
                        final path =
                            await DownloadService().getLocalPath(filename);
                        if (await File(path).exists()) {
                          if (mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PdfViewerScreen(
                                    file: File(path), title: resource.title),
                              ),
                            );
                          }
                        }
                      },
                      tooltip: 'Open',
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded,
                          color: colorScheme.error, size: 20),
                      onPressed: () => _confirmDelete(resource, filename),
                      tooltip: 'Delete',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestCard(BuildContext context, MockTest test) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filename = 'mock_test_${test.id}.json';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outline.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final path = await DownloadService().getLocalPath(filename);
            if (await File(path).exists()) {
              if (mounted) {
                await ExamHelper.startExam(context, test);
                _checkDownloads();
              }
            }
          },
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: test.signedUrl != null && test.signedUrl!.isNotEmpty
                      ? Image.network(
                          test.signedUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholderIcon(
                              context, Icons.quiz_rounded),
                        )
                      : _buildPlaceholderIcon(context, Icons.quiz_rounded),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        test.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(Icons.quiz_outlined,
                              size: 14, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${test.totalQuestions} Questions • ${test.category}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.play_circle_outline_rounded,
                          color: colorScheme.primary, size: 24),
                      onPressed: () async {
                        final path =
                            await DownloadService().getLocalPath(filename);
                        if (await File(path).exists()) {
                          if (mounted) {
                            await ExamHelper.startExam(context, test);
                            _checkDownloads();
                          }
                        }
                      },
                      tooltip: 'Start Test',
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded,
                          color: colorScheme.error, size: 20),
                      onPressed: () => _confirmDelete(test, filename),
                      tooltip: 'Delete',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon(BuildContext context, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(icon, color: colorScheme.primary, size: 24),
    );
  }

  Future<void> _confirmDelete(dynamic item, String filename) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = item is Resource
        ? item.title
        : (item is MockTest ? item.title : 'this item');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('Delete Download'),
        content: Text(
            'Are you sure you want to delete "$title" from your device?\n\nYou can download it again anytime.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await DownloadService().deleteFile(filename);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('File deleted successfully'),
              backgroundColor: colorScheme.tertiary,
            ),
          );
          _checkDownloads();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting file: $e'),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      }
    }
  }
}
