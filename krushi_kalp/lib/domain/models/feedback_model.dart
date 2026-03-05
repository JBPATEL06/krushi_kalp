enum FeedbackStatus { pending, replied, closed }

class FeedbackModel {
  final String id;
  final String userId;
  final String subject; // NEW
  final String message; // mapped from description
  final String? adminReply; // NEW
  final FeedbackStatus status; // NEW
  final DateTime createdAt; // NEW

  // Legacy fields kept for compatibility with existing UI if needed,
  // or refactored. The user didn't explicitly delete 'rating' but defined a new table.
  // I will keep 'rating' and 'type' as optional for now to avoid breaking UI immediately,
  // but focus on the new schema.
  final double? rating;
  final String? mockTestId;

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.subject,
    required this.message,
    this.adminReply,
    this.status = FeedbackStatus.pending,
    required this.createdAt,
    this.rating,
    this.mockTestId,
  });
}
