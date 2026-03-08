import 'package:flutter/material.dart';
import '../../data/repositories/mock_repository.dart';
import '../../domain/models/question.dart';
import '../../core/theme/app_spacing.dart'; // FIXED: Added import for spacing tokens
import '../../core/theme/app_radius.dart'; // FIXED: Added import for radius tokens
import '../widgets/common/responsive_wrapper.dart'; // FIXED: Added import for responsive scaling
import 'test_result_screen.dart';

class TestAttemptScreen extends StatefulWidget {
  final int testId;
  final String testTitle;

  const TestAttemptScreen({
    super.key,
    required this.testId,
    required this.testTitle,
  });

  @override
  State<TestAttemptScreen> createState() => _TestAttemptScreenState();
}

class _TestAttemptScreenState extends State<TestAttemptScreen> {
  late List<Question> _questions;
  int _currentQuestionIndex = 0;
  final Map<int, int> _selectedAnswers = {}; // Map<QuestionId, OptionIndex>
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  void _loadQuestions() {
    // Simulate async loading
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _questions = MockRepository().getQuestions(widget.testId);
        _isLoading = false;
      });
    });
  }

  void _onOptionSelected(int optionIndex) {
    setState(() {
      _selectedAnswers[_questions[_currentQuestionIndex].id] = optionIndex;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _finishTest();
    }
  }

  Future<bool> _showExitConfirmation() async {
    final theme = Theme.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Test?'),
        content: const Text(
          'Are you sure you want to exit? Your progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Exit',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _finishTest() {
    // Calculate score
    int score = 0;
    for (var question in _questions) {
      final selected = _selectedAnswers[question.id];
      // CHANGED: Use string-based comparison instead of index
      if (selected != null &&
          question.options[selected].trim().toLowerCase() ==
              question.correctAnswer.trim().toLowerCase()) {
        score++; // CHANGED
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TestResultScreen(
          testId: widget.testId.toString(),
          testTitle: widget.testTitle,
          score: score.toDouble(),
          totalQuestions: _questions.length,
          totalMarks: _questions.length.toDouble(),
          questions: _questions,
          selectedAnswers: _selectedAnswers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final question = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final shouldPop = await _showExitConfirmation();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          elevation: 0,
          title: Text(
            widget.testTitle,
            style: TextStyle(fontSize: context.sp(18)), // FIXED: context.sp(18)
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final shouldPop = await _showExitConfirmation();
              if (shouldPop && mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            Center(
              child: Padding(
                padding: EdgeInsets.only(
                    right: context.w(16.0)), // FIXED: context.w(16.0)
                child: Text(
                  '${_currentQuestionIndex + 1}/${_questions.length}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    fontSize: context.sp(16), // FIXED: context.sp(16)
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(context.w(16.0)), // FIXED: context.w(16.0)
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor:
                    AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
              SizedBox(height: context.h(24)), // FIXED: context.h(24)
              Text(
                'Question ${_currentQuestionIndex + 1}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: context.sp(14), // FIXED: context.sp(14)
                ),
              ),
              SizedBox(height: context.h(8)), // FIXED: context.h(8)
              Text(
                question.text,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: context.sp(20), // FIXED: context.sp(20)
                ),
              ),
              SizedBox(height: context.h(32)), // FIXED: context.h(32)
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: question.options.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedAnswers[question.id] == index;
                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: context.h(12.0)), // FIXED: context.h(12.0)
                      child: OutlinedButton(
                        onPressed: () => _onOptionSelected(index),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.all(
                              context.w(16)), // FIXED: context.w(16)
                          backgroundColor: isSelected
                              ? theme.colorScheme.primary.withValues(alpha: 0.1)
                              : theme.colorScheme.surface,
                          side: BorderSide(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                            width: isSelected ? 2 : 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppRadius.md), // FIXED: AppRadius.md
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            question.options[index],
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: context.sp(14), // FIXED: context.sp(14)
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md), // FIXED: AppSpacing.md
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: AppSpacing.md +
                          MediaQuery.of(context)
                              .padding
                              .bottom), // FIXED: Standard bottom padding
                  child: ElevatedButton(
                    onPressed: _selectedAnswers[question.id] != null
                        ? _nextQuestion
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding:
                          EdgeInsets.all(context.w(16)), // FIXED: context.w(16)
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppRadius.md), // FIXED: AppRadius.md
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentQuestionIndex == _questions.length - 1
                          ? 'Submit Test'
                          : 'Next Question',
                      style: TextStyle(
                          fontSize: context.sp(18),
                          fontWeight: FontWeight.bold), // FIXED: context.sp(18)
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
