---
name: krushi-supabase-service
description: Write or update a Supabase data service in Krushi Kalp following the singleton pattern, no-foreign-key rule, and Crashlytics error logging. Use when adding new database queries, RPCs, or data stitching logic.
metadata:
  model: claude-sonnet-4-5
  last_modified: Sun, 24 May 2026 00:00:00 GMT
---
# Supabase Services in Krushi Kalp

## Contents
- [Core Rules](#core-rules)
- [Service Structure](#service-structure)
- [Query Patterns](#query-patterns)
- [Workflow: Writing a New Service Method](#workflow-writing-a-new-service-method)
- [Examples](#examples)

## Core Rules

These are non-negotiable for all Supabase services in this project:

1. **Singleton pattern** — `ClassName._()` private constructor + `static final instance`.
2. **No foreign key joins in queries** — Never use `.select('*, related_table(*)')`. Fetch related data in separate queries and stitch manually in Dart.
3. **Always filter `is_active = true`** on user-facing content fetches.
4. **Crashlytics on every catch** — `CrashlyticsService.instance.recordError(e, st, reason: '...')`. Never use bare `print`.
5. **Robust numeric parsing** — Use `_parseNum` / `double.tryParse` for all financial/numeric Postgres fields (they come as strings from PostgREST).
6. **IST timezone** — Never call `.toUtc()`. All datetime logic uses IST (Asia/Kolkata).
7. **No RPC overloading** — Each Supabase RPC must have a unique name to avoid PostgREST ambiguity errors.
8. **Snapshot integrity** — Store full item + user snapshots in transaction tables. Fall back to snapshots in the library if live records are missing.

## Service Structure

```
lib/data/services/
├── feature_service.dart      ← Your service file
```

All services live in `lib/data/services/`. The service is the only layer that talks to Supabase directly.

## Query Patterns

| Operation | Pattern |
|---|---|
| Fetch list | `.from('table').select().eq('is_active', true).order(...)` |
| Fetch single | `.from('table').select().eq('id', id).single()` |
| Insert | `.from('table').insert(data).select().single()` |
| Update | `.from('table').update(data).eq('id', id).select().single()` |
| Delete (soft) | `.from('table').update({'is_active': false}).eq('id', id)` |
| RPC call | `.rpc('function_name', params: {...})` |
| Paginated | `.from('table').select().range(from, to).order(...)` |

## Workflow: Writing a New Service Method

### Task Progress
- [ ] **Step 1**: Identify the Supabase table(s) involved.
- [ ] **Step 2**: Determine if related data needs separate fetches (no joins rule).
- [ ] **Step 3**: Write the method with `try/catch` wrapping the entire body.
- [ ] **Step 4**: Parse response with `fromJson` on the domain model.
- [ ] **Step 5**: Stitch related data manually in Dart if needed.
- [ ] **Step 6**: Log errors via `CrashlyticsService.instance.recordError`.
- [ ] **Step 7**: `rethrow` after logging so the provider can handle the error state.
- [ ] **Step 8**: Run `flutter analyze` — fix all issues.

## Examples

### Basic Singleton Service

```dart
// lib/data/services/resource_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:krushi_kalp/domain/models/resource.dart';
import 'package:krushi_kalp/utils/crashlytics_service.dart';

class ResourceService {
  ResourceService._();
  static final instance = ResourceService._();

  final _client = Supabase.instance.client;

  Future<List<Resource>> fetchActiveResources() async {
    try {
      final response = await _client
          .from('resources')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => Resource.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      CrashlyticsService.instance.recordError(
        e, st, reason: 'ResourceService.fetchActiveResources',
      );
      rethrow;
    }
  }
}
```

### Manual Data Stitching (no joins)

```dart
// Fetch orders and stitch user + item data separately
Future<List<OrderDetail>> fetchOrdersWithDetails() async {
  try {
    // 1. Fetch orders
    final ordersRaw = await _client
        .from('orders')
        .select()
        .order('created_at', ascending: false);

    final orders = (ordersRaw as List)
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();

    if (orders.isEmpty) return [];

    // 2. Fetch related users separately
    final userIds = orders.map((o) => o.userId).toSet().toList();
    final usersRaw = await _client
        .from('profiles')
        .select('id, full_name, email')
        .inFilter('id', userIds);

    final usersMap = {
      for (final u in usersRaw as List)
        (u as Map<String, dynamic>)['id'] as String: u,
    };

    // 3. Stitch manually in Dart
    return orders.map((order) {
      final userData = usersMap[order.userId];
      return OrderDetail(
        order: order,
        userName: userData?['full_name'] as String? ?? 'Unknown',
        userEmail: userData?['email'] as String? ?? '',
      );
    }).toList();
  } catch (e, st) {
    CrashlyticsService.instance.recordError(
      e, st, reason: 'OrderService.fetchOrdersWithDetails',
    );
    rethrow;
  }
}
```

### Robust Numeric Parsing Helper

```dart
// Use this for all financial/numeric fields from Postgres
double _parseNum(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

// Usage in fromJson override or manual mapping:
final price = _parseNum(json['price']);
```

### Paginated Fetch

```dart
Future<List<MockTest>> fetchTestsPaginated({
  required int page,
  required int pageSize,
}) async {
  try {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    final response = await _client
        .from('mock_tests')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .range(from, to);

    return (response as List)
        .map((e) => MockTest.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e, st) {
    CrashlyticsService.instance.recordError(
      e, st, reason: 'MockTestService.fetchTestsPaginated',
    );
    rethrow;
  }
}
```

### RPC Call

```dart
Future<Map<String, dynamic>> getUserStats(String userId) async {
  try {
    final result = await _client.rpc(
      'get_user_stats',
      params: {'p_user_id': userId},
    );
    return result as Map<String, dynamic>;
  } catch (e, st) {
    CrashlyticsService.instance.recordError(
      e, st, reason: 'UserService.getUserStats',
    );
    rethrow;
  }
}
```
