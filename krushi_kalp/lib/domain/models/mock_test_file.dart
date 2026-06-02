class MockTestFile {
  final int id;
  final int testId;
  final String storagePath;
  final String displayName;
  final int fileOrder;
  final int? fileSizeBytes;
  final String fileType;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MockTestFile({
    required this.id,
    required this.testId,
    required this.storagePath,
    required this.displayName,
    this.fileOrder = 0,
    this.fileSizeBytes,
    this.fileType = 'supplementary_pdf',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isQuiz => fileType == 'quiz_json';

  factory MockTestFile.fromJson(Map<String, dynamic> json) {
    return MockTestFile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      testId: (json['test_id'] as num?)?.toInt() ?? 0,
      storagePath: json['storage_path'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      fileOrder: (json['file_order'] as num?)?.toInt() ?? 0,
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt(),
      fileType: json['file_type'] as String? ?? 'supplementary_pdf',
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
      'test_id': testId,
      'storage_path': storagePath,
      'display_name': displayName,
      'file_order': fileOrder,
      'file_size_bytes': fileSizeBytes,
      'file_type': fileType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  MockTestFile copyWith({
    int? id,
    int? testId,
    String? storagePath,
    String? displayName,
    int? fileOrder,
    int? fileSizeBytes,
    String? fileType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MockTestFile(
      id: id ?? this.id,
      testId: testId ?? this.testId,
      storagePath: storagePath ?? this.storagePath,
      displayName: displayName ?? this.displayName,
      fileOrder: fileOrder ?? this.fileOrder,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      fileType: fileType ?? this.fileType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
