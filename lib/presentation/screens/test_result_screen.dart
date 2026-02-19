import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/question.dart';
import '../../domain/services/pdf_service.dart';
import 'pdf_viewer_screen.dart';
import 'test_analysis_screen.dart';
import '../../data/services/translation_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class TestResultScreen extends StatefulWidget {
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
        title: const Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: AppColors.error),
            SizedBox(width: AppSpacing.sm),
            Text('Offline Attempt'),
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
      final user = Supabase.instance.client.auth.currentUser;
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
        await Supabase.instance.client.storage.from('mock_test').upload(
              path,
              file,
              fileOptions: const FileOptions(upsert: true),
            );

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
    // Logic
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
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text(
                'RESULTS SUMMARY',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
              ),
              centerTitle: true,
              backgroundColor: AppColors.surface,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: AppColors.textPrimary),
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
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
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryActive],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusXl),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'TOTAL SCORE',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // Icon
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isPassed
                                  ? Icons.emoji_events_rounded
                                  : Icons.sentiment_dissatisfied_rounded,
                              size: 64,
                              color: Colors.white,
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
                                      color: Colors.white,
                                      fontSize: 56,
                                    ),
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              isPassed
                                  ? 'Test Completed Successfully\nYou have achieved the passing score for the ${widget.testTitle}.'
                                  : 'Test Not Cleared\nYou did not achieve the required passing score for the ${widget.testTitle}.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.95),
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
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: _buildStatCard(
                              label: 'WRONG',
                              value: '${widget.wrongAnswers ?? 0}',
                              color: AppColors.error,
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
                              : const Icon(Icons.download,
                                  color: AppColors.textPrimary),
                          label: Text(
                            _isGeneratingPdf
                                ? 'Generating PDF...'
                                : 'Download & View Result PDF',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            side: const BorderSide(
                              color: AppColors.textPrimary,
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
                                    questions:
                                        widget.questions as List<Question>,
                                    selectedAnswers: widget.selectedAnswers!,
                                  ),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              side: const BorderSide(
                                color: AppColors.textPrimary,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusXl),
                              ),
                            ),
                            child: Text(
                              'Check Answers',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
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
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                AppColors.textPrimary, // Dark Theme
                            foregroundColor: AppColors.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusXl),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Back to Home',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onPrimary,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 20, // Reduced from default (30)
            gravity: 0.3, // Slower fall
            colors: const [
              Color(0xFF2563EB), // Blue
              Color(0xFF60A5FA), // Light Blue
              Color(0xFFFFFFFF), // White
              Color(0xFFCBD5E1), // Slate/Silver
              Color(0xFF1E40AF), // Dark Blue
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
                  color: AppColors.error.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cloud_off, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Offline',
                      style: TextStyle(
                          color: Colors.white,
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
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}
