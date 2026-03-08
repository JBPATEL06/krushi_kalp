enum NotificationType { feedbackReply, systemAlert, examUpdate }

class NotificationModel {
  final int id;
  final int userId;
  final int? relatedFeedbackId;
  final NotificationType type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    this.relatedFeedbackId,
    required this.type,
    required this.title,
    required this.message,
    this.isRead = false,
    required this.createdAt,
  });
}
