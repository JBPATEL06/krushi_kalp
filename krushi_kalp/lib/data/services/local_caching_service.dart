import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

// Import our local entities
import '../local/entities/mock_test_entity.dart';
import '../local/entities/offer_entity.dart';
import '../local/entities/resource_entity.dart';

class LocalCachingService {
  static late Isar isar;
  static bool _isInitialized = false;

  /// Initializes the Isar NoSQL Database (Run once in main.dart)
  static Future<void> init() async {
    if (_isInitialized) return;

    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [
        MockTestEntitySchema,
        OfferEntitySchema,
        ResourceEntitySchema,
      ],
      directory: dir.path,
    );
    _isInitialized = true;
  }

  // ============================================
  // MOCK TESTS 
  // ============================================

  /// Save multiple mock tests safely (Upsert)
  static Future<void> saveMockTests(List<MockTestEntity> tests) async {
    await isar.writeTxn(() async {
      await isar.mockTestEntitys.putAll(tests);
    });
  }

  /// Get all cached mock tests
  static Future<List<MockTestEntity>> getCachedMockTests() async {
    return await isar.mockTestEntitys.where().findAll();
  }

  // ============================================
  // OFFERS 
  // ============================================

  /// Save multiple offers safely (Upsert)
  static Future<void> saveOffers(List<OfferEntity> offers) async {
    await isar.writeTxn(() async {
      await isar.offerEntitys.putAll(offers);
    });
  }

  /// Get all cached offers
  static Future<List<OfferEntity>> getCachedOffers() async {
    return await isar.offerEntitys.where().findAll();
  }

  // ============================================
  // RESOURCES 
  // ============================================

  /// Save multiple resources safely (Upsert)
  static Future<void> saveResources(List<ResourceEntity> resources) async {
    await isar.writeTxn(() async {
      await isar.resourceEntitys.putAll(resources);
    });
  }

  /// Get all cached resources
  static Future<List<ResourceEntity>> getCachedResources() async {
    return await isar.resourceEntitys.where().findAll();
  }

  /// Clear Database (Usually for manual cache clear or logout if needed)
  static Future<void> clearAllCache() async {
    await isar.writeTxn(() async {
      await isar.clear();
    });
  }
}
