---
name: krushi-isar-local-cache
description: Add or update an Isar local database schema and caching layer in Krushi Kalp. Use when implementing offline support, local caching of Supabase data, or high-speed local reads.
metadata:
  model: claude-sonnet-4-5
  last_modified: Sun, 24 May 2026 00:00:00 GMT
---
# Isar Local Cache in Krushi Kalp

## Contents
- [Key Rules](#key-rules)
- [File Location](#file-location)
- [Workflow: Adding a New Isar Schema](#workflow-adding-a-new-isar-schema)
- [Examples](#examples)

## Key Rules

- Krushi Kalp uses **`isar_community`** (not the original `isar`) for Android 15 16KB page size support. Never switch back to `isar`.
- Isar schemas require code generation — run `build_runner` after any schema change.
- Isar is used for **caching** only. Supabase is the source of truth. Always sync from Supabase on refresh.
- Schema files live in `lib/data/local/`.
- The Isar instance is initialized in `main.dart` and accessed via a singleton or provider.

## File Location

```
lib/data/local/
├── isar_service.dart        ← Isar initialization + singleton access
├── cached_mock_test.dart    ← Example schema
└── cached_resource.dart     ← Example schema
```

## Workflow: Adding a New Isar Schema

### Task Progress
- [ ] **Step 1**: Create schema file in `lib/data/local/cached_feature.dart`
- [ ] **Step 2**: Annotate with `@collection` and add `part` directive
- [ ] **Step 3**: Define `Id id = Isar.autoIncrement` as the primary key
- [ ] **Step 4**: Add all fields with appropriate Isar type annotations
- [ ] **Step 5**: Run `build_runner` to generate `.g.dart`
- [ ] **Step 6**: Register the schema in the Isar `open()` call in `isar_service.dart`
- [ ] **Step 7**: Add read/write methods to the relevant data service or repository
- [ ] **Step 8**: Run `flutter analyze` — fix all issues

## Examples

### Isar Schema Definition

```dart
// lib/data/local/cached_mock_test.dart
import 'package:isar/isar.dart';

part 'cached_mock_test.g.dart';

@collection
class CachedMockTest {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String remoteId;   // Supabase UUID

  late String title;
  late String description;
  late int totalQuestions;
  late int durationMinutes;
  late double price;
  late bool isActive;
  late DateTime cachedAt;
}
```

### Isar Service (singleton)

```dart
// lib/data/local/isar_service.dart
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'cached_mock_test.dart';
import 'cached_resource.dart';

class IsarService {
  IsarService._();
  static final instance = IsarService._();

  late Isar _isar;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        CachedMockTestSchema,
        CachedResourceSchema,
        // Register new schemas here
      ],
      directory: dir.path,
    );
    _initialized = true;
  }

  Isar get db => _isar;
}
```

### Cache Read/Write in a Repository

```dart
// lib/data/repositories/mock_test_repository.dart
class MockTestRepository {
  MockTestRepository._();
  static final instance = MockTestRepository._();

  final _isar = IsarService.instance.db;
  final _service = MockTestService.instance;

  /// Returns cached data immediately, then refreshes from Supabase.
  Future<List<MockTest>> getTests({bool forceRefresh = false}) async {
    // 1. Try cache first
    if (!forceRefresh) {
      final cached = await _isar.cachedMockTests
          .filter()
          .isActiveEqualTo(true)
          .findAll();

      if (cached.isNotEmpty) {
        return cached.map(_fromCache).toList();
      }
    }

    // 2. Fetch from Supabase
    final fresh = await _service.fetchActiveTests();

    // 3. Write to cache
    await _isar.writeTxn(() async {
      await _isar.cachedMockTests.clear();
      await _isar.cachedMockTests.putAll(
        fresh.map(_toCache).toList(),
      );
    });

    return fresh;
  }

  CachedMockTest _toCache(MockTest test) => CachedMockTest()
    ..remoteId = test.id
    ..title = test.title
    ..description = test.description
    ..totalQuestions = test.totalQuestions
    ..durationMinutes = test.durationMinutes
    ..price = test.price
    ..isActive = test.isActive
    ..cachedAt = DateTime.now();

  MockTest _fromCache(CachedMockTest c) => MockTest(
    id: c.remoteId,
    title: c.title,
    description: c.description,
    totalQuestions: c.totalQuestions,
    durationMinutes: c.durationMinutes,
    price: c.price,
    isActive: c.isActive,
  );
}
```

### Clear Cache on Sign Out

```dart
// In AuthService or AuthNotifier sign-out logic:
await IsarService.instance.db.writeTxn(() async {
  await IsarService.instance.db.cachedMockTests.clear();
  await IsarService.instance.db.cachedResources.clear();
});
```
