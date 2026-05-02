# Discussion Log: Krushi Kalp Development

[... previous logs ...]

---

## [Phase 21: Admin Resource Detail Fix]
### Goal
Fix compiler errors in `AdminResourceDetailScreen` following the removal of `isPublic` from the `Resource` model.

### Proposed Changes
- **File**: `lib/presentation/screens/admin/resources/admin_resource_detail_screen.dart`
  - **Action**: Replaced all `isPublic` references with `isActive`.
  - **Action**: Updated `copyWith` to use `isActive`.
  - **Action**: Fixed deprecated `activeColor` to `activeThumbColor` in `Switch`.
  - **Action**: Removed duplicate import of `Resource` model.

### Risks / Side Effects
- None.

### Resolved and How
- Screen functionality restored and aligned with updated domain model.

---

## [Phase 20: Resource Schema Fix]
### Goal
Resolve the `PGRST204` database crash occurring when creating/updating resources due to a missing `is_public` column in the `resources` table.

### Proposed Changes
- **File**: `lib/domain/models/resource.dart`
  - **Action**: Removed `isPublic` field. The `resources` table uses `is_active` for visibility.
- **File**: `lib/data/services/resource_service.dart`
  - **Action**: Updated `_signResources` to remove `isPublic` from the constructor call.
- **File**: `lib/presentation/screens/admin/resources/admin_resource_form.dart`
  - **Action**: Removed all references to `isPublic`.

### Risks / Side Effects
- None expected as `isActive` is the primary visibility flag.

### Resolved and How
- Model updated and service calls synchronized.

---

## [Phase 19: Revenue Calculation & Schema Alignment]
### Goal
Resolve transaction revenue discrepancies and ensure Admin UI correctly reflects the `payment` and `access` table schema (replacing legacy `order_items`).

### Proposed Changes
- **File**: `lib/data/services/admin_service.dart`
  - **Action**: Fix `fetchAllOrdersWithDetails` mapping to include `item_snapshot` in the `order_items` compatibility list.
- **File**: `lib/presentation/screens/admin/revenue_details_screen.dart`
  - **Action**: Refactor math logic in `_showOrderDetailsDialog` and `_buildOrderRow`.
- **File**: `lib/presentation/screens/admin/admin_order_list_screen.dart`
  - **Action**: Align dialog math with the updated logic.

---

## [Phase 18: Timezone & Dashboard Synchronization]
### Goal
Fix "Today" filtering issues where revenue was not showing due to server-side UTC offsets.

### Proposed Changes
- **Supabase RPC**: `get_admin_performance` — updated to use `Asia/Kolkata` timezone.
- **File**: `lib/presentation/screens/admin/admin_order_list_screen.dart` — improved username fallback.
- **File**: `lib/presentation/screens/admin/revenue_details_screen.dart` — fixed date filtering.
- **File**: `lib/data/services/admin_service.dart` — fixed `_parseNum` and username fallbacks.

---

## [Phase 17: Payment & Access Integrity Stabilization]
### Goal
Resolve blank admin lists, access type mismatches, and user-side content visibility issues.

### Proposed Changes
- **Supabase RPCs**: Dropped old `complete_checkout_v1`, updated `process_item_claim` to use `access_type = 'claimed'`.
- **File**: `lib/data/services/admin_service.dart` — added `_parseNum` helper.
- **Files**: `lib/data/services/test_service.dart`, `resource_service.dart` — added `is_active` filter and `item_snapshot` fallback.

---

## [Phase 22: Admin Revenue Screen — Payment Table Alignment]
### Goal
Fix revenue screen showing wrong amounts. Understand `payment.amount` semantics and fix all display logic.

### What Was Done
- **Confirmed**: `payment.amount` = net paid (after discount). `payment.discount_amount` = discount applied.
- **`complete_checkout_v1` RPC bug**: `amount` was never written on checkout (cart created with `amount=0`, RPC never updated it).
- **Fix**: Added `amount = p_amount` to the UPDATE in `complete_checkout_v1`.
- **Data fix**: Backfilled 4 broken `amount=0` Razorpay records using `SUM(access.price_paid)`.
- **Further fix**: Records where `amount` stored gross price — corrected to net paid via `amount = amount - discount_amount`.
- **Flutter**: `revenue_details_screen.dart` — `totalRevenue` now sums `total_amount` directly (= net paid). Row and dialog show correct amounts.

### Files Changed
- `lib/presentation/screens/admin/revenue_details_screen.dart`
- Supabase: `complete_checkout_v1` RPC

---

## [Phase 23: Timezone Fix — Joined Date & Purchased Items]
### Goal
Fix dates showing wrong day/time due to missing `.toLocal()` conversion.

### What Was Done
- **`admin_user_details_screen.dart`**: `DateTime.tryParse(user['created_at'])` → added `.toLocal()` so "Joined" date shows correct local day.
- **`admin_user_details_screen.dart`**: `DateTime.parse(item['created_at'])` → added `.toLocal()` for purchased item dates.
- **`revenue_details_screen.dart`**: Removed redundant `.toUtc()` before `.toLocal()` in all 3 date format calls.

---

## [Phase 24: Revenue Screen — Offer Display]
### Goal
Show offer name, % discount, and ₹ saved in transaction details dialog.

### What Was Done
- **`revenue_details_screen.dart`** `_showOrderDetailsDialog`:
  - Shows offer `title` (name).
  - If `discount_type = PERCENTAGE`: shows `X% OFF • saved ₹Y`.
  - If `discount_type = FLAT`: shows `₹X FLAT OFF`.
  - Fallback: shows `saved ₹X` if no offer details in DB.
  - Shows offer `code` below.
  - Right side shows `-₹discount` in green.

---

## [Phase 25: Forgot Password — SMTP Fix]
### Goal
Fix `AuthRetryableFetchException: Error sending recovery email` (500 error).

### Root Cause
Supabase auth logs showed: `535 5.7.8 Username and Password not accepted` from Gmail SMTP. The Gmail app password configured in Supabase Auth SMTP settings was expired/wrong.

### Fix (Manual — Supabase Dashboard)
1. Go to Supabase Dashboard → Authentication → Settings → SMTP Settings.
2. Generate a new Gmail App Password at myaccount.google.com/apppasswords.
3. Update the SMTP password field.
4. Settings: Host=`smtp.gmail.com`, Port=`587`.

---

## [Phase 26: Admin Delete — FK Error Fix]
### Goal
Allow admin to delete users, mock tests, and resources without foreign key constraint errors.

### What Was Done
**3 new Supabase RPC functions deployed:**

| Function | Deletes in order |
|---|---|
| `admin_hard_delete_user` | `access` → `payment` → `results` → `user_streaks` → `messages` → `notifications` → `reviews` → `users` → `auth.users` |
| `admin_delete_mock_test` | `access` (test) → `results` → `reviews` → `mock_tests` |
| `admin_delete_resource` | `access` (resource) → `reviews` → `resources` |

**Flutter changes:**
- `lib/data/services/test_service.dart` — `deleteMockTest` now calls `admin_delete_mock_test` RPC, then cleans storage best-effort.
- `lib/data/services/resource_service.dart` — `deleteResource` now calls `admin_delete_resource` RPC, then cleans storage best-effort.
- `lib/data/services/admin_service.dart` — `deleteUser` already called `admin_hard_delete_user`, which was updated to use `payment`/`access` instead of legacy `orders`/`order_items`.

---

## [Phase 27: Grant/Gift Access Screen — Theme Fix]
### Goal
Fix hardcoded colors in `AdminGrantAccessScreen` that broke dark/light theme.

### What Was Done
- **`lib/presentation/screens/admin/admin_grant_access_screen.dart`**:
  - All `Colors.grey.shade400/600` → `colorScheme.onSurfaceVariant.withValues(alpha: ...)`
  - `Colors.red` (revoke icon) → `colorScheme.error`
  - `const TextStyle(color: Colors.grey)` → `theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)`
  - `const Divider()` → `Divider(color: colorScheme.outlineVariant...)`
  - `ListTile` → added `tileColor: colorScheme.surface`
  - `TabBar` → added `labelColor`, `unselectedLabelColor`, `indicatorColor`
  - `Scaffold` → added `backgroundColor: theme.scaffoldBackgroundColor`
  - Search field text color fixed (was using `onPrimary`, now uses default theme)

---

## [Phase 28: Direct Checkout — Image URI Fix]
### Goal
Fix `Invalid argument(s): No host specified in URI file://` crash in direct checkout sheet when item has no image.

### Root Cause
`Image.network()` was called with a raw storage path (e.g. `mock_test_cover/30.jpg`) or `file://` path instead of a valid `https://` URL.

### What Was Done
- **`lib/presentation/widgets/direct_checkout_sheet.dart`**: Added `startsWith('http')` guard before `Image.network()` + `errorBuilder` fallback.
- **`lib/presentation/screens/admin/admin_home_screen.dart`**: Added `startsWith('http')` guard on top test image.
- Verified all other `Image.network` usages already had the guard.

---

## [Phase 29: Weekly Study Minutes — Stale Data Fix]
### Goal
Fix performance card showing last week's reading minutes on the current week even if user didn't study.

### Root Cause
`get_user_performance` RPC returned `weekly_study_minutes` raw from DB without adjusting for days elapsed since `last_active_date`. The 7-element array `[0,0,0,0,0,0,today]` was never shifted when the user skipped days.

### What Was Done
- **Supabase RPC `get_user_performance`** updated:
  - Calculates `days_since = CURRENT_DATE - last_active_date`.
  - If `days_since >= 7`: returns `[0,0,0,0,0,0,0]` (entire window stale).
  - If `0 < days_since < 7`: shifts array left by `days_since`, fills right with zeros.
  - If `days_since = 0`: returns array unchanged (active today).
- No Flutter changes needed.

### Verified
Query confirmed correct shifting:
- User active 9 days ago: `[0,0,0,0,0,0,1]` → `[0,0,0,0,0,0,0]` ✓
- User active today: `[0,0,0,0,0,0,1]` → `[0,0,0,0,0,0,1]` ✓
- User active 5 days ago: `[0,0,0,0,0,0,1]` → `[0,1,0,0,0,0,0]` ✓

---

## [Phase 30: Code Audit — Database Cost & Stream Analysis]
### Goal
Identify patterns that could inflate Supabase database bill (realtime connections, polling streams, excessive queries).

### Findings — see audit below.

---

## [Phase 30: Code Audit — Database Cost & Stream Analysis]

### Supabase Billing Factors
- **Realtime connections** (`.stream(primaryKey:...)`) — each open a persistent WebSocket. Supabase Free tier allows 200 concurrent. Each active user screen with a stream = 1 connection.
- **Polling streams** (`Stream.periodic + asyncMap`) — fire HTTP requests every N seconds regardless of whether data changed.
- **Row reads** — every query counts toward your monthly row read quota.

---

### 🔴 HIGH RISK — Polling Streams (Admin Only, but expensive)

| Stream | Interval | Queries per tick | Issue |
|---|---|---|---|
| `streamDashboardStats()` | 30s | 9 queries (7 counts + revenue RPC + payment count) | 9 DB hits every 30s while admin screen is open |
| `streamTopUsers()` | 60s | 3 queries (results×100 + users + mock_tests) | Fetches 100 results rows every minute |
| `streamTopTests()` | 60s | 2 queries + signed URL generation | Generates signed URLs every minute |
| `streamUsers()` | 60s | 2 queries (users + results) | Runs even when admin isn't looking at user list |

**Fix**: Increase intervals. `streamDashboardStats` → 5 min. `streamTopUsers/Tests` → 10 min. Or replace with manual refresh-on-demand.

---

### 🟡 MEDIUM RISK — Realtime WebSocket Streams

| Stream | Table | Who uses it | Issue |
|---|---|---|---|
| `streamPurchasedTests()` | `access` | Every logged-in user on Library screen | 1 persistent WS per user. Fine for small scale, watch at 1000+ concurrent users |
| `streamUserDetails()` | `users` | Admin user detail screen | Opens WS per admin view — fine |
| `streamUserOrders()` | `access` | Admin user detail screen | Opens WS per admin view — fine |
| `streamUserResults()` | `results` | Admin user detail screen | Opens WS per admin view — fine |
| `streamAllBanners()` | `banner` | Admin banner management | Fine — admin only |
| `streamOffers()` | `offers` | Admin offer list | Fine — admin only |
| `auth_service stream` | `users` | Auth state — always open | Necessary |
| `test_service stream` | `mock_tests` | Store screen | 1 WS per user on store — watch at scale |

---

### 🟡 MEDIUM RISK — `streamPurchasedTests` does extra query on every change

Every time the `access` table changes (for any reason), `streamPurchasedTests` fires an `asyncMap` that queries `mock_tests` again. This means if admin grants access to 10 users at once, each affected user's stream fires a `mock_tests` query.

---

### 🟢 LOW RISK — One-time fetches (fine)

- `fetchAllOrdersWithDetails()` — called once on revenue screen open, not streamed.
- `fetchPaginatedOrders()` — paginated, fine.
- `getUserPerformance()` — single RPC call, fine.
- All `getPaginated*` methods — fine, user-triggered.

---

### Fixes Applied

**`streamDashboardStats`** — interval increased from 30s → 5 minutes.
**`streamTopUsers`** — interval increased from 60s → 10 minutes.
**`streamTopTests`** — interval increased from 60s → 10 minutes.
**`streamUsers`** — interval increased from 60s → 5 minutes.

---

## [Phase 31: Android 15 16KB Memory Page Size Migration & Stability]
### Goal
Migrate the application to support Android 15's 16KB memory page size requirement and resolve associated build/logic regressions.

### What Was Done
- **Isar Migration**: Replaced `isar` with `isar_community` across the project for 16KB page size compatibility.
- **Dependency Upgrades**: 
  - Upgraded to Riverpod 3.0-dev (`flutter_riverpod 3.3.1`, `riverpod_generator 4.0.3`) to meet new `build` package requirements.
  - Upgraded to Freezed 3.0-dev (`freezed 3.2.5`).
- **Code Refactoring**:
  - Renamed `*NotifierProvider` to `*Provider` to align with the latest Riverpod generator conventions.
  - Fixed `Future.wait` type-casting errors in `home_screen.dart`, `free_content_screen.dart`, and `downloads_screen.dart`.
  - Updated `app_router.dart` to use `Ref` instead of the now-internal `AppRouterRef`.
  - Converted all Freezed state classes to `abstract class` to satisfy new Dart 3 mixin requirements.
- **Compliance**: Removed `USE_EXACT_ALARM` permission to satisfy Google Play Store policy rejections.
- **Cleanup**: Deleted corrupted `.g.dart` files and performed a clean build generation.

### Risks / Side Effects
- **Experimental Versions**: Using dev/pre-release versions of core libraries (Riverpod/Freezed) may have unknown edge cases.
- **Build Runner**: `isar_community_generator` is incompatible with stable `freezed`, necessitating the push to 3.0-dev across the stack.

### Resolved and How
- Compiled clean with `dart analyze` reporting 0 errors.
- Successfully generated a release App Bundle (`1.0.3+17`).
- Ready for 16KB alignment verification and Play Store submission.

---

## [Phase 32: Android Storage Permission Fix & Admin File Picker Reliability]
### Goal
Fix admin file picker silently not opening and resolve Google Play storage permission rejection.

### Root Cause — Double isPicking Flag Bug
`MockTestUploadScreen._pickCoverImage` and `_pickQuestionsFile` both manually called `isPicking = true` **before** calling `safePickFiles()`. Since `safePickFiles()` internally checks `if (isPicking) return null;` as its very first line, every button tap was silently returning null without ever opening the system picker. The mixin owns the lifecycle entirely — callers must NOT set `isPicking` manually.

### Root Cause — Missing Storage Permissions
`AndroidManifest.xml` had no storage read/write permissions at all for Android ≤12. While `file_picker` uses SAF on Android 13+, on Android 9 (API 28) and Android 10–12 (API 32) the OS requires explicit permissions for legacy storage path access.

### Files Changed
- **`android/app/src/main/AndroidManifest.xml`**:
  - Added `WRITE_EXTERNAL_STORAGE` (maxSdkVersion=28) for Android 9 and below.
  - Added `READ_EXTERNAL_STORAGE` (maxSdkVersion=32) for Android 10–12.
  - Kept `READ_MEDIA_*` removal entries — not needed for SAF on Android 13+.
  - No `MANAGE_EXTERNAL_STORAGE` — Play Store policy violation, not justifiable.
- **`lib/presentation/screens/mock_test_upload_screen.dart`**:
  - Removed manual `isPicking = true/false` from `_pickCoverImage` and `_pickQuestionsFile`.
  - Moved size check before byte read (correct order: check size → read bytes).
  - Error handling scoped to the byte read only (not the picker call, since safePickFiles handles that).

### Rules Established
- All admin pick methods MUST call `safePickFiles()` directly — never wrap with `isPicking`.
- `admin_resource_form.dart` and `mock_test_edit_screen.dart` were already correct.
- `MockTestUploadScreen` was the only screen with the bug.

### Verified
- `dart analyze` on changed file: 0 issues.
