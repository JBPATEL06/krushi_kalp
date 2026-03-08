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
  final double? mrp; // Maximum Retail Price
  final String? discount; // Discount description
  final bool isActive;
  final DateTime createdAt;

  Resource({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.category,
    this.fileUrl,
    this.thumbnailUrl,
    this.price = 0.0,
    this.mrp,
    this.discount,
    required this.isActive,
    required this.createdAt,
  });

  // Helper for Discount Percentage
  int get discountPercentage {
    if (mrp == null || mrp! <= price || mrp! == 0) return 0;
    return ((mrp! - price) / mrp! * 100).round();
  }

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: _parseType(json['type']),
      category: json['category'],
      fileUrl: json['file_url'],
      thumbnailUrl: json['thumbnail_url'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      mrp: (json['mrp'] as num?)?.toDouble(),
      discount: json['discount'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
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
    double? mrp,
    String? discount,
    bool? isActive,
    DateTime? createdAt,
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
      mrp: mrp ?? this.mrp,
      discount: discount ?? this.discount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static ResourceType _parseType(String typeStr) {
    switch (typeStr) {
      case 'current_affair':
        return ResourceType.currentAffair;
      case 'study_material':
        return ResourceType.studyMaterial;
      case 'ebook':
        return ResourceType.eBook;
      case 'pyq':
        return ResourceType.pyq;
      default:
        return ResourceType.studyMaterial;
    }
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
}
