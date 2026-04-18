import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/auth_notifier.dart';
import '../providers/network_notifier.dart';
import '../../data/services/test_service.dart';
import '../../domain/models/test_result.dart';
import '../widgets/common/network_error_state.dart';
import 'pdf_viewer_screen.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart'; // FIXED: Added import for radius tokens
import '../widgets/common/responsive_wrapper.dart'; // FIXED: Added import for responsive scaling
import '../../utils/crashlytics_service.dart';
import '../../utils/network_utils.dart';

class ScoreScreen extends ConsumerStatefulWidget {
  const ScoreScreen({super.key});

  @override
  ConsumerState<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends ConsumerState<ScoreScreen> {
  List<TestResult> _results = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _hadNetworkError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onNetworkChange() {
    final isConnected = ref.read(networkNotifierProvider);
    if (isConnected && _hadNetworkError && mounted) {
      _hadNetworkError = false;
      _errorMessage = null;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final user = ref.read(authNotifierProvider).user;
    if (user != null) {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }
      try {
        final data = await TestService.instance.fetchUserResults(user.id);

        if (mounted) {
          setState(() {
            _results = data;
            _isLoading = false;
          });
        }
      } catch (e, stack) {
        CrashlyticsService.instance.recordError(e, stack, reason: 'score_screen');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = e.toString();
            _hadNetworkError = NetworkUtils.isNetworkError(e);
          });
        }
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadAndOpenResult(int resultId, String title) async {
    try {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/exam_result_$resultId.pdf');

      if (await file.exists()) {
        _openPdf(file, title);
        return;
      }

      final bucketPath = 'exam_result/$resultId.pdf';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading Result...')),
      );

      final bytes = await TestService.instance.downloadResultPdf(bucketPath);

      await file.writeAsBytes(bytes);
      _openPdf(file, title);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'score_screen');
      if (mounted) {
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('object not found') || 
            errorStr.contains('not found') || 
            errorStr.contains('404')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report not found. Please generate the PDF from the test result screen first.'),
              backgroundColor: Colors.blueAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error downloading result: $e')),
          );
        }
      }
    }
  }

  void _openPdf(File file, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          file: file,
          title: '$title Result',
          password: null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to network changes
    ref.listen(networkNotifierProvider, (previous, next) {
      if (next && _hadNetworkError && mounted) {
        _hadNetworkError = false;
        _errorMessage = null;
        _loadData();
      }
    });

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Score History",
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: context.sp(20), // FIXED: context.sp(20)
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? NetworkErrorState(
                  message: isNetworkError(_errorMessage)
                      ? 'Unable to load score history.'
                      : 'Error: $_errorMessage',
                  onRetry: _loadData,
                )
              : _results.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                              height: MediaQuery.of(context).size.height * 0.3),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history,
                                    size:
                                        context.sp(64), // FIXED: context.sp(64)
                                    color: theme.colorScheme.outline),
                                SizedBox(
                                    height: context.h(AppSpacing
                                        .lg)), // FIXED: context.h(AppSpacing.lg)
                                Text(
                                  "No attempts yet.",
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize:
                                        context.sp(16), // FIXED: context.sp(16)
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // --- LIST ---
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadData,
                            child: AnimationLimiter(
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.only(
                                  left: AppSpacing.lg,
                                  right: AppSpacing.lg,
                                  top: AppSpacing.lg,
                                  bottom: AppSpacing.md +
                                      MediaQuery.of(context)
                                          .padding
                                          .bottom, // FIXED: AppSpacing.md + bottom padding
                                ),
                                itemCount: _results.length,
                                separatorBuilder: (_, __) => SizedBox(
                                    height: context.h(AppSpacing
                                        .md)), // FIXED: context.h(AppSpacing.md)
                                itemBuilder: (context, index) {
                                  final result = _results[index];
                                  return AnimationConfiguration.staggeredList(
                                    position: index,
                                    duration: const Duration(milliseconds: 375),
                                    child: SlideAnimation(
                                      verticalOffset: 50.0,
                                      child: FadeInAnimation(
                                        child: _buildResultCard(result),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildResultCard(TestResult result) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius:
            BorderRadius.circular(AppRadius.lg), // FIXED: AppRadius.lg
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Score Circle
              Container(
                width: context.w(48), // FIXED: context.w(48)
                height: context.w(48), // FIXED: context.w(48)
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: result.isPassed
                      ? theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.3)
                      : theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                ),
                child: Center(
                  child: Text(
                    "${((result.scoreObtained / result.totalMarks) * 100).toInt()}%",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: result.isPassed
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                      fontSize: context.sp(14), // FIXED: context.sp(14)
                    ),
                  ),
                ),
              ),
              SizedBox(
                  width: context
                      .w(AppSpacing.md)), // FIXED: context.w(AppSpacing.md)

              // 2. Main Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Badge Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            result.testTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                              color: theme.colorScheme.onSurface,
                              fontSize: context.sp(16), // FIXED: context.sp(16)
                            ),
                          ),
                        ),
                        SizedBox(
                            width: context.w(AppSpacing
                                .sm)), // FIXED: context.w(AppSpacing.sm)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: context.w(8),
                              vertical: context
                                  .h(4)), // FIXED: context.w(8), context.h(4)
                          decoration: BoxDecoration(
                            color: result.isPassed
                                ? theme.colorScheme.primaryContainer
                                    .withValues(alpha: 0.3)
                                : theme.colorScheme.errorContainer
                                    .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(
                                AppRadius.sm), // FIXED: AppRadius.sm
                          ),
                          child: Text(
                            result.isPassed ? "PASS" : "FAIL",
                            style: TextStyle(
                              color: result.isPassed
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.error,
                              fontWeight: FontWeight.bold,
                              fontSize: context.sp(10), // FIXED: context.sp(10)
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.h(6)), // FIXED: context.h(6)

                    // Marks & Language
                    Row(
                      children: [
                        Icon(Icons.assignment_turned_in_outlined,
                            size: context.sp(14), // FIXED: context.sp(14)
                            color: theme.colorScheme.onSurfaceVariant),
                        SizedBox(width: context.w(4)), // FIXED: context.w(4)
                        Expanded(
                          // FIXED: Added Expanded
                          child: Text(
                            "${result.scoreObtained.toStringAsFixed(1)} / ${result.totalMarks}",
                            overflow:
                                TextOverflow.ellipsis, // FIXED: Added ellipsis
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                              fontSize: context.sp(12), // FIXED: context.sp(12)
                            ),
                          ),
                        ),
                        SizedBox(
                            width: context.w(AppSpacing
                                .md)), // FIXED: context.w(AppSpacing.md)
                        Icon(Icons.translate,
                            size: context.sp(14), // FIXED: context.sp(14)
                            color: theme.colorScheme.onSurfaceVariant),
                        SizedBox(width: context.w(4)), // FIXED: context.w(4)
                        Text(
                          result.language == 'gu' ? 'Gujarati' : 'English',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                            fontSize: context.sp(12), // FIXED: context.sp(12)
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.h(4)), // FIXED: context.h(4)

                    // Date
                    Text(
                      _formatDate(result.attemptDate),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontSize: context.sp(11), // FIXED: context.sp(11)
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 3. Actions Divider
          Padding(
            padding: EdgeInsets.only(
                top: context.h(12),
                bottom: context.h(8)), // FIXED: context.h(12), context.h(8)
            child: Divider(height: 1, color: theme.colorScheme.outlineVariant),
          ),

          // 4. Action Buttons (Full Width Touch Targets)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _deleteResult(result.resultId),
                icon: Icon(Icons.delete_outline,
                    size: context.sp(18),
                    color: theme.colorScheme.error), // FIXED: context.sp(18)
                label: Text("Delete",
                    style: TextStyle(
                        color: theme.colorScheme.error,
                        fontSize: context.sp(13))), // FIXED: context.sp(13)
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                      horizontal: context.w(AppSpacing.md),
                      vertical: context.h(
                          8)), // FIXED: context.w(AppSpacing.md), context.h(8)
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              SizedBox(
                  width: context
                      .w(AppSpacing.sm)), // FIXED: context.w(AppSpacing.sm)
              TextButton.icon(
                onPressed: () =>
                    _downloadAndOpenResult(result.resultId, result.testTitle),
                icon: Icon(Icons.remove_red_eye,
                    size: context.sp(18),
                    color: theme.colorScheme.primary), // FIXED: context.sp(18)
                label: Text("View Result",
                    style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: context.sp(13))), // FIXED: context.sp(13)
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                      horizontal: context.w(AppSpacing.lg),
                      vertical: context.h(
                          8)), // FIXED: context.w(AppSpacing.lg), context.h(8)
                  backgroundColor:
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppRadius.md)), // FIXED: AppRadius.md
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _deleteResult(int resultId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Result?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Delete",
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error))),
        ],
      ),
    );

    if (confirmed == true) {
      // Optimistic update: Remove from UI immediately
      final previousResults = List<TestResult>.from(_results);
      if (!mounted) return;
      setState(() {
        _results.removeWhere((r) => r.resultId == resultId);
        _isLoading = true; // Show loading briefly while confirming
      });

      try {
        final success = await TestService.instance.deleteTestResult(resultId);

        if (success) {
          // Re-fetch to ensure consistency
          await _loadData();
          if (!mounted) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Attempt deleted")));
        } else {
          // Rollback on server failure
          if (!mounted) return;
          setState(() {
            _results = previousResults;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  "Server permission error: Please check Supabase Delete Policy."),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e, stack) {
        CrashlyticsService.instance.recordError(e, stack, reason: 'score_screen');
        // Rollback on error
        if (!mounted) return;
        setState(() {
          _results = previousResults;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }
}
