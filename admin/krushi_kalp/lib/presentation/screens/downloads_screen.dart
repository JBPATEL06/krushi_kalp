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
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../utils/exam_helper.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen>
    with WidgetsBindingObserver {
  // We need to track download status for items to sort/display correctly
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

  // To avoid infinite loops or excessive checks, we track the last IDs checked
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
    // Watch providers for changes
    final resourceProvider = context.watch<ResourceProvider>();
    final testProvider = context.watch<TestProvider>();

    final purchasedResourceIds = resourceProvider.purchasedResourceIds;
    final myTests = testProvider.userTests;
    final myResources = resourceProvider.purchasedResources;

    // Trigger re-check if purchase IDs changed (and we're not loading)
    final currentTestIds = myTests.map((t) => t.id).toSet();
    if (!_isLoading &&
        (!SetEquality().equals(_lastTestIds, currentTestIds) ||
            !SetEquality().equals(_lastResourceIds, purchasedResourceIds))) {
      // Use future.microtask to avoid calling setState during build
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

    // Sort: Downloaded first? Or Date?
    // Let's sort by Title for now
    // displayItems.sort((a, b) => ...);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              "Downloads",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (!_isLoading && displayItems.isNotEmpty)
              Text(
                "${displayItems.length} item${displayItems.length == 1 ? '' : 's'}",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
          ],
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: _isLoading ? AppColors.primary : AppColors.textPrimary,
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
                            color: AppColors.neutral100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.file_download_outlined,
                            size: 56,
                            color: AppColors.neutral400,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          "No Downloads Yet",
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          "Downloaded resources will appear here\nfor offline access",
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _checkDownloads,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemCount: displayItems.length,
                    itemBuilder: (context, index) {
                      final item = displayItems[index];

                      if (item is Resource) {
                        return _buildResourceCard(item);
                      } else if (item is MockTest) {
                        return _buildTestCard(item);
                      }
                      return const SizedBox();
                    },
                  ),
                ),
    );
  }

  Widget _buildResourceCard(Resource resource) {
    final filename = 'resource_${resource.id}.pdf';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.neutral200.withValues(alpha: 0.3),
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
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Cover Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: resource.thumbnailUrl != null &&
                          resource.thumbnailUrl!.isNotEmpty
                      ? Image.network(
                          resource.thumbnailUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.folder_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              resource.category ?? resource.type.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.open_in_new_rounded,
                          color: AppColors.primary, size: 20),
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
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.error, size: 20),
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

  Widget _buildTestCard(MockTest test) {
    final filename = 'mock_test_${test.id}.json';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.neutral200.withValues(alpha: 0.3),
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
                // Refresh list in case they finished it or something changed
                _checkDownloads();
              }
            }
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Cover Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: test.signedUrl != null && test.signedUrl!.isNotEmpty
                      ? Image.network(
                          test.signedUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: const Icon(
                              Icons.description,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: const Icon(
                            Icons.description,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        test.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.quiz_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${test.totalQuestions} Questions • ${test.category}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.play_circle_outline,
                          color: AppColors.primary, size: 24),
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
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.error, size: 20),
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

  Future<void> _confirmDelete(dynamic item, String filename) async {
    final title = item is Resource
        ? item.title
        : (item is MockTest ? item.title : 'this item');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
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
            const SnackBar(
              content: Text('File deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          // Refresh the list
          _checkDownloads();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting file: $e')),
          );
        }
      }
    }
  }
}
