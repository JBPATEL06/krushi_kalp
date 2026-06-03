import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krushi_kalp/utils/responsive.dart';
import 'package:krushi_kalp/core/theme/app_spacing.dart';
import 'package:krushi_kalp/core/theme/app_radius.dart';
import 'package:krushi_kalp/data/services/mock_test_file_service.dart';
import 'package:krushi_kalp/data/services/download_service.dart';
import 'package:krushi_kalp/domain/models/mock_test.dart';
import 'package:krushi_kalp/domain/models/mock_test_file.dart';
import '../utils/exam_helper.dart';
import '../widgets/common/download_action_button.dart';
import '../providers/auth_notifier.dart';
import 'pdf_viewer_screen.dart';
import '../../utils/crashlytics_service.dart';
import '../../utils/error_utils.dart';

class MockTestFilesScreen extends ConsumerStatefulWidget {
  final MockTest test;

  const MockTestFilesScreen({super.key, required this.test});

  @override
  ConsumerState<MockTestFilesScreen> createState() => _MockTestFilesScreenState();
}

class _MockTestFilesScreenState extends ConsumerState<MockTestFilesScreen> {
  List<MockTestFile> _quizzes = [];
  List<MockTestFile> _supplementaryFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    try {
      final files = await MockTestFileService.instance.fetchMockTestFiles(widget.test.id);
      if (mounted) {
        setState(() {
          _quizzes = files.where((f) => f.isQuiz).toList();
          _supplementaryFiles = files.where((f) => !f.isQuiz).toList();
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'mock_test_files_screen: _loadFiles');
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
    final t = widget.test;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Mock Test Files',
            style: TextStyle(fontSize: context.sp(20), fontWeight: FontWeight.bold)),
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
              // Cover and Header Card
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
                    // Cover Thumbnail
                    Container(
                      width: context.sp(80),
                      height: context.sp(80),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: t.signedUrl != null && t.signedUrl!.startsWith('http')
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              child: Image.network(
                                t.signedUrl!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(Icons.assignment_rounded,
                              size: context.sp(36),
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    // Info block
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              t.category.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            t.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: context.sp(16),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${t.totalQuestions} Tests | ${t.time} | Marks/Q: ${t.marksPerQuestion.toString().replaceAll(RegExp(r'\.0$'), '')}${t.negativeMarking ? " | Neg: -${t.negativeMarksPerQ.toString().replaceAll(RegExp(r'\.0$'), '')}" : ""}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Fallback single ATTEMPT Mock Test button if there are no new quiz files but there is a legacy filePath
              if (_quizzes.isEmpty && t.filePath.isNotEmpty) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await ExamHelper.startExam(context, t);
                    },
                    icon: Icon(Icons.play_arrow_rounded, color: colorScheme.onPrimary, size: context.sp(24)),
                    label: Text(
                      'ATTEMPT MOCK TEST',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: context.sp(16),
                        letterSpacing: 1.1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // QUIZZES SECTION (if there are new quiz files)
              if (_quizzes.isNotEmpty) ...[
                Text(
                  'QUIZZES',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 1.2,
                    fontSize: context.sp(12),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _quizzes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final file = _quizzes[index];
                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.quiz_outlined, color: colorScheme.primary, size: context.sp(26)),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              file.displayName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: context.sp(14),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          ElevatedButton(
                            onPressed: () async {
                              await ExamHelper.startExamFromFile(context, t, file);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: const Text('Attempt'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // SUPPLEMENTARY FILES
              Text(
                'SUPPLEMENTARY RESOURCES',
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
              else if (_supplementaryFiles.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    'No additional supplementary files available for this mock test.',
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
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final file = _supplementaryFiles[index];
                    final localFilename = 'mock_test_file_${file.id}.pdf';

                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf_outlined, color: colorScheme.error, size: context.sp(26)),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.displayName,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: context.sp(14),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (file.fileSizeBytes != null)
                                  Text(
                                    _formatBytes(file.fileSizeBytes!),
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
                            url: file.storagePath,
                            bucketName: 'mock_test',
                            testId: 'supplementary_file_${file.id}',
                            startLabel: 'Open',
                            isFullWidth: false,
                            userId: ref.read(authProvider).user?.id,
                            displayName: file.displayName,
                            onAction: () async {
                              try {
                                final currentUserId = ref.read(authProvider).user?.id;
                                if (currentUserId == null) return;
                                final localPath = await DownloadService().getLocalPath(localFilename, userId: currentUserId);
                                final localFile = File(localPath);
                                if (await localFile.exists()) {
                                  if (context.mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PdfViewerScreen(
                                          file: localFile,
                                          title: file.displayName,
                                        ),
                                      ),
                                    );
                                  }
                                } else {
                                  if (context.mounted) {
                                    ErrorUtils.showError(context, 'Local file not found. Please download again.');
                                  }
                                }
                              } catch (e, stack) {
                                CrashlyticsService.instance.recordError(e, stack, reason: 'Failed to open supplementary PDF');
                                if (context.mounted) {
                                  ErrorUtils.showError(context, 'Failed to open file: $e');
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
