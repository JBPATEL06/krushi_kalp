import 'package:isar/isar.dart';
import 'package:krushi_kalp/domain/models/resource.dart';

part 'resource_entity.g.dart';

@collection
class ResourceEntity {
  @Index(unique: true, replace: true)
  Id id = Isar.autoIncrement;

  int? resourceId;
  String? title;
  String? description;

  // Safe Enum storing as String
  String? typeString;

  String? category;
  String? fileUrl;
  String? thumbnailUrl;
  double? price;
  bool? isActive;
  DateTime? createdAt;
  DateTime? updatedAt;


  // Convert from Domain Model
  static ResourceEntity fromResource(Resource resource) {
    return ResourceEntity()
      ..id = resource.id
      ..resourceId = resource.id
      ..title = resource.title
      ..description = resource.description
      ..typeString = resource.type.name
      ..category = resource.category
      ..fileUrl = resource.fileUrl
      ..thumbnailUrl = resource.thumbnailUrl
      ..price = resource.price
      ..isActive = resource.isActive
      ..createdAt = resource.createdAt
      ..updatedAt = resource.updatedAt;

  }

  // Convert to Domain Model
  Resource toResource() {
    // Parse the enum from string
    ResourceType parsedType = ResourceType.values.firstWhere(
      (e) => e.name == typeString,
      orElse: () => ResourceType.studyMaterial,
    );

    return Resource(
      id: resourceId ?? 0,
      title: title ?? '',
      description: description,
      type: parsedType,
      category: category,
      fileUrl: fileUrl,
      thumbnailUrl: thumbnailUrl,
      price: price ?? 0.0,
      isActive: isActive ?? true,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
    );

  }
}
