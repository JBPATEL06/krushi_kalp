class MockTest {
  final int id;
  final String title;
  final String description;
  final String category;
  final String filePath; // Path to JSON with questions
  final double price;
  final int?
      durationMinutes; // 'duration_minutes' - Nullable for unlimited time
  final int totalQuestions;
  final int totalMarks; // NEW: Max marks possible
  final bool negativeMarking; // NEW: TRUE if enabled
  final double negativeMarksPerQ; // NEW: Deduction amount
  final String language; // NEW: Test language (e.g., 'English', 'Hindi')

  final String? coverImagePath;
  final String? signedUrl; // Used for Cover Image
  final String? contentUrl; // NEW: Used for JSON Content
  final String? discount;
  final double? mrp;
  final DateTime createdAt;
  final bool isPublic;

  MockTest({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.filePath,
    required this.price,
    this.durationMinutes,
    required this.totalQuestions,
    required this.totalMarks,
    required this.negativeMarking,
    required this.negativeMarksPerQ,
    required this.language,
    this.coverImagePath,
    this.discount,
    this.signedUrl,
    this.contentUrl, // NEW
    this.mrp,
    required this.createdAt,
    this.isPublic = false,
  });

  // Helper implementation to display time string
  String get time =>
      durationMinutes != null ? '$durationMinutes mins' : 'No Time Limit';

  // Helper for final price (assuming no discount or handled elsewhere)
  double get finalPrice => price;

  // Calculate Discount Percentage
  int get discountPercentage {
    if (mrp == null || mrp! <= price || mrp! == 0) return 0;
    return ((mrp! - price) / mrp! * 100).round();
  }

  MockTest copyWith({String? signedUrl, String? contentUrl, bool? isPublic}) {
    return MockTest(
      id: id,
      title: title,
      description: description,
      category: category,
      filePath: filePath,
      price: price,
      durationMinutes: durationMinutes,
      totalQuestions: totalQuestions,
      totalMarks: totalMarks,
      negativeMarking: negativeMarking,
      negativeMarksPerQ: negativeMarksPerQ,
      language: language,
      coverImagePath: coverImagePath,
      discount: discount,
      signedUrl: signedUrl ?? this.signedUrl,
      contentUrl: contentUrl ?? this.contentUrl, // NEW
      mrp: mrp,
      createdAt: createdAt,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  // Factory to create a MockTest from a JSON map (Supabase row)
  factory MockTest.fromJson(Map<String, dynamic> json) {
    return MockTest(
      id: json['test_id'] is int
          ? json['test_id']
          : int.tryParse(json['test_id'].toString()) ?? 0,
      title: json['title']?.toString() ?? 'Untitled',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      filePath: json['file_path']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: json['duration_minutes'] is int
          ? json['duration_minutes']
          : int.tryParse(json['duration_minutes']?.toString() ?? ''),
      totalQuestions: json['total_questions'] is int
          ? json['total_questions']
          : int.tryParse(json['total_questions']?.toString() ?? '0') ?? 0,
      totalMarks: json['total_marks'] is int
          ? json['total_marks']
          : int.tryParse(json['total_marks']?.toString() ?? '0') ?? 0,
      negativeMarking: json['negative_marking'] is bool
          ? json['negative_marking']
          : (json['negative_marking'].toString() == 'true'),
      negativeMarksPerQ:
          (json['negative_marks_per_q'] as num?)?.toDouble() ?? 0.0,
      language: json['language']?.toString() ?? 'English',
      coverImagePath: json['cover_image_path'] as String?,
      discount: json['discount'] as String?,
      signedUrl: null,
      contentUrl: null, // Initial null
      mrp: (json['mrp'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isPublic: json['is_public'] is bool
          ? json['is_public']
          : (json['is_public']?.toString() == 'true'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'file_path': filePath,
      'price': price,
      'duration_minutes': durationMinutes,
      'total_questions': totalQuestions,
      'total_marks': totalMarks,
      'negative_marking': negativeMarking,
      'negative_marks_per_q': negativeMarksPerQ,
      'language': language,
      'cover_image_path': coverImagePath,
      'created_at': createdAt.toIso8601String(),
      'is_public': isPublic,
    };
  }
}
