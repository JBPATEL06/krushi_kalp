class Question {
  final int id; // CHANGED
  final String text; // CHANGED
  final List<String> options; // CHANGED
  final String correctAnswer; // CHANGED (String instead of int)

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctAnswer,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    // Handle both old format and new tableConvert format
    // New format keys: "No.", "Question", "Option A", "Option B", ... "Correct Answer"

    // Robust ID parsing
    int? parsedId;
    final dynamic rawId = json['No.'] ?? json['id'];
    if (rawId is int) {
      parsedId = rawId;
    } else if (rawId != null) {
      parsedId = int.tryParse(rawId.toString());
    }
    final int id = parsedId ?? 0;
    final String text =
        (json['Question'] ?? json['text'] ?? '') as String; // CHANGED

    // Extract options (A, B, C, D, E...)
    List<String> options = []; // CHANGED
    if (json.containsKey('options')) {
      options = List<String>.from(json['options']); // CHANGED
    } else {
      // tableConvert format: Option A, Option B, etc.
      options = json.keys
          .where((k) => k.startsWith('Option '))
          .map((k) => json[k].toString().trim())
          .where((v) => v.isNotEmpty)
          .toList(); // CHANGED
    }

    final String correctAnswer =
        (json['Correct Answer'] ?? json['correctAnswer'] ?? '')
            .toString()
            .trim(); // CHANGED

    // Validation: Correct Answer must match one of the options (case-insensitive)
    final bool matchFound = options.any((opt) =>
        opt.trim().toLowerCase() == correctAnswer.toLowerCase()); // CHANGED

    if (correctAnswer.isNotEmpty && !matchFound) {
      throw Exception(
          'Question #$id: Correct Answer "$correctAnswer" not found in options: ${options.join(", ")}'); // CHANGED
    }

    return Question(
      id: id,
      text: text,
      options: options,
      correctAnswer: correctAnswer,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, // CHANGED
      'text': text, // CHANGED
      'options': options, // CHANGED
      'correctAnswer': correctAnswer, // CHANGED
    };
  }
}
