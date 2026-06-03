class TestResult {
  final int resultId;
  final String userId; // Changed to String
  final int testId;
  final String testTitle;
  final double scoreObtained;
  final int totalMarks;
  final bool isPassed;
  final DateTime attemptDate;
  final String language;
  final int? mockTestFileId;
  final int? correctAnswers;
  final int? incorrectAnswers;
  final int? skippedAnswers;
  final int? timeTakenSeconds;

  TestResult({
    required this.resultId,
    required this.userId,
    required this.testId,
    this.testTitle = 'Unknown Test',
    required this.scoreObtained,
    required this.totalMarks,
    required this.isPassed,
    required this.attemptDate,
    this.language = 'en',
    this.mockTestFileId,
    this.correctAnswers,
    this.incorrectAnswers,
    this.skippedAnswers,
    this.timeTakenSeconds,
  });

  factory TestResult.fromJson(Map<String, dynamic> json) {
    // Handle nested mock_test data
    final mockTest = json['mock_tests'];
    String title = 'Test #${json['test_id']}';
    
    double marksPerQ = 1.0;
    if (mockTest != null && mockTest['marks_per_question'] != null) {
      marksPerQ = (mockTest['marks_per_question'] as num).toDouble();
    } else if (json['marks_per_question'] != null) {
      marksPerQ = (json['marks_per_question'] as num).toDouble();
    }

    int attemptedQuestions = (json['correct_answers'] as num?)?.toInt() ?? 0;
    attemptedQuestions += (json['incorrect_answers'] as num?)?.toInt() ?? 0;
    attemptedQuestions += (json['skipped_answers'] as num?)?.toInt() ?? 0;

    int maxMarks = 100; // Default fallback

    if (json['mock_test_file_id'] != null && attemptedQuestions > 0) {
      maxMarks = (attemptedQuestions * marksPerQ).round();
    } else if (mockTest != null) {
      title = mockTest['title'] as String? ?? title;
      if (mockTest['total_questions'] != null && (mockTest['total_questions'] as num).toInt() > 0) {
        final parentQs = (mockTest['total_questions'] as num).toInt();
        maxMarks = (parentQs * marksPerQ).round();
      } else if (mockTest['total_marks'] != null) {
        maxMarks = (mockTest['total_marks'] as num).toInt();
      }
    }

    // Append nested mock test file display name if present
    final mockTestFile = json['mock_test_files'];
    if (mockTestFile != null && mockTestFile is Map) {
      final displayName = mockTestFile['display_name'] as String?;
      if (displayName != null && displayName.isNotEmpty) {
        title = '$title - $displayName';
      }
    }

    // Legacy fallback: sometimes total_marks might be at top level in older queries
    if (json.containsKey('total_marks') && json['total_marks'] != null) {
      maxMarks = (json['total_marks'] as num).toInt();
    }

    return TestResult(
      resultId: json['result_id'] as int,
      userId: json['user_id'] as String, // Cast to String
      testId: json['test_id'] as int,
      testTitle: title,
      scoreObtained: (json['score_obtained'] as num).toDouble(),
      totalMarks: maxMarks,
      isPassed: json['is_passed'] as bool? ?? false,
      attemptDate: DateTime.parse(json['attempt_date'] as String).toLocal(),
      language: json['language'] as String? ?? 'en',
      mockTestFileId: json['mock_test_file_id'] as int?,
      correctAnswers: json['correct_answers'] as int?,
      incorrectAnswers: json['incorrect_answers'] as int?,
      skippedAnswers: json['skipped_answers'] as int?,
      timeTakenSeconds: json['time_taken_seconds'] as int?,
    );
  }
}
