import 'dart:io'; // NEW
import 'dart:convert'; // NEW
import 'dart:async';
import 'package:flutter/material.dart';

import '../../domain/models/mock_test.dart';
import '../../domain/models/question.dart';
import '../../data/services/test_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/translation_service.dart';
import '../widgets/common/network_error_state.dart';
import 'test_result_screen.dart';
import 'main_screen.dart';
import '../../core/theme/app_spacing.dart';

class ExamScreen extends StatefulWidget {
  final MockTest test;
  final String examLanguage;
  final File? localFile; // NEW

  const ExamScreen({
    super.key,
    required this.test,
    this.examLanguage = 'en',
    this.localFile, // NEW
  });

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  // Data
  List<Question> _questions = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Translation State
  bool _shouldTranslate = false;
  final Map<int, Question> _translatedQuestions = {};
  final Set<int> _pendingTranslations = {};

  // Exam State
  int _currentQuestionIndex = 0;
  final Map<int, int> _selectedAnswers = {}; // Map<QuestionIndex, OptionIndex>
  Timer? _timer;
  int _remainingSeconds = 0;

  // Controllers
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      List<Question> questions;

      // 1. Try loading from Local File first
      if (widget.localFile != null && await widget.localFile!.exists()) {
        final jsonString = await widget.localFile!.readAsString();
        final List<dynamic> jsonList = jsonDecode(jsonString);
        questions = jsonList.map((q) => Question.fromJson(q)).toList();
      } else {
        // 2. Fallback to Network (Legacy / Safety)
        questions =
            await TestService.instance.fetchQuestions(widget.test.filePath);
      }

      // If user chose Gujarati, ALWAYS translate — regardless of what
      // language the test metadata claims. Respect the user's explicit choice.
      if (widget.examLanguage == 'gu') {
        _shouldTranslate = true;
      }

      if (mounted) {
        setState(() {
          _questions = questions;
          _isLoading = false;
          _startTimer();

          if (_shouldTranslate) {
            _translateBuffer(0); // Start buffering first set
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  // Smart Buffering: Translates current + next 5 questions
  Future<void> _translateBuffer(int startIndex) async {
    if (!_shouldTranslate) return;

    // Buffer range: startIndex to startIndex + 5
    for (int i = startIndex;
        i <= startIndex + 5 && i < _questions.length;
        i++) {
      if (_translatedQuestions.containsKey(i) ||
          _pendingTranslations.contains(i)) {
        continue;
      }

      _pendingTranslations.add(i);

      // Translate in background
      TranslationService.translateQuestion(_questions[i]).then((translatedQ) {
        if (mounted) {
          setState(() {
            _translatedQuestions[i] = translatedQ;
            _pendingTranslations.remove(i);
          });
        }
      });
    }
  }

  void _startTimer() {
    if (widget.test.durationMinutes == null) return; // Unlimited time

    _remainingSeconds = widget.test.durationMinutes! * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _submitTest(autoSubmit: true);
      }
    });
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients) return;

    // Item Width (40) + Separator (8) = 48
    double itemWidth = 48.0;
    double screenWidth = MediaQuery.of(context).size.width;

    // Calculate target offset to center the item
    // Start with padding (16) + item position (index * 48) + half item (24)
    double itemCenter = 16.0 + (index * itemWidth) + (itemWidth / 2);

    // We want this center to be at the middle of the screen
    double offset = itemCenter - (screenWidth / 2);

    // Animate (Controller will clamp values automatically)
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _changePage(int index) {
    if (index < 0 || index >= _questions.length) return;

    // NAVIGATION LOCK: Cannot jump > 10 questions ahead of current
    if (index > _currentQuestionIndex + 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot jump more than 10 questions ahead.'),
        ),
      );
      return;
    }

    setState(() {
      _currentQuestionIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    _scrollToIndex(index);

    // Trigger buffer for next set
    if (_shouldTranslate) {
      _translateBuffer(index);
    }
  }

  void _submitTest({bool autoSubmit = false}) {
    // ... (rest of method is same, just needed to close _changePage first)
    _timer?.cancel();

    // Calculate Score
    int correctCount = 0;
    int wrongCount = 0;

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final selected = _selectedAnswers[i];

      if (selected != null) {
        // CHANGED: Use string-based comparison instead of index
        if (q.options[selected].trim().toLowerCase() ==
            q.correctAnswer.trim().toLowerCase()) {
          correctCount++; // CHANGED
        } else {
          wrongCount++; // CHANGED
        }
      }
    }

    double marksPerQ = widget.test.totalMarks /
        (widget.test.totalQuestions > 0 ? widget.test.totalQuestions : 1);

    double totalScore = (correctCount * marksPerQ);

    if (widget.test.negativeMarking) {
      totalScore -= (wrongCount * widget.test.negativeMarksPerQ);
    }

    if (totalScore < 0) totalScore = 0;

    if (mounted) {
      final user = AuthService.instance.currentUser;
      Future<int?>? submissionFuture;
      if (user != null) {
        submissionFuture = TestService.instance.submitTestResult(
          testId: widget.test.id,
          score: totalScore,
          totalMarks: widget.test.totalMarks,
          authUserId: user.id,
          language: widget.examLanguage,
        );
      }

      if (submissionFuture == null) {
        if (mounted) {
          _navigateToResult(
            resultId: null,
            totalScore: totalScore,
            correctCount: correctCount,
            wrongCount: wrongCount,
          );
        }
      } else {
        submissionFuture.then((resultId) {
          if (mounted) {
            _navigateToResult(
              resultId: resultId,
              totalScore: totalScore,
              correctCount: correctCount,
              wrongCount: wrongCount,
            );
          }
        }).catchError((e) {
          if (mounted) {
            _navigateToResult(
              resultId: null,
              totalScore: totalScore,
              correctCount: correctCount,
              wrongCount: wrongCount,
            );
          }
          return null;
        });
      }

      if (autoSubmit) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Time is up! Test submitted automatically.'),
          ),
        );
      }
    }
  }

  void _navigateToResult({
    int? resultId,
    required double totalScore,
    required int correctCount,
    required int wrongCount,
  }) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TestResultScreen(
          resultId: resultId,
          testId: widget.test.id.toString(),
          testTitle: widget.test.title,
          score: totalScore,
          totalQuestions: _questions.length,
          totalMarks: widget.test.totalMarks.toDouble(),
          correctAnswers: correctCount,
          wrongAnswers: wrongCount,
          skippedAnswers: _questions.length - (correctCount + wrongCount),
          questions: _questions,
          selectedAnswers: _selectedAnswers,
          examLanguage: widget.examLanguage,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final theme = Theme.of(context);

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: NetworkErrorState(
          message: isNetworkError(_errorMessage)
              ? 'Unable to load questions. Please check your connection.'
              : 'Error: $_errorMessage',
          onRetry: _loadQuestions,
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _showExitConfirmation();
        if (shouldExit && context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(widget.test.title, style: theme.textTheme.titleLarge),
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final shouldExit = await _showExitConfirmation();
              if (shouldExit && context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ),
        body: Column(
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: _questions.isEmpty
                  ? 0
                  : (_currentQuestionIndex + 1) / _questions.length,
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              minHeight: 4,
            ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Question ${_currentQuestionIndex + 1}/${_questions.length}",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: 6),
                    decoration: BoxDecoration(
                      color: _remainingSeconds < 60
                          ? theme.colorScheme.error.withValues(alpha: 0.1)
                          : theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: _remainingSeconds < 60
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(_remainingSeconds),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _remainingSeconds < 60
                                ? theme.colorScheme.error
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  // Check if translation is needed and available
                  Question displayQuestion = _questions[index];
                  if (_shouldTranslate) {
                    if (_translatedQuestions.containsKey(index)) {
                      displayQuestion = _translatedQuestions[index]!;
                    } else {
                      // If current question is NOT ready, force translate immediately
                      if (!_pendingTranslations.contains(index)) {
                        _translateBuffer(index);
                      }

                      return TranslationLoadingWidget(
                        onTimeout: () {
                          // User chose to skip translation for this question
                          setState(() {
                            _translatedQuestions[index] =
                                _questions[index]; // Use original
                          });
                        },
                      );
                    }
                  }

                  return _buildQuestionCard(theme, displayQuestion, index);
                },
              ),
            ),

            // Pagination
            if (_questions.isNotEmpty)
              Container(
                height: 50,
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListView.separated(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  scrollDirection: Axis.horizontal,
                  itemCount: _questions.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final isCurrent = index == _currentQuestionIndex;
                    final isAnswered = _selectedAnswers.containsKey(index);

                    return GestureDetector(
                      onTap: () => _changePage(index),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? theme.colorScheme.primary
                              : (isAnswered
                                  ? theme.colorScheme.primary
                                      .withValues(alpha: 0.1)
                                  : theme.colorScheme.surface),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCurrent
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isCurrent
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                            fontWeight:
                                isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Bottom Buttons
            SafeArea(
              bottom: true,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Previous Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _currentQuestionIndex > 0
                            ? () => _changePage(_currentQuestionIndex - 1)
                            : null,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.md),
                          ),
                          side: BorderSide(
                              color: theme.colorScheme.outlineVariant),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_back,
                                size: 18, color: theme.colorScheme.onSurface),
                            const SizedBox(width: 8),
                            Text(
                              'Previous',
                              style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Next Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentQuestionIndex < _questions.length - 1) {
                            _changePage(_currentQuestionIndex + 1);
                          } else {
                            _showSubmitDialog(theme);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.md),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentQuestionIndex < _questions.length - 1
                                  ? 'Next Question'
                                  : 'Submit Test',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              size: 18,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(ThemeData theme, Question q, int index) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question ${index + 1} of ${_questions.length}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            q.text,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ...List.generate(q.options.length, (optIndex) {
            bool isSelected = _selectedAnswers[index] == optIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.md),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedAnswers[index] = optIndex;
                    });
                  },
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surface,
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  size: 16,
                                  color: theme.colorScheme.onPrimary,
                                )
                              : null,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            q.options[optIndex],
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<bool> _showExitConfirmation() async {
    final theme = Theme.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Exam?'),
            content: const Text(
                'Are you sure you want to exit? Your progress will be lost and the exam will not be submitted.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Exit',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSubmitDialog(ThemeData theme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Test?'),
        content: Text(
          'You have answered ${_selectedAnswers.length} out of ${_questions.length} questions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitTest();
            },
            child: const Text(
              'Submit',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class TranslationLoadingWidget extends StatefulWidget {
  final VoidCallback onTimeout;

  const TranslationLoadingWidget({super.key, required this.onTimeout});

  @override
  State<TranslationLoadingWidget> createState() =>
      _TranslationLoadingWidgetState();
}

class _TranslationLoadingWidgetState extends State<TranslationLoadingWidget> {
  bool _showFallback = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Start 10s timer
    _timer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _showFallback = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!_showFallback) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.md),
            const Text("Translating to Gujarati..."),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "(Please wait...)",
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ] else ...[
            const Icon(Icons.timer_off, size: 48, color: Colors.orange),
            const SizedBox(height: AppSpacing.md),
            const Text(
              "Translation is taking longer than expected.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: widget.onTimeout,
              icon: const Icon(Icons.language),
              label: const Text("Attempt in English"),
              style: ElevatedButton.styleFrom(
                foregroundColor: theme.colorScheme.onPrimary,
                backgroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
