class AppConfig {
  final String key;
  final Map<String, dynamic> value;
  final String? description;

  AppConfig({
    required this.key,
    required this.value,
    this.description,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      key: json['key'] as String,
      value: json['value'] as Map<String, dynamic>,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
      'description': description,
    };
  }
}
