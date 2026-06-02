import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krushi_kalp/utils/responsive.dart';
import 'package:krushi_kalp/core/theme/app_spacing.dart';
import 'package:krushi_kalp/core/theme/app_radius.dart';
import 'package:krushi_kalp/data/services/resource_service.dart';
import 'package:krushi_kalp/data/services/download_service.dart';
import 'package:krushi_kalp/domain/models/resource.dart';
import 'package:krushi_kalp/domain/models/resource_file.dart';
import '../widgets/common/download_action_button.dart';
import '../providers/auth_notifier.dart';
import 'pdf_viewer_screen.dart';
import '../../utils/crashlytics_service.dart';
import '../../utils/error_utils.dart';

class ResourceFilesScreen extends ConsumerStatefulWidget {
  final Resource resource;

  const ResourceFilesScreen({super.key, required this.resource});

  @override
  ConsumerState<ResourceFilesScreen> createState() =>
      _ResourceFilesScreenState();
}

class _ResourceFilesScreenState extends ConsumerState<ResourceFilesScreen> {
  List<ResourceFile> _supplementaryFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    try {
      final files =
          await ResourceService.instance.fetchResourceFiles(widget.resource.id);
      if (mounted) {
        setState(() {
          _supplementaryFiles = files;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      CrashlyticsService.instance
          .recordError(e, stack, reason: 'resource_files_screen: _loadFiles');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    double size = bytes.toDouble();
    int suffixIndex = 0;
    while (size >= 1024 && suffixIndex < suffixes.length - 1) {
      size /= 1024;
      suffixIndex++;
    }
    return "${size.toStringAsFixed(2)} ${suffixes[suffixIndex]}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final r = widget.resource;

    // Check if we should use legacy PDF file fallback
    final hasNoSupplementary = _supplementaryFiles.isEmpty && !_isLoading;
    final hasLegacyPdf = r.fileUrl != null && r.fileUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          r.title,
          style:
              TextStyle(fontSize: context.sp(18), fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadFiles,
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
                    // Cover Image
                    Container(
                      width: context.sp(80),
                      height: context.sp(80),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: r.thumbnailUrl != null &&
                              r.thumbnailUrl!.startsWith('http')
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              child: Image.network(
                                r.thumbnailUrl!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(Icons.picture_as_pdf_outlined,
                              size: context.sp(36),
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5)),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    // Info Block
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              (r.category ?? 'Resource').toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            r.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: context.sp(16),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            r.description != null && r.description!.isNotEmpty
                                ? r.description!
                                : 'Supplementary Resource',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // FILES SECTION HEADER
              Text(
                'RESOURCE FILES',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                  fontSize: context.sp(12),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: CircularProgressIndicator(),
                  ),
                )
              // Backward compatibility fallback to show single Main PDF
              else if (hasNoSupplementary && hasLegacyPdf)
                _buildFileRow(
                  context: context,
                  displayName: 'Main PDF',
                  storagePath: r.fileUrl!,
                  localFilename: 'resource_${r.id}.pdf',
                  fileSizeBytes: null,
                )
              else if (hasNoSupplementary && !hasLegacyPdf)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                        color:
                            colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    'No download files available for this resource.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _supplementaryFiles.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final file = _supplementaryFiles[index];
                    final localFilename = 'resource_file_${file.id}.pdf';
                    return _buildFileRow(
                      context: context,
                      displayName: file.displayName,
                      storagePath: file.storagePath,
                      localFilename: localFilename,
                      fileSizeBytes: file.fileSizeBytes,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileRow({
    required BuildContext context,
    required String displayName,
    required String storagePath,
    required String localFilename,
    required int? fileSizeBytes,
  }) {
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
      child: Row(
        children: [
          Icon(Icons.picture_as_pdf_outlined,
              color: colorScheme.error, size: context.sp(26)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: context.sp(14),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (fileSizeBytes != null)
                  Text(
                    _formatBytes(fileSizeBytes),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: context.sp(11),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          DownloadActionButton(
            filename: localFilename,
            url: storagePath,
            bucketName: 'mock_test',
            testId: 'resource_file_${displayName}_$localFilename',
            startLabel: 'Open',
            isFullWidth: false,
            userId: ref.read(authProvider).user?.id,
            displayName: displayName,
            onAction: () async {
              try {
                final currentUserId = ref.read(authProvider).user?.id;
                if (currentUserId == null) return;
                final localPath = await DownloadService()
                    .getLocalPath(localFilename, userId: currentUserId);
                final localFile = File(localPath);
                if (await localFile.exists()) {
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PdfViewerScreen(
                          file: localFile,
                          title: displayName,
                        ),
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ErrorUtils.showError(context,
                        'Local file not found. Please download again.');
                  }
                }
              } catch (e, stack) {
                CrashlyticsService.instance.recordError(e, stack,
                    reason: 'Failed to open supplementary resource PDF');
                if (context.mounted) {
                  ErrorUtils.showError(context, 'Failed to open file: $e');
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
