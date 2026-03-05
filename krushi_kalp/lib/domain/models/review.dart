class Review {
  final int id;
  final String userId;
  final int itemId;
  final String itemType; // 'test' or 'resource'
  final double rating;
  final String? reviewText;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional: Joined User Data (for UI display)
  final String userName;
  final String? userAvatarUrl;

  Review({
    required this.id,
    required this.userId,
    required this.itemId,
    required this.itemType,
    required this.rating,
    this.reviewText,
    required this.createdAt,
    required this.updatedAt,
    this.userName = 'User',
    this.userAvatarUrl,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    // Handle joined user data if available (Supabase join syntax)
    String? name;
    String? avatar;

    // Check if 'users' table was joined
    if (json['users'] != null) {
      name = json['users']
          ['username']; // Only username is reliable from AuthService
      // avatar = json['users']['avatar_url']; // Removed as strictly not in AuthService insert
    }

    return Review(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      itemId: json['item_id'] as int,
      itemType: json['item_type'] as String,
      rating: (json['rating'] as num).toDouble(),
      reviewText: json['review_text'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      userName: name ?? 'User',
      userAvatarUrl: avatar,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'item_id': itemId,
      'item_type': itemType,
      'rating': rating,
      'review_text': reviewText,
      // created_at / updated_at handled by DB defaults typically,
      // but included if needed for specific logic
    };
  }
}
