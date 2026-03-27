import 'package:isar/isar.dart';
import 'package:krushi_kalp/domain/models/resource.dart';

part 'resource_entity.g.dart';

@collection
class ResourceEntity {
  Id id = Isar.autoIncrement;

  late int resourceId;
  late String title;
  String? description;

  // Safe Enum storing as String
  late String typeString;

  String? category;
  String? fileUrl;
  String? thumbnailUrl;
  late double price;
  late bool isActive;
  late DateTime createdAt;

  // Convert from Domain Model
  static ResourceEntity fromResource(Resource resource) {
    return ResourceEntity()
      ..resourceId = resource.id
      ..title = resource.title
      ..description = resource.description
      ..typeString = resource.type.name
      ..category = resource.category
      ..fileUrl = resource.fileUrl
      ..thumbnailUrl = resource.thumbnailUrl
      ..price = resource.price
      ..isActive = resource.isActive
      ..createdAt = resource.createdAt;
  }

  // Convert to Domain Model
  Resource toResource() {
    // Parse the enum from string
    ResourceType parsedType = ResourceType.values.firstWhere(
      (e) => e.name == typeString,
      orElse: () => ResourceType.studyMaterial,
    );

    return Resource(
      id: resourceId,
      title: title,
      description: description,
      type: parsedType,
      category: category,
      fileUrl: fileUrl,
      thumbnailUrl: thumbnailUrl,
      price: price,
      isActive: isActive,
      createdAt: createdAt,
    );
  }
}
