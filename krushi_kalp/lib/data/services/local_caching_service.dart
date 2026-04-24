import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    // One-time cache clear for migration to unique IDs (Deduplication Fix)
    final prefs = await SharedPreferences.getInstance();
    const migrationKey = 'isar_migration_v2_unique_ids';
    final hasMigrated = prefs.getBool(migrationKey) ?? false;
    if (!hasMigrated) {
      await isar.writeTxn(() => isar.clear());
      await prefs.setBool(migrationKey, true);
    }

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

  /// PRO FIX: Sync Mock Tests (Clear + Put) to prevent ghost data
  static Future<void> syncMockTests(List<MockTestEntity> tests) async {
    await isar.writeTxn(() async {
      await isar.mockTestEntitys.clear();
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

  /// PRO FIX: Sync Offers (Clear + Put)
  static Future<void> syncOffers(List<OfferEntity> offers) async {
    await isar.writeTxn(() async {
      await isar.offerEntitys.clear();
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

  /// PRO FIX: Sync Resources by Type (Clear specific type + Put)
  static Future<void> syncResources(List<ResourceEntity> resources, String typeString) async {
    await isar.writeTxn(() async {
      // Delete only resources of the specified type
      await isar.resourceEntitys
          .filter()
          .typeStringEqualTo(typeString)
          .deleteAll();
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
