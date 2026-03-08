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
  });

  factory TestResult.fromJson(Map<String, dynamic> json) {
    // Handle nested mock_test data
    final mockTest = json['mock_tests'];
    String title = 'Test #${json['test_id']}';
    int maxMarks = 100; // Default fallback

    if (mockTest != null) {
      title = mockTest['title'] as String? ?? title;
      // Try to get total_marks from nested object, fallback to top level if legacy
      if (mockTest['total_marks'] != null) {
        maxMarks = mockTest['total_marks'] as int;
      }
    }

    // Legacy fallback: sometimes total_marks might be at top level in older queries
    if (json.containsKey('total_marks') && json['total_marks'] != null) {
      maxMarks = json['total_marks'] as int;
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
    );
  }
}
