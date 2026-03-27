# Krushi Kalp — Code Audit Report (Updated)
**Date:** 2026-03-28 | **Verified against:** Actual source files | **Previous audit items:** ✅ Fixed / ❌ Still Open

---

## Phase 1 Audit Verification (Old `code_audit_report.md`)
> Original audit flagged architecture as failing. Here is the true current state:

| Old Finding | Was | Now | Status |
|-------------|-----|-----|--------|
| State Management | `Provider` | Still `Provider ^6.1.5+1` | ❌ NOT migrated to Riverpod |
| Local DB | `SharedPreferences` | `Isar 3.1.0+1` added | ✅ FIXED |
| Networking | `http: ^1.2.1` | Still `http: ^1.2.1` (Dio not added) | ❌ NOT migrated |
| Navigation | Standard `Navigator` | GoRouter not found in pubspec | ❌ NOT migrated |
| Secrets | `.env` direct | `Envied ^0.5.4` implemented | ✅ FIXED |
| Payment Verification | Client-side | Server-side SQL RPC deployed | ✅ FIXED |
| RepaintBoundary | Missing | Still missing everywhere | ❌ NOT fixed |

---

## Phase 2 Audit Verification (Previous session bugs)

| Bug | File | Fix Status |
|-----|------|-----------|
| `Resource.fromJson` null cast crash | `resource.dart:45` | ❌ **Still open** — `id: json['id']` unguarded |
| Duplicate Hero tags | `universal_item_card.dart:104` | ❌ **Still open** — `'uic_${title}_$price'` |
| `get_user_performance` RPC | Supabase | ✅ FIXED — verified working |
| `Resource.mrp` / `discount` ghost fields | `resource.dart:17-18` | ❌ **Still open** |
| SQL RPC `calculate_secure_price` | Supabase | ✅ FIXED — deployed and verified |
| SQL RPC `calculate_secure_cart_price` | Supabase | ✅ FIXED — deployed and verified |
| Impeller opt-out deprecated | `AndroidManifest.xml:80-82` | ❌ **Still open** — line 81 still present |
| `mounted` guards | All screen files | ✅ FIXED — guards in place |

---

## 🔴 CRITICAL — Still Open

### 1. `Resource.fromJson` — Null Cast Crash
**File:** [resource.dart:45](file:///f:/Krushi_kalp1/krushi_kalp/lib/domain/models/resource.dart#L45)
**Confirmed in logs:** `type 'Null' is not a subtype of type 'int'`

```dart
// Current — CRASHES if SharedPreferences cache has stale/missing id
id: json['id'],          // no null guard → crash
title: json['title'],    // no null guard → crash
createdAt: DateTime.parse(json['created_at']),  // no guard → crash
```

---

### 2. Duplicate Hero Tags — Navigation Crash
**File:** [universal_item_card.dart:104](file:///f:/Krushi_kalp1/krushi_kalp/lib/presentation/widgets/common/universal_item_card.dart#L104)
**Confirmed in logs:** `multiple heroes share tag: sic_mock test 2_10.0`

```dart
// Current — CRASHES when 2 items in a list have same title AND price
tag: heroTag ?? 'uic_${title}_$price',
```

---

## 🟠 HIGH — Still Open

### 3. `Resource` Ghost Fields (Schema Mismatch)
**File:** [resource.dart:17-18](file:///f:/Krushi_kalp1/krushi_kalp/lib/domain/models/resource.dart#L17)

```dart
final double? mrp;      // NOT in DB — resources table has no mrp column
final String? discount; // NOT in DB — always null, discountPercentage always = 0
```
DB never returns these → `discountPercentage` getter always returns `0` → all discount badges dead.

---

### 4. Silent Error Swallowing — 175+ Instances (CRITICAL DEBT)
**Found:** 175+ blocks of `} catch (e) { ... }` that either do nothing or only `debugPrint`.

**Pattern found in:**
- `auth_provider.dart` — User login/auth failures are invisible.
- `payment_service.dart` — **Payment failures are invisible** in production.
- `notification_service.dart` / `fcm_service.dart` — Push notification errors are swallowed.
- All 8 admin screens — Management failures are hidden.

**Impact:** You will never know why a user's payment failed or why they can't log in because the errors never reach Crashlytics.
**Requirement:** **Every** catch block must at least call `CrashlyticsService.instance.recordError(e, stack)`.

---

### 5. `get_user_performance` RPC Status
The SQL function has been verified as present and working on Supabase backend. It correctly handles streak calculation and test results.

---

### 6. Untyped `dynamic` API Returns
| File | Line | Problem |
|------|------|---------|
| [test_service.dart:273](file:///f:/Krushi_kalp1/krushi_kalp/lib/data/services/test_service.dart#L273) | L273 | `Future<List<dynamic>>` return type |
| [test_service.dart:654](file:///f:/Krushi_kalp1/krushi_kalp/lib/data/services/test_service.dart#L654) | L654 | `fetchAllTestsRaw()` untyped |
| [app_config_service.dart:41](file:///f:/Krushi_kalp1/krushi_kalp/lib/data/services/app_config_service.dart#L41) | L41 | `static dynamic getValue(...)` |

---

### 7. Provider Not Migrated to Riverpod
**`pubspec.yaml:53`** — `provider: ^6.1.5+1` still the state manager.
All providers are `ChangeNotifier` classes, not Riverpod `Notifier`/`AsyncNotifier`.
This is a planned migration per AGENTS.md — not started yet.

---

### 8. Networking Not Migrated to Dio
**`pubspec.yaml:67`** — `http: ^1.2.1` still used.
Dio + Retrofit not added. REST calls are raw `http.get/post` with no interceptors.

---

## 🟡 MEDIUM — Still Open

### 9. Missing `RepaintBoundary` on All List Cards
Zero `RepaintBoundary` widgets in codebase. Logs showed 40–230 skipped frames.
Affected cards: `UniversalItemCard`, `StoreItemCard`, `FreeItemCard`, `DownloadItemCard`.

### 10. Impeller Opt-Out Deprecated
**File:** [AndroidManifest.xml:80-82](file:///f:/Krushi_kalp1/krushi_kalp/android/app/src/main/AndroidManifest.xml#L80)
```xml
<!-- Still present — will break in future Flutter stable: -->
<meta-data
    android:name="io.flutter.embedding.android.EnableImpeller"
    android:value="false" />
```

### 11. `hardwareAccelerated="false"` on MainActivity
**File:** [AndroidManifest.xml:41](file:///f:/Krushi_kalp1/krushi_kalp/android/app/src/main/AndroidManifest.xml#L41)
This disables GPU acceleration for the entire app — unusual and likely hurts rendering performance.

### 12. GoRouter Not Implemented
AGENTS.md requires GoRouter for deep linking. Pubspec has no `go_router` dependency. Navigation is still `Navigator.push/pop`.

---

## ✅ FIXED / CLEAN

| Item | Status |
|------|--------|
| Secrets — Envied | ✅ Implemented |
| Payment — Server-side SQL RPC | ✅ Deployed, verified live |
| Isar local caching | ✅ Implemented |
| Firebase Crashlytics | ✅ Active |
| FCM Push Notifications | ✅ Active |
| `mounted` guards (async context safety) | ✅ Present in all screen files |
| Hardcoded API keys | ✅ None found |
| Static analysis (prod code) | ✅ Zero errors |

---

## Priority Fix Order (for New Engineer)

| # | Severity | Issue | File | Effort |
|---|----------|-------|------|--------|
| 1 | 🔴 | `Resource.fromJson` null crash | `resource.dart:45` | 5 min |
| 2 | 🔴 | Duplicate Hero tags | `universal_item_card.dart:104` | 5 min |
| 3 | 🟠 | **175+ Silent Catch Blocks** | Project-wide | 2 hrs |
| 4 | 🟠 | Remove `mrp`/`discount` ghost fields | `resource.dart:17-18` | 10 min |
| 5 | 🟡 | `hardwareAccelerated="false"` | `AndroidManifest.xml:41` | 2 min |
| 6 | 🟡 | Remove Impeller opt-out | `AndroidManifest.xml:80-82` | 2 min |
| 7 | 🟡 | Add `RepaintBoundary` to list cards | 4 widget files | 20 min |
| 8 | 🟠 | Add Dio + type-safe service layer | `pubspec.yaml` + services | Large |
| 9 | 🟠 | Migrate Provider → Riverpod | All providers | Large |
| 10 | 🟠 | Add GoRouter navigation | Core router | Large |
