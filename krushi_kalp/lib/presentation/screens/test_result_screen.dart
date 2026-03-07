import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import '../../domain/models/question.dart';
import '../../domain/services/pdf_service.dart';
import 'pdf_viewer_screen.dart';
import 'test_analysis_screen.dart';
import '../../data/services/translation_service.dart';
import '../../core/theme/app_spacing.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../data/services/review_service.dart'; // NEW
import '../widgets/reviews/review_dialog.dart'; // NEW
import 'main_screen.dart';
import '../../data/services/test_service.dart';

class TestResultScreen extends StatefulWidget {
  final int? resultId;
  final String testId;
  final String testTitle;
  final double score; // Marks Obtained
  final int totalQuestions;
  final double totalMarks;
  final int? correctAnswers;
  final int? wrongAnswers;
  final int? skippedAnswers;
  // Analysis Data
  final dynamic questions; // Using dynamic for flexibility here
  final Map<int, int>? selectedAnswers;
  final String examLanguage;

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
  });

  @override
  State<TestResultScreen> createState() => _TestResultScreenState();
}

class _TestResultScreenState extends State<TestResultScreen>
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

    _scoreAnimation = Tween<double>(begin: 0, end: percentage).animate(
        CurvedAnimation(
            parent: _scoreAnimationController, curve: Curves.easeOut));

    if (percentage >= 40) {
      _confettiController.play();
    }
    _scoreAnimationController.forward();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    if (results.contains(ConnectivityResult.none)) {
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
            const SizedBox(width: AppSpacing.sm),
            const Text('Offline Attempt'),
          ],
        ),
        content: const Text(
          'Your data will not be uploaded in database as you are offline. However, your result PDF will be locally stored on this device for your reference.\n\nYou can view it anytime in your downloads.',
          style: TextStyle(fontSize: 14),
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
      final user = AuthService.instance.currentUser;
      final userId = user?.id ?? 'guest_user';
      final userName = user?.userMetadata?['full_name'] ?? 'User';

      // 1. Check and Translate if needed
      List<Question>? finalQuestions = widget.questions != null
          ? (widget.questions as List).cast<Question>()
          : null;

      if (finalQuestions != null) {
        try {
          if (widget.examLanguage == 'gu') {
            // Translate if the exam was taken in Gujarati
            finalQuestions =
                await TranslationService.translateBatch(finalQuestions);
          }
        } catch (e) {
          debugPrint('PDF Translation Error: $e');
        }
      }

      // 2. Generate local encrypted PDF
      final file = await _pdfService.generateExamResultPdf(
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

      // 3. Upload to Supabase Storage
      // Path: exam_result/<testId>.pdf (as requested)
      final path = 'exam_result/${widget.testId}.pdf';
      try {
        await TestService.instance.uploadResultPdf(path, file);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF Uploaded Successfully')),
          );
        }
      } catch (e) {
        debugPrint('Upload error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: $e. Opening local copy.')),
          );
        }
      }

      if (!mounted) return;

      // 4. Open in App
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double percentage =
        widget.totalMarks > 0 ? (widget.score / widget.totalMarks) * 100 : 0.0;
    final bool isPassed = percentage >= 40; // Passing logic
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Optionally show message
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
                  const SizedBox(height: AppSpacing.lg),
                  // Score Card
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    padding: const EdgeInsets.symmetric(
                        vertical: 32, horizontal: AppSpacing.lg),
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
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      boxShadow: [
                        BoxShadow(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'TOTAL SCORE',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: theme.colorScheme.onPrimary
                                        .withValues(alpha: 0.8),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onPrimary
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPassed
                                ? Icons.emoji_events_rounded
                                : Icons.sentiment_dissatisfied_rounded,
                            size: 64,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Percentage Animation
                        AnimatedBuilder(
                          animation: _scoreAnimation,
                          builder: (context, child) {
                            return Text(
                              '${_scoreAnimation.value.toStringAsFixed(0)}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimary,
                                    fontSize: 56,
                                  ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                                  fontSize: 18, // Slightly larger
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Stats Grid
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            label: 'RIGHT',
                            value: '${widget.correctAnswers ?? 0}',
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
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

                  const SizedBox(height: AppSpacing.xl),

                  // PDF Download Button
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            _isGeneratingPdf ? null : _generateAndDownloadPdf,
                        icon: _isGeneratingPdf
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(Icons.download,
                                color: theme.colorScheme.onSurface),
                        label: Text(
                          _isGeneratingPdf
                              ? 'Generating PDF...'
                              : 'Download & View Result PDF',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          side: BorderSide(
                            color: theme.colorScheme.onSurface,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusXl),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Rating Button (only if online)
                  if (!_isOffline)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: _buildRatingSection(),
                    ),

                  const SizedBox(height: AppSpacing.lg),

                  // Analysis Button
                  if (widget.questions != null &&
                      widget.selectedAnswers != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
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
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            side: BorderSide(
                              color: theme.colorScheme.onSurface,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusXl),
                            ),
                          ),
                          child: Text(
                            'Check Answers',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Discard Button (only if online and resultId exists)
                      if (!_isOffline && widget.resultId != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          child: _isDiscarding
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(AppSpacing.md),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : SizedBox(
                                  width: double.infinity,
                                  child: TextButton.icon(
                                    onPressed: _discardResult,
                                    icon: Icon(Icons.delete_outline,
                                        color: theme.colorScheme.error),
                                    label: const Text(
                                      'Discard This Result',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: theme.colorScheme.error,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      backgroundColor: theme.colorScheme.error
                                          .withValues(alpha: 0.1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            AppSpacing.radiusXl),
                                      ),
                                    ),
                                  ),
                                ),
                        ),

                      // Bottom Button (Back to Home)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const MainScreen(),
                                ),
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusXl),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Back to Home',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).padding.bottom),
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
            numberOfParticles: 20, // Reduced from default (30)
            gravity: 0.3, // Slower fall
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
              theme.colorScheme.tertiary,
              theme.colorScheme.surface,
              theme.colorScheme.outline,
            ],
          ),
          // Offline Indicator
          if (_isOffline)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud_off,
                        color: theme.colorScheme.onPrimary, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Offline',
                      style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 10,
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

  // --- RATING SECTION ---
  bool _hasRated = false;
  bool _isLoadingRating = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkExistingRating();
  }

  Future<void> _checkExistingRating() async {
    // Only check once
    if (!_isLoadingRating) return;

    final user = AuthService.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingRating = false);
      return;
    }

    try {
      // Assuming testId is numeric ID in string format. If GUID, this works too.
      // But ReviewService expects int for ID.
      // Let's try to parse widget.testId. If it fails, we skip rating (legacy IDs).
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
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
              color: theme.colorScheme.secondary.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                color: theme.colorScheme.secondary, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              "Thanks for your feedback!",
              style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold),
            ),
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
        label: Text(
          'Rate this Test',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
        ),
      ),
    );
  }

  void _showRatingDialog() {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    int? tId = int.tryParse(widget.testId);
    if (tId == null) return;

    showDialog(
      context: context,
      builder: (context) => ReviewDialog(
        title: widget.testTitle,
        onSubmit: (rating, review) async {
          try {
            await ReviewService.submitReview(
              userId: user.id,
              itemId: tId,
              itemType: 'test',
              rating: rating,
              reviewText: review,
            );

            if (mounted) {
              setState(() => _hasRated = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you for your review!')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to submit: $e')),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05), // Very light tint
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(backgroundColor: color, radius: 4),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color.withValues(alpha: 0.8),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _discardResult() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Discard Result?"),
        content: const Text(
            "This will delete this attempt's record from your history. This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Keep"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              "Discard",
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isDiscarding = true);
      try {
        await TestService.instance.deleteTestResult(widget.resultId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Result discarded successfully.')),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDiscarding = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to discard: $e')),
          );
        }
      }
    }
  }
}
