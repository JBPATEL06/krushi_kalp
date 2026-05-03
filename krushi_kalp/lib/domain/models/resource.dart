enum ResourceType {
  currentAffair,
  studyMaterial,
  eBook,
  pyq,
}

class Resource {
  final int id;
  final String title;
  final String? description;
  final ResourceType type;
  final String? category;
  final String? fileUrl;
  final String? thumbnailUrl;
  final double price;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;


  const Resource({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.category,
    this.fileUrl,
    this.thumbnailUrl,
    this.price = 0.0,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });


  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      // FIX #1: All non-nullable fields are null-safe — prevents startup crash
      // when SharedPreferences cache has stale/incomplete entries.
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] as String?) ?? '',
      description: json['description'] as String?,
      type: _parseType((json['type'] as String?) ?? ''),
      category: json['category'] as String?,
      fileUrl: json['file_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      isActive: (json['is_active'] as bool?) ?? false,
      // FIX #3: 'mrp' and 'discount' do NOT exist in the DB schema.
      // 'created_at' is null-guarded to prevent crash on malformed cache.
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );

  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'type': _typeToString(type),
      'category': category,
      'file_url': fileUrl,
      'thumbnail_url': thumbnailUrl,
      'price': price,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };

  }

  Resource copyWith({
    int? id,
    String? title,
    String? description,
    ResourceType? type,
    String? category,
    String? fileUrl,
    String? thumbnailUrl,
    double? price,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {

    return Resource(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      fileUrl: fileUrl ?? this.fileUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      price: price ?? this.price,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );

  }

  static ResourceType _parseType(String typeStr) {
    final normalized = typeStr.toLowerCase().trim().replaceAll('-', '').replaceAll('_', '').replaceAll(' ', '');
    if (normalized == 'currentaffair') return ResourceType.currentAffair;
    if (normalized == 'studymaterial') return ResourceType.studyMaterial;
    if (normalized == 'ebook') return ResourceType.eBook;
    if (normalized == 'pyq') return ResourceType.pyq;
    
    return ResourceType.studyMaterial;
  }

  static String _typeToString(ResourceType type) {
    switch (type) {
      case ResourceType.currentAffair:
        return 'current_affair';
      case ResourceType.studyMaterial:
        return 'study_material';
      case ResourceType.eBook:
        return 'ebook';
      case ResourceType.pyq:
        return 'pyq';
    }
  }

  String get typeString => _typeToString(type);
}
