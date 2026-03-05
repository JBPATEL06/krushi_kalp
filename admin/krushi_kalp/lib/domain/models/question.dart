class Question {
  final int id;
  final String text;
  final List<String> options;
  final int correctOptionIndex; // 0-based index

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctOptionIndex,
  });
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as int? ?? 0,
      text: json['text'] as String,
      options: List<String>.from(json['options'] ?? []),
      correctOptionIndex: json['correctOptionIndex'] as int? ?? 0,
    );
  }
}
