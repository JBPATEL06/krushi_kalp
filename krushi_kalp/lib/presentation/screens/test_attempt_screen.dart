import 'package:flutter/material.dart';
import '../../data/repositories/mock_repository.dart';
import '../../domain/models/question.dart';
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
            child: const Text(
              'Exit',
              style: TextStyle(color: Colors.red),
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
      if (selected != null && selected == question.correctOptionIndex) {
        score++;
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
        appBar: AppBar(
          title: Text(widget.testTitle),
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
                padding: const EdgeInsets.only(right: 16.0),
                child: Text(
                  '${_currentQuestionIndex + 1}/${_questions.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 24),
              Text(
                'Question ${_currentQuestionIndex + 1}',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(question.text,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 32),
              ...List.generate(question.options.length, (index) {
                final isSelected = _selectedAnswers[question.id] == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: OutlinedButton(
                    onPressed: () => _onOptionSelected(index),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: isSelected
                          ? Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.1)
                          : null,
                      side: BorderSide(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        question.options[index],
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              ElevatedButton(
                onPressed: _selectedAnswers[question.id] != null
                    ? _nextQuestion
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: Text(
                  _currentQuestionIndex == _questions.length - 1
                      ? 'Submit Test'
                      : 'Next Question',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
