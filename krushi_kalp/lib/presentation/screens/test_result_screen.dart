import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/crashlytics_service.dart';
import '../../domain/models/question.dart';
import '../../domain/services/pdf_service.dart';
import 'pdf_viewer_screen.dart';
import 'test_analysis_screen.dart';
import '../../data/services/translation_service.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';
import '../../data/services/review_service.dart';
import '../widgets/reviews/review_dialog.dart';
import 'main_screen.dart';
import '../../data/services/test_service.dart';
import '../../utils/error_utils.dart';
import '../widgets/common/responsive_wrapper.dart';
import '../../data/services/performance_service.dart';
import '../providers/auth_notifier.dart';
import '../providers/network_notifier.dart';

class TestResultScreen extends ConsumerStatefulWidget {
  final int? resultId;
  final String testId;
  final String testTitle;
  final double score; 
  final int totalQuestions;
  final double totalMarks;
  final int? correctAnswers;
  final int? wrongAnswers;
  final int? skippedAnswers;
  final dynamic questions; 
  final Map<int, int>? selectedAnswers;
  final String examLanguage;
  final int timeTakenSeconds;

  const TestResultScreen({
    super.key,
    this.resultId,
    required this.testId,
    required this.testTitle,
    required this.score,
    required this.totalQuestions,
    required this.totalMarks,
    this.correctAnswers,
    this.wrongAnswers,
    this.skippedAnswers,
    this.questions,
    this.selectedAnswers,
    this.examLanguage = 'en',
    this.timeTakenSeconds = 0,
  });

  @override
  ConsumerState<TestResultScreen> createState() => _TestResultScreenState();
}

class _TestResultScreenState extends ConsumerState<TestResultScreen>
    with SingleTickerProviderStateMixin {
  final PdfService _pdfService = PdfService();
  late ConfettiController _confettiController;
  late AnimationController _scoreAnimationController;
  late Animation<double> _scoreAnimation;
  bool _isGeneratingPdf = false;
  bool _isDiscarding = false;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _scoreAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));

    final double percentage =
        widget.totalMarks > 0 ? (widget.score / widget.totalMarks) * 100 : 0.0;

    _scoreAnimation = Tween<double>(begin: 0, end: widget.score).animate(
        CurvedAnimation(
            parent: _scoreAnimationController, curve: Curves.easeOut));

    if (percentage >= 40) {
      _confettiController.play();
    }
    _scoreAnimationController.forward();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final isConnected = ref.read(networkNotifierProvider);
    if (!isConnected) {
      setState(() => _isOffline = true);
      if (mounted) {
        _showOfflineWarning();
      }
    }
  }

  void _showOfflineWarning() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.wifi_off_rounded,
                color: Theme.of(context).colorScheme.error),
            SizedBox(
                width: context
                    .w(AppSpacing.sm)), 
            const Text('Offline Attempt'),
          ],
        ),
        content: Text(
          'Your data will not be uploaded in database as you are offline. However, your result PDF will be locally stored on this device for your reference.\n\nYou can view it anytime in your downloads.',
          style: TextStyle(fontSize: context.sp(14)), 
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scoreAnimationController.dispose();
    super.dispose();
  }

  Future<void> _generateAndDownloadPdf() async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final authState = ref.read(authNotifierProvider);
      final user = authState.user;
      final userId = user?.id ?? 'guest_user';
      final userName = authState.username ?? 'User';

      List<Question>? finalQuestions = widget.questions != null
          ? (widget.questions as List).cast<Question>()
          : null;

      if (finalQuestions != null) {
        try {
          if (widget.examLanguage == 'gu') {
            finalQuestions =
                await TranslationService.translateBatch(finalQuestions);
          }
        } catch (e, stack) {
          await CrashlyticsService.instance.recordError(e, stack,
              reason: 'Failed to translate questions for PDF');
        }
      }

      final file = await _pdfService.generateExamResultPdf(
        testId: widget.testId,

        testTitle: widget.testTitle,
        score: widget.score,
        totalMarks: widget.totalMarks,
        correctAnswers: widget.correctAnswers ?? 0,
        wrongAnswers: widget.wrongAnswers ?? 0,
        skippedAnswers: widget.skippedAnswers ?? 0,
        userId: userId,
        userName: userName,
        questions: finalQuestions,
        selectedAnswers: widget.selectedAnswers,
        languageCode: widget.examLanguage,
      );

      final path = 'exam_result/${userId}_${widget.testId}.pdf';
      try {
        await TestService.instance.uploadResultPdf(path, file);

        PerformanceService.instance
            .updateUserStreak(
              userId,
              widget.timeTakenSeconds,
              'test_attempt',
            )
            .ignore();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF Uploaded Successfully')),
          );
        }
      } catch (e, stack) {
        CrashlyticsService.instance.recordError(e, stack, reason: 'test_result_screen');
        if (mounted) {
          ErrorUtils.showError(context, e);
        }
      }

      if (!mounted) return;

      final password = _pdfService.getSecurePassword(userId, widget.testTitle);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(
            file: file,
            password: password,
            title: 'Result PDF',
          ),
        ),
      );
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'test_result_screen');
      if (mounted) {
        ErrorUtils.showError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  Future<void> _discardResult() async {
    if (widget.resultId == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Result?'),
        content: const Text('This will permanently delete this test result. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isDiscarding = true);
      try {
        await TestService.instance.deleteTestResult(widget.resultId!);
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        }
      } catch (e, stack) {
        CrashlyticsService.instance.recordError(e, stack, reason: 'test_result_screen');
        if (mounted) ErrorUtils.showError(context, e);
      } finally {
        if (mounted) setState(() => _isDiscarding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double percentage =
        widget.totalMarks > 0 ? (widget.score / widget.totalMarks) * 100 : 0.0;
    final bool isPassed = percentage >= 40; 
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Please use "Back to Home" or "Close" to exit results.'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Scaffold(
            backgroundColor: theme.colorScheme.surface,
            appBar: AppBar(
              title: Text(
                'RESULTS SUMMARY',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              centerTitle: true,
              backgroundColor: theme.colorScheme.surface,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const MainScreen(),
                  ),
                  (route) => false,
                ),
              ),
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: context.h(AppSpacing.lg)),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    padding: EdgeInsets.symmetric(
                        vertical: context.h(32),
                        horizontal: AppSpacing.lg),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primaryContainer
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'TOTAL SCORE',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: theme.colorScheme.onPrimary
                                        .withValues(alpha: 0.8),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                        ),
                        SizedBox(height: context.h(AppSpacing.md)),
                        Container(
                          padding: EdgeInsets.all(context.w(AppSpacing.md)),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onPrimary
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPassed
                                ? Icons.emoji_events_rounded
                                : Icons.sentiment_dissatisfied_rounded,
                            size: context.sp(64),
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        SizedBox(height: context.h(AppSpacing.md)),
                        AnimatedBuilder(
                          animation: _scoreAnimation,
                          builder: (context, child) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _scoreAnimation.value.toStringAsFixed(1),
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onPrimary,
                                        fontSize: context.sp(56),
                                      ),
                                ),
                                Text(
                                  'OUT OF ${widget.totalMarks.toStringAsFixed(1)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: theme.colorScheme.onPrimary
                                            .withValues(alpha: 0.8),
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                ),
                              ],
                            );
                          },
                        ),
                        SizedBox(height: context.h(AppSpacing.lg)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          child: Text(
                            isPassed
                                ? 'Test Completed Successfully\nYou have achieved the passing score for the ${widget.testTitle}.'
                                : 'Test Not Cleared\nYou did not achieve the required passing score for the ${widget.testTitle}.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: theme.colorScheme.onPrimary
                                      .withValues(alpha: 0.95),
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                  fontSize: context.sp(18),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.h(AppSpacing.xxl)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            label: 'RIGHT',
                            value: '${widget.correctAnswers ?? 0}',
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        SizedBox(width: context.w(AppSpacing.lg)),
                        Expanded(
                          child: _buildStatCard(
                            label: 'WRONG',
                            value: '${widget.wrongAnswers ?? 0}',
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.h(AppSpacing.xl)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isGeneratingPdf ? null : _generateAndDownloadPdf,
                        icon: _isGeneratingPdf
                            ? SizedBox(
                                width: context.sp(20),
                                height: context.sp(20),
                                child: const CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(Icons.download, color: theme.colorScheme.onPrimary),
                        label: Text(
                          _isGeneratingPdf
                              ? 'Generating PDF...'
                              : 'Download & View Result PDF',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimary,
                            fontSize: context.sp(16),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          foregroundColor: theme.colorScheme.onPrimaryContainer,
                          padding: EdgeInsets.symmetric(vertical: context.h(18)),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            side: BorderSide(
                              color: theme.colorScheme.primary.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: context.h(AppSpacing.lg)),
                  if (!_isOffline)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: _buildRatingSection(),
                    ),
                  SizedBox(height: context.h(AppSpacing.lg)),
                  if (widget.questions != null && widget.selectedAnswers != null)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: context.h(AppSpacing.sm),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TestAnalysisScreen(
                                  testTitle: widget.testTitle,
                                  questions: widget.questions as List<Question>,
                                  selectedAnswers: widget.selectedAnswers!,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.surface,
                            foregroundColor: theme.colorScheme.primary,
                            padding: EdgeInsets.symmetric(vertical: context.h(18)),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                              side: BorderSide(
                                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Text(
                            'Check Answers',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                              fontSize: context.sp(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_isOffline && widget.resultId != null)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: context.h(AppSpacing.sm),
                          ),
                          child: _isDiscarding
                              ? Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(context.w(AppSpacing.md)),
                                    child: const CircularProgressIndicator(),
                                  ),
                                )
                              : SizedBox(
                                  width: double.infinity,
                                  child: TextButton.icon(
                                    onPressed: _discardResult,
                                    icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                                    label: Text(
                                      'Discard This Result',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: context.sp(14),
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: theme.colorScheme.error,
                                      padding: EdgeInsets.symmetric(vertical: context.h(16)),
                                      backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppRadius.xl),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      Padding(
                        padding: EdgeInsets.all(context.w(AppSpacing.xl)),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (context) => const MainScreen()),
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: EdgeInsets.symmetric(vertical: context.h(18)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.xl),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Back to Home',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimary,
                                fontSize: context.sp(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.md + MediaQuery.of(context).padding.bottom),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 20,
            gravity: 0.3,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
              theme.colorScheme.tertiary,
              theme.colorScheme.surface,
              theme.colorScheme.outline,
            ],
          ),
          if (_isOffline)
            Positioned(
              top: context.h(10),
              right: context.w(10),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(6)),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud_off, color: theme.colorScheme.onPrimary, size: context.sp(14)),
                    SizedBox(width: context.w(4)),
                    Text(
                      'Offline',
                      style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: context.sp(10),
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard({required String label, required String value, required Color color}) {
    return Container(
      padding: EdgeInsets.all(context.w(AppSpacing.lg)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: context.sp(12))),
          SizedBox(height: context.h(AppSpacing.sm)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: context.sp(24))),
        ],
      ),
    );
  }

  bool _hasRated = false;
  bool _isLoadingRating = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkExistingRating();
  }

  Future<void> _checkExistingRating() async {
    if (!_isLoadingRating) return;
    final authState = ref.read(authNotifierProvider);
    final user = authState.user;
    if (user == null) {
      if (mounted) setState(() => _isLoadingRating = false);
      return;
    }
    try {
      int? tId = int.tryParse(widget.testId);
      if (tId != null) {
        final review = await ReviewService.getUserReview(user.id, tId, 'test');
        if (mounted) {
          setState(() {
            _hasRated = review != null;
            _isLoadingRating = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingRating = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingRating = false);
    }
  }

  Widget _buildRatingSection() {
    if (_isLoadingRating) return const SizedBox.shrink();
    if (_hasRated) {
      final theme = Theme.of(context);
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(context.w(AppSpacing.md)),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: theme.colorScheme.secondary, size: context.sp(20)),
            SizedBox(width: context.w(AppSpacing.sm)),
            Text("Thanks for your feedback!", style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: context.sp(14))),
          ],
        ),
      );
    }
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () => _showRatingDialog(),
        icon: Icon(Icons.star_rate_rounded, color: theme.colorScheme.secondary),
        label: Text('Rate this Test', style: TextStyle(fontSize: context.sp(16), fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: context.h(16)),
          backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        ),
      ),
    );
  }

  void _showRatingDialog() {
    final authState = ref.read(authNotifierProvider);
    final user = authState.user;
    if (user == null) return;
    int? tId = int.tryParse(widget.testId);
    if (tId == null) return;
    
    showDialog(
      context: context,
      builder: (context) => ReviewDialog(
        title: widget.testTitle,
        onSubmit: (rating, review) async {
          // Actual submission logic if needed, or just callback
          setState(() => _hasRated = true);
        },
      ),
    );
  }
}
