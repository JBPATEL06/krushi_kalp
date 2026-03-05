import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/auth_provider.dart';
import '../providers/network_provider.dart';
import '../../data/services/test_service.dart';
import '../../domain/models/test_result.dart';
import '../widgets/common/network_error_state.dart';
import 'pdf_viewer_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class ScoreScreen extends StatefulWidget {
  const ScoreScreen({super.key});

  @override
  State<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends State<ScoreScreen> {
  List<TestResult> _results = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _hadNetworkError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    NetworkProvider().addListener(_onNetworkChange);
  }

  @override
  void dispose() {
    NetworkProvider().removeListener(_onNetworkChange);
    super.dispose();
  }

  void _onNetworkChange() {
    final isConnected = NetworkProvider().isConnected;
    if (isConnected && _hadNetworkError && mounted) {
      _hadNetworkError = false;
      _errorMessage = null;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }
      try {
        final data = await TestService.fetchUserResults(user.id);

        if (mounted) {
          setState(() {
            _results = data.map((json) => TestResult.fromJson(json)).toList();
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint("Error loading score data: $e");
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = e.toString();
            _hadNetworkError = isNetworkError(e);
          });
        }
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadAndOpenResult(int testId, String title) async {
    try {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/exam_result_$testId.pdf');

      if (await file.exists()) {
        _openPdf(file, title);
        return;
      }

      final bucketPath = 'exam_result/$testId.pdf';
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading Result...')),
      );

      final bytes = await Supabase.instance.client.storage
          .from('mock_test')
          .download(bucketPath);

      await file.writeAsBytes(bytes);
      _openPdf(file, title);
    } catch (e) {
      debugPrint('Download Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading result: $e')),
        );
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "Score History",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
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
                                const Icon(Icons.history,
                                    size: 64, color: AppColors.neutral400),
                                const SizedBox(height: AppSpacing.lg),
                                Text(
                                  "No attempts yet.",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
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
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                itemCount: _results.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: AppSpacing.md),
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.neutral100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: result.isPassed
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Text(
                    "${((result.scoreObtained / result.totalMarks) * 100).toInt()}%",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          result.isPassed ? AppColors.success : AppColors.error,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

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
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                      color: AppColors.textPrimary,
                                    ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: result.isPassed
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.error.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Text(
                            result.isPassed ? "PASS" : "FAIL",
                            style: TextStyle(
                              color: result.isPassed
                                  ? AppColors.success
                                  : AppColors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Marks & Language
                    Row(
                      children: [
                        Icon(Icons.assignment_turned_in_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          "${result.scoreObtained.toStringAsFixed(1)} / ${result.totalMarks}",
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Icon(Icons.translate,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          result.language == 'gu' ? 'Gujarati' : 'English',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Date
                    Text(
                      _formatDate(result.attemptDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.neutral400,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 3. Actions Divider
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Divider(height: 1, color: AppColors.neutral100),
          ),

          // 4. Action Buttons (Full Width Touch Targets)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _deleteResult(result.resultId),
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: AppColors.error),
                label: Text("Delete",
                    style: TextStyle(color: AppColors.error, fontSize: 13)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              TextButton.icon(
                onPressed: () =>
                    _downloadAndOpenResult(result.testId, result.testTitle),
                icon: const Icon(Icons.remove_red_eye,
                    size: 18, color: AppColors.info),
                label: const Text("View Result",
                    style: TextStyle(color: AppColors.info, fontSize: 13)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: 8),
                  backgroundColor: AppColors.info.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
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
              child: Text("Delete", style: TextStyle(color: AppColors.error))),
        ],
      ),
    );

    if (confirmed == true) {
      // Optimistic update: Remove from UI immediately
      final previousResults = List<TestResult>.from(_results);
      if (mounted) {
        setState(() {
          _results.removeWhere((r) => r.resultId == resultId);
          _isLoading = true; // Show loading briefly while confirming
        });
      }

      try {
        final success = await TestService.deleteTestResult(resultId);

        if (success) {
          // Re-fetch to ensure consistency
          await _loadData();
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text("Attempt deleted")));
          }
        } else {
          // Rollback on server failure
          if (mounted) {
            setState(() {
              _results = previousResults;
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    "Server permission error: Please check Supabase Delete Policy."),
                backgroundColor: AppColors.error,
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      } catch (e) {
        // Rollback on error
        if (mounted) {
          setState(() {
            _results = previousResults;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} • ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}
