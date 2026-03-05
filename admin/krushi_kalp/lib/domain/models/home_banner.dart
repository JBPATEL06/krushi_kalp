class HomeBanner {
  final int id;
  final String title;
  final String imageUrl;
  final String actionType; // 'category', 'test', 'url'
  final String actionValue;
  final bool isActive;
  final int priority;

  HomeBanner({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.actionType,
    required this.actionValue,
    this.isActive = true,
    this.priority = 0,
  });

  factory HomeBanner.fromJson(Map<String, dynamic> json) {
    return HomeBanner(
      id: json['id'] as int,
      title: json['title'] ?? '',
      imageUrl: json['image_url'] ?? '',
      actionType: json['action_type'] ?? 'none',
      actionValue: json['action_value'] ?? '',
      isActive: json['is_active'] ?? true,
      priority: json['priority'] ?? 0,
    );
  }
}
