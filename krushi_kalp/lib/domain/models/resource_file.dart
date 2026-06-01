class ResourceFile {
  final int id;
  final int resourceId;
  final String storagePath;
  final String displayName;
  final int fileOrder;
  final int? fileSizeBytes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ResourceFile({
    required this.id,
    required this.resourceId,
    required this.storagePath,
    required this.displayName,
    this.fileOrder = 0,
    this.fileSizeBytes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ResourceFile.fromJson(Map<String, dynamic> json) {
    return ResourceFile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      resourceId: (json['resource_id'] as num?)?.toInt() ?? 0,
      storagePath: json['storage_path'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      fileOrder: (json['file_order'] as num?)?.toInt() ?? 0,
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt(),
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
      'id': id,
      'resource_id': resourceId,
      'storage_path': storagePath,
      'display_name': displayName,
      'file_order': fileOrder,
      'file_size_bytes': fileSizeBytes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ResourceFile copyWith({
    int? id,
    int? resourceId,
    String? storagePath,
    String? displayName,
    int? fileOrder,
    int? fileSizeBytes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ResourceFile(
      id: id ?? this.id,
      resourceId: resourceId ?? this.resourceId,
      storagePath: storagePath ?? this.storagePath,
      displayName: displayName ?? this.displayName,
      fileOrder: fileOrder ?? this.fileOrder,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
