class Message {
  final String id;
  final String userId;
  final String message;
  final bool isFromAdmin;
  final DateTime createdAt;
  final bool isRead;

  Message({
    required this.id,
    required this.userId,
    required this.message,
    required this.isFromAdmin,
    required this.createdAt,
    this.isRead = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      message: json['message'] as String,
      isFromAdmin: json['is_from_admin'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'message': message,
      'is_from_admin': isFromAdmin,
      // 'created_at' is usually handled by DB default
    };
  }
}
