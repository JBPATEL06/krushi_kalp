# Discussion Log: Krushi Kalp Development

[... previous logs ...]

---

## [Phase 50: Multi-file DB Schema + Models]
### Goal
Allow resources and mock tests to support multiple supplementary files/PDFs using atomic database relations. Define the SQL tables, create the standard Dart domain models, and implement the service CRUD operations.

### Branch
`feature/phase-50-multi-file-db-models` (new branch switched from `feature/phase-48-multi-file-upload-open`)

### Decisions Made
- Proceeded with the **Database Table approach** (Option B) instead of Storage Folder Listing. Database tables ensure atomic database updates (milliseconds instead of slow filesystem moves), granular user RLS select policies on a private bucket, arbitrary rich text display names, and reliable batch reordering.
- The existing fields (`resources.file_url` / `mock_tests.file_path`) remain fully supported as backward-compatible fallbacks if the supplementary tables are empty.

### Files Changed
- **[NEW]** `supabase/20260601_add_multi_file_tables.sql` — SQL migration file containing schemas for `resource_files` and `mock_test_files` tables with cascade deletes and RLS policies.
- **[NEW]** `lib/domain/models/resource_file.dart` — Standard Dart model `ResourceFile` with JSON serialization.
- **[NEW]** `lib/domain/models/mock_test_file.dart` — Standard Dart model `MockTestFile` with JSON serialization.
- **[MODIFIED]** `lib/data/services/resource_service.dart` — Added `fetchResourceFiles`, `addResourceFile`, `deleteResourceFile`, `renameResourceFile`, `reorderResourceFiles`, and dynamic fresh signed URL resolver `_signResourceFiles`.
- **[NEW]** `lib/data/services/mock_test_file_service.dart` — `MockTestFileService` singleton providing mirrored CRUD/signing services for mock test supplementary files.

### Risks / Side Effects
- Requires applying the SQL migration in Supabase Dashboard manually before the next phases run.

### Test Criteria
- `dart analyze` passes with 0 issues on all new and modified files.

### Outcome
- ✅ `dart analyze` 0 issues. Phase 50 complete.

---

## [Phase 49: FIFO Download Queue Service]
### Goal
Prevent multiple simultaneous file downloads. All user background downloads (resource PDFs, mock test covers, questions JSON) must be serialized through a single FIFO queue.

### Branch
`feature/phase-48-multi-file-upload-open`

### Files Changed
- **[NEW]** `lib/data/services/download_queue_service.dart` — `DownloadQueueService` singleton (FIFO Queue, Completer-based awaiting, stream snapshot for UI)
- **[MODIFIED]** `lib/presentation/widgets/common/download_action_button.dart` — Replaced direct background download with `DownloadQueueService().enqueue(QueuedDownloadRequest(...))`. Cleaned up unused crashlytics import. Added stream subscription to display current queue position to the user when downloading.

### Risks / Side Effects
- Queue is in-memory only — if app dies mid-download, next item in queue is lost (same behavior as before).

### Test Criteria
- Trigger 3 downloads → queue position is displayed on the UI (e.g. `In Queue (#1)`, `In Queue (#2)`) and only one download processes at a time.

### Outcome
- ✅ `dart analyze` 0 issues. Phase 49 complete.

---

## [Phase 48: FIFO Upload Queue Service]
### Goal
Prevent multiple simultaneous file uploads. All admin upload operations (resource PDFs, covers, mock test covers, questions JSON) must be serialized through a single FIFO queue.

### Branch
`feature/phase-48-multi-file-upload-open` (new branch from `main`)

### Supabase Storage Discovery (MCP Inspection)
- **Buckets**: 3 total — `mock_test` (private), `app_banners` (public), `banners` (public)
- **Single upload bucket**: `mock_test`
- **Existing resource paths**: `Resources/{type}/file/{timestamp}_{name}.pdf` and `Resources/{type}/cover/{timestamp}_{name}.png`
- **Confirmed new multi-file path convention**: `resources/{id}/file_{n}.pdf` inside `mock_test` bucket
- **Mock test paths stay unchanged**: `mock_test_cover/{id}.jpg`, `mock_test_json_file/{id}.json`

### Files Changed
- **[NEW]** `lib/data/services/upload_queue_service.dart` — `UploadQueueService` singleton (FIFO Queue, Completer-based awaiting, stream snapshot for UI)
- **[MODIFIED]** `lib/presentation/screens/admin/resources/admin_resource_form.dart` — Replaced `BackgroundUploadService().uploadFile(...)` with `UploadQueueService().enqueue(QueuedUploadRequest(...))`
- **[MODIFIED]** `lib/presentation/screens/admin/mock_test_edit_screen.dart` — Same. Also removed unused `supabase` local variable.
- **[MODIFIED]** `lib/presentation/screens/mock_test_upload_screen.dart` — Same. Also removed unused `admin_notification_service.dart` import.

### Risks / Side Effects
- `BackgroundUploadService` is still used internally by `UploadQueueService` — not deprecated.
- Queue is in-memory only — if app dies mid-upload, next item in queue is lost (same behavior as before).

### Test Criteria
- Upload resource PDF + cover → only one uploads at a time (check notification).
- Upload mock test cover + JSON → cover uploads first, then JSON.

### Outcome
✅ `dart analyze` 0 issues. Phase 48 complete and committed.

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
- Successfully generated
- **Phase 35**: Admin Upload & Notification Stabilization (In Progress)
- **Phase 34**: Global UI Polish & Symbol Cleanup (Completed)
- **Phase 33**: Privacy by Default, Manual Notifications & Store Refresh (Completed)
- **Phase 32**: Android Storage Permission Fix & Admin File Picker Reliability (Completed)
- All previous phases (1-31) completed.

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

---

- **UI/UX Refinement**: Corrected corrupted character sequences (â‚¹, â€¢) across 8+ screens. Added manual refresh buttons to Admin and User detail screens for better data synchronization.
- **Privacy Enforcement**: Verified that new items are created as non-public by default, and notifications only fire upon manual "Public" toggle in Admin dashboard.
- **Bug Fixes**: Resolved persistent syntax errors (missing/extra parentheses) and incorrect parameter placements in `AdminMockTestList` and `MockTestDetailScreen`.
- **Status**: Completed.

---

## [Phase 34: Global UI Polish & Symbol Cleanup]
### Goal
Systematically resolve character encoding issues (Rupee symbol and bullet points) and implement explicit refresh buttons across all critical administrative and user-facing detail screens.

### Changes
- **Symbol Fixes**: Replaced corrupted UTF-8 sequences (`â‚¹` → `₹`, `â€¢` → `•`) in:
  - `StoreItemCard`, `StoreGrid`, `StoreResourceGrid`
  - `MockTestDetailScreen`, `ResourceDetailScreen`
  - `DirectCheckoutSheet`, `CartScreen`, `AdminAnalysisScreen`
- **Manual Refresh**:
  - Added `RefreshIndicator` and `AppBar` refresh button to `AdminStoreScreen` / `AdminMockTestList`.
  - Added `AppBar` refresh buttons to `AdminMockTestDetailScreen` and `AdminResourceDetailScreen`.
  - Added `AppBar` refresh button and `RefreshIndicator` to `MockTestDetailScreen`.
  - Added `AppBar` refresh button to `ResourceDetailScreen`.
- **Policy**: Finalized removal of automatic Postgres-based notifications in `NotificationService`.

### Resolved and How
- Consistent rendering of currency and separators across the entire app.
- Admins and users can now manually sync data without waiting for background polling.

---

### [Phase 35: Outcome - Admin Upload & Notification Stabilization]
- **Ghost Notifications**: Audited all creation services. Verified that automated notifications are removed. If they still occur, they must be from an un-indexed DB trigger (User to verify in Supabase Dashboard).
- **Late Initialization (MIUI)**: 
    - **Optimized Pre-warming**: In `main.dart`, the background service now starts **only for Admins**.
    - **Local Role Caching**: Implemented role caching in `AuthService` using `SharedPreferences`. This allows `main.dart` to determine the user's role without a network call.
    - **Zero Overhead for Students**: Normal users (students) skip the pre-warming entirely, saving battery and memory.
    - **Immediate Feedback**: Added immediate local notification feedback in `BackgroundUploadService.uploadFile` (UI Isolate side) so admins see progress instantly.
- **Background Reliability (Edit Sync)**:
    - **Architectural Shift**: Database updates (Supabase `.update()`) for file paths are now handled *inside* the background isolate.
    - **Benefit**: Even if the UI isolate is killed by the OS (common on MIUI/Android 14) while the user is away, the background worker will successfully complete the upload AND update the database record to point to the new file.
- **Files Modified**:
    - `lib/main.dart`: Pre-warming logic.
    - `lib/data/services/background_upload_service.dart`: Isolate-side DB updates and immediate feedback.
    - `lib/presentation/screens/admin/mock_test_edit_screen.dart`: Migration to new background update pattern.
    - `lib/presentation/screens/admin/resources/admin_resource_form.dart`: Migration to new background update pattern.

### Risks / Side Effects
- MIUI aggressive battery management may still kill the service; investigating `foregroundServiceType` and priority.

---

## [Phase 36: Startup Optimization \u0026 Background Resilience]
### Goal
Resolve app startup lag and background isolate crashes occurring on restrictive Android devices (MIUI/Android 14).

### Proposed Changes
- **File**: lib/main.dart
  - **Action**: Deferred initializeService, LocalCachingService, and NotificationService initializations to avoid blocking the main thread.
  - **Action**: Removed 'Pre-warm' service logic that was competing with the UI for resources on launch.
  - **Action**: Updated onStart to use initializeBackground() to prevent permission-related crashes.
- **File**: lib/data/services/notification_service.dart
  - **Action**: Implemented initializeBackground() to skip platform-specific permission calls that require an Activity context.
- **Files**: BackgroundUploadService.dart, DownloadService.dart
  - **Action**: Throttled progress updates from 5% to 10% to reduce bridge overhead.
  - **Action**: Implemented a 'Wait-for-Readiness' loop to ensure the background engine is ready before processing tasks.
- **Admin Forms**: 
  - **Action**: Increased file size limits from 1MB to 50MB in MockTestUploadScreen, AdminResourceForm, and MockTestEditScreen.

### Risks / Side Effects
- Users might see an 'Initializing...' notification for a few seconds longer if the device is slow, but the app remains responsive.

### Resolved and How
- App launches instantly.
- Background uploads/downloads no longer crash the isolate engine.
- Admins can now upload high-quality assets.

---

## [Phase 37: Background Logic Restoration & Startup Stability]
### Goal
Revert the background upload architecture from a separate isolate-based model to a UI-isolate-based model protected by a foreground service. This resolves NullPointerException crashes, the "stuck at 1%" progress issue, and UI lag.

### Proposed Changes
- **File**: `lib/data/services/background_upload_service.dart`
  - **Action**: Move upload and DB update logic back to the main isolate in `uploadFile`.
  - **Action**: Remove `performUploadTask` static method.
  - **Action**: Use `invoke('updateProgress')` only for notification updates.
- **File**: `lib/main.dart`
  - **Action**: Simplify `onStart` by removing heavy initializations (Firebase, Supabase).
  - **Action**: Remove the `startUpload` listener.
  - **Action**: Await `LocalCachingService.init()` and `initializeService()` in `main()` for stability.
- **File**: `lib/data/services/notification_service.dart`
  - **Action**: Ensure lazy initialization of Supabase/Firestore.

### Risks / Side Effects
- Uploads are now managed by the UI isolate; while the foreground service protects the process, extremely aggressive battery management might still kill the UI isolate if the app is minimized for very long periods. However, this is the pattern used successfully in `DownloadService`.

### Test Criteria
- Admin upload starts immediately (no "1%" stuck).
- Progress notification updates correctly.
- DB updates correctly upon completion.
- No `NullPointerException` in logs during service start.
- App startup is smooth and consistent.


---

## [Phase 38: Search Bar Rendering Fix]
### Goal
Resolve the UI rendering glitch in the `DownloadsScreen` search bar where white corners/edges were visible around the rounded purple input field.

### Proposed Changes
- **File**: `lib/presentation/widgets/common/modern_card.dart`
  - **Action**: Add `clipBehavior` property to `ModernCard` and apply it to the internal `Container`.
- **File**: `lib/presentation/screens/downloads_screen.dart`
  - **Action**: Refactor search bar to use `ModernCard` background exclusively.
  - **Action**: Set `filled: false` in `InputDecoration` to prevent redundant background rendering.
  - **Action**: Use `theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)` for card background.

### Risks / Side Effects
- None. Improved visual integrity.

### Test Criteria
- Search bar renders with smooth rounded corners.
- No white artifacts visible on the edges.
- Theme consistency maintained.

---

## [Phase 39: Image Consistency & Responsiveness Fix]
### Goal
Standardize image rendering across the app to ensure all list items and detail headers have a uniform, premium, and responsive appearance. Eliminate "letterboxing" and inconsistent widths in item cards.

### Proposed Changes
- **File**: `lib/presentation/screens/store/widgets/store_item_card.dart`
  - **Action**: Change `BoxFit.contain` to `BoxFit.cover` in `_buildImage`.
- **File**: `lib/presentation/widgets/common/download_item_card.dart`
  - **Action**: Change `BoxFit.contain` to `BoxFit.cover` in `_buildImage`.
  - **Action**: Update docstring to correctly describe the implementation.
- **File**: `lib/presentation/screens/resource_detail_screen.dart`
  - **Action**: Change `BoxFit.contain` to `BoxFit.cover` in `_buildImageHeader` for an immersive header feel.

### Risks / Side Effects
- Minor cropping of edges for images that don't match the fixed aspect ratios. This is acceptable for UI consistency.

### Test Criteria
- All store item cards have uniform image widths.
- No empty spaces or letterboxing in card images.
- Resource detail header fills the entire width of the device.
- Images remain sharp and properly centered.

---

## [Phase 40: Performance Streak Logic Fix]
### Goal
Refactor the `update_user_streak` database function to align with industry standards and fix logic errors in weekly history tracking.

### Proposed Changes
- **Database Function**: `update_user_streak`
  - **Change 1**: Use IST Timezone (`Asia/Kolkata`) for all date comparisons to ensure streak accuracy for Indian users.
  - **Change 2**: Implement dynamic "Weekly Shifting" logic. If a user is absent for $N$ days, the weekly minutes array shifts by $N$ positions instead of being wiped out.
  - **Change 3**: Ensure the "Add" logic correctly handles same-day activity by accumulating minutes.
  - **Change 4**: Standardize trigger threshold (5 minutes for reading, any for tests).

### Risks / Side Effects
- Users might see their weekly heatmap change slightly as the "wiping" behavior is replaced by a "shifting" behavior. This is an improvement, not a loss of data.
- Transitioning to IST might cause a one-time "double-day" or "missed-day" for users currently in a different DB timezone, but stabilizes the experience moving forward.

### Test Criteria
- Activity on the same day updates minutes but doesn't increment streak count.
- Activity on the next day increments streak and shifts the weekly array by 1.
- Activity after 3 days resets streak to 1 and shifts the weekly array by 3.
- Heatmap values correctly represent the last 7 days.

---

## [Phase 41: Profile UI Cleanup]
### Goal
Remove the "Link Google Account" option from the Profile Screen to simplify the user experience and align with updated authentication requirements.

### Proposed Changes
- **File**: `lib/presentation/screens/profile_screen.dart`
  - Remove the `isGoogleLinked` logic.
  - Remove the `_buildProfileOption` widget for linking Google accounts.
  - Clean up unused imports or variables if any (e.g., `providers`).

### Risks / Side Effects
- Users who signed up via Email will no longer see the option to link their Google account from within the profile screen. They can still use their primary login method.

### Test Criteria
- Navigate to the Profile screen.
- Verify that the "Link Google Account" option is no longer visible, regardless of the login method used.

---

## [Phase 42: Global Encoding & Typography Fix]
### Goal
Identify and correct mis-encoded characters (mojibake) across the codebase. These often appear as `âœ¨` instead of emojis or `â†’` instead of arrows, which detracts from the premium feel of the application.

### Proposed Changes
- **Identify Patterns**:
  - `âœ¨` -> ✨ (Sparkles)
  - `ðŸ¥³` -> 🥳 (Partying Face)
  - `ðŸŽ‰` -> 🎉 (Party Popper)
  - `â†’` -> → (Right Arrow)
  - `â€”` -> — (Em Dash)
  - `â”€` -> ─ (Box Drawing Light Horizontal)
- **Files to Fix**:
  - `lib/presentation/screens/cart_screen.dart`
  - `lib/presentation/widgets/direct_checkout_sheet.dart`
  - `lib/presentation/screens/test_result_screen.dart`
  - `lib/presentation/screens/home_screen.dart`
  - And others identified via grep.

### Risks / Side Effects
- Minor: If a character is replaced incorrectly, it might change the intended symbol. Double-checking with common Latin-1 to UTF-8 mojibake patterns is essential.

### Test Criteria
- Verify the "Store sale discounts" message in the Cart shows the ✨ emoji.
- Verify the "Purchase Complete" message shows the 🥳 emoji.
- Verify that separator lines in comments/docs are readable (or replaced with standard dashes).

**Status: Resolved**
- Fixed major UI artifacts in `cart_screen.dart` and `direct_checkout_sheet.dart`.
- Cleaned up typography artifacts in `test_result_screen.dart`, `resource_detail_screen.dart`, and `pdf_viewer_screen.dart`.
- Fixed comment separators in `home_screen.dart`.

---

## Phase 43: Global Local Time Standardization

### Goal
Standardize the use of Local Time (IST) throughout the application to match the user's regional context (India/Gujarat) and simplify database reporting.

### Scope
- Remove `.toUtc()` from all data submission logic in `TestService`, `CartService`, `OfferService`, `AdminNotificationService`, etc.
- Standardize on `DateTime.now()` (local) for all timestamps.
- Audit admin screens to ensure date picking and saving respects local time.

### Risks
- Dependency on device clock accuracy.
- Database records will store timestamps with local hours (if offset is handled correctly) or the DB will store as UTC but we will treat as local.

### Files to Modify
- `lib/data/services/test_service.dart`
- `lib/data/services/cart_service.dart`
- `lib/data/services/offer_service.dart`
- `lib/data/services/admin_notification_service.dart`
- `lib/data/services/review_service.dart`
- `lib/data/services/resource_service.dart`
- `lib/presentation/screens/admin/admin_offer_manage_screen.dart`
- `lib/presentation/screens/admin/resources/admin_resource_form.dart`

---

## [Phase 44: Global Pagination Standardization]
### Goal
Optimize application performance and Supabase bandwidth usage by implementing infinite scroll pagination across all list-heavy screens.

### Proposed Changes
- **Services Update (Infrastructure)**:
  - `lib/data/services/review_service.dart`: Update `getAllReviews` to support `offset` and `limit`.
  - `lib/data/services/chat_service.dart`: Add paginated fetching for conversations.
  - `lib/data/services/test_service.dart`: Verify/Add pagination support for all list methods.
  - `lib/data/services/resource_service.dart`: Verify/Add pagination support for all list methods.
- **UI Refactoring**:
  - Transition `StoreScreen`, `FreeContentScreen`, `MyLibraryScreen`, `ScoreScreen`, `AdminReviewsScreen`, and `AdminChatListScreen` from `ListView` to `PagedListView`.
  - Use `PagingController<int, dynamic>` for state management in each screen.

### Risks / Side Effects
- **State Fragmentation**: Since we are moving away from full-list providers in some areas, we must ensure search and filter logic remains reactive.
- **UX Consistency**: Standardize loading and error indicators using `PagedChildBuilderDelegate`.

### Test Criteria
- Scroll to bottom triggers next page load.
- Pull-to-refresh correctly resets the paging controller.
- Search queries correctly reset and paginate the filtered results.
- No memory spikes or UI lag when scrolling through large lists.

**Status: Resolved**
- Migrated `StoreScreen` to use 5 distinct `PagingController` objects for categories.
- Refactored `StoreGrid` and `StoreResourceGrid` to use `PagedSliverList` with metadata caching.
- Migrated `FreeContentScreen`, `MyLibraryScreen`, `ScoreScreen`, `AdminReviewsScreen`, `AdminChatListScreen`, `PurchasedTestsScreen`, and `MyResourcesScreen` to `PagedListView` or `PagedSliverList`.
- Standardized `fetchPaginated...` pattern in `TestService`, `ResourceService`, `ReviewService`, and `AdminService`.
- Integrated search debouncing and refresh logic with all paginated controllers.
- Fixed typography artifacts in `AllTestsScreen`.

---

## [Phase 46: System UI Integrity & Device Compatibility]
### Goal
Audit and implement `MediaQuery` bottom padding across all screens to prevent system navigation bar overlap and ensure consistent UI spacing on devices with gesture navigation.

### Proposed Changes
- **File**: `lib/presentation/widgets/common/safe_bottom_padding.dart`
  - **Action**: Create a utility widget that wraps content in `Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom))`.
- **Files to Update**:
  - `lib/presentation/screens/cart_screen.dart`
  - `lib/presentation/screens/profile_screen.dart`
  - `lib/presentation/screens/downloads_screen.dart`
  - `lib/presentation/screens/home_screen.dart`
  - Any screen utilizing fixed-position bottom action bars or floating buttons.

### Risks / Side Effects
- Minor: Potential double-padding if not carefully integrated with existing `Scaffold` `bottomNavigationBar` slots.

### Test Criteria
- Verify that content at the bottom of the screen is not obscured by the system navigation bar.
- Ensure smooth scrolling continues to show the last items without interference.

**Status: Resolved**
- Audited and updated bottom paddings using `MediaQuery.of(context).padding.bottom` across all core screens.
- Added padding to dynamic lists in `AdminUserDetailsScreen`, `AdminGrantAccessScreen`, `AdminUserListScreen`, `AdminReviewsScreen`, `AdminOrderListScreen`, and `AdminOfferListScreen`.
- Ensured bottom navigation bar padding in `PdfViewerScreen` accurately accommodates Android 15 gestures.
- Validated existing padding configurations across action buttons and detail views.

---

## [Phase 45: Global Error Handling and Observability]
### Goal
Standardize user-facing error feedback and ensure comprehensive developer observability by integrating Firebase Crashlytics and a centralized error UI widget.

### Proposed Changes
- **Core Improvements**:
  - `lib/data/services/error_service.dart`: Enhanced error translation logic for human-readable messages.
  - `lib/presentation/widgets/common/network_error_state.dart`: Refactored to support generic errors, pass-through error objects, and dynamic iconography.
- **Service-Level Audit**:
  - Integrated `CrashlyticsService.instance.recordError` in `AdminService`, `BannerService`, `CartService`, `ChatService`, and `NotificationService`.
- **UI Standardization**:
  - Replaced raw error displays in `CartScreen`, `NotificationsScreen`, `AdminAnalysisScreen`, `AdminUserDetailsScreen`, and `BannerManagementTab` with `NetworkErrorState`.
  - Ensured `onRetry` callbacks correctly refresh state/data.

### Risks / Side Effects
- **Error Silencing**: Risk of over-simplifying error messages. Mitigated by ensuring Crashlytics captures the full raw exception for debugging.
- **State Stale-ness**: Ensured that "Retry" actions properly re-trigger the necessary service calls or stream refreshes.

### Test Criteria
- Force a network failure: Verify "No Internet" screen appears with troubleshooting tips.
- Force a logic error: Verify "Something went wrong" appears without technical details.
- Verify Crashlytics: Ensure stack traces and custom 'reason' strings are correctly reported to the Firebase Console.

**Status: Resolved**
- Centralized error UI is consistent across all main modules.
- Services are fully instrumented for error reporting.
- Walkthrough documentation created in artifacts.

---

## [Phase 46: System UI Padding Standardization]
### Goal
Ensure all scrollable screens and list views respect the Android 15 gesture navigation bar insets, preventing content from being clipped behind the system navigation bar.

### Files Modified
- `lib/presentation/screens/admin/admin_user_details_screen.dart`
- `lib/presentation/screens/admin/admin_grant_access_screen.dart`
- `lib/presentation/screens/admin/admin_user_list_screen.dart`
- `lib/presentation/screens/admin/admin_reviews_screen.dart`
- `lib/presentation/screens/admin/admin_order_list_screen.dart`
- `lib/presentation/screens/admin/admin_offer_list_screen.dart`
- `lib/presentation/screens/pdf_viewer_screen.dart`
- `lib/presentation/screens/purchased_tests_screen.dart` (critical syntax fix)

### Decision
Use `EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md)` as the standard bottom padding for all `PagedListView`, `ListView`, and `CustomScrollView` instances. This is the project-wide standard going forward.

### Risks Identified
- A syntax error was introduced in `purchased_tests_screen.dart` during the padding refactor — the `itemBuilder` closure in `PagedChildBuilderDelegate` was missing. This was fixed and verified with `dart analyze` (no issues found).

### Test Criteria
- On a device with gesture navigation enabled, the last list item should not be hidden behind the navigation bar.
- `dart analyze` returns zero issues on all modified files.

**Status: Resolved**
- All identified screens updated. `purchased_tests_screen.dart` syntax error patched and committed.
- Committed to `bugfxing` branch.

---

## [Phase 47: Pull-to-Refresh Standardization]
### Goal
Remove all manual refresh buttons (AppBar `IconButton`, inline `TextButton`) from every screen in the app and replace them with standard pull-to-refresh (`RefreshIndicator`) patterns.

### Rule Established
> **Manual refresh buttons in AppBar or inline headers are forbidden.** All list and detail screens must use `RefreshIndicator`. Screens using `SingleChildScrollView` must also be wrapped with `RefreshIndicator` + `AlwaysScrollableScrollPhysics`.

### Audit Results

| Screen | Had Manual Button | Had PTR | Action Taken |
|---|---|---|---|
| `score_screen.dart` | ✅ AppBar icon | ✅ | Removed AppBar icon |
| `my_library_screen.dart` | ✅ AppBar icon | ✅ | Removed AppBar icon |
| `free_content_screen.dart` | ✅ AppBar icon | ✅ | Removed AppBar icon |
| `mock_test_detail_screen.dart` | ✅ SliverAppBar icon | ✅ | Removed SliverAppBar icon |
| `admin_mock_test_detail_screen.dart` | ✅ AppBar icon | ❌ | Removed icon + Added PTR |
| `admin_resource_detail_screen.dart` | ✅ AppBar icon | ❌ | Removed icon + Added PTR |
| `admin_store_screen.dart` | ✅ AppBar icon | ✅ (child) | Removed AppBar icon |
| `admin_offer_list_screen.dart` | ✅ AppBar icon | ❌ | Removed icon + Added PTR |
| `admin_chat_list_screen.dart` | ✅ Inline TextButton | ✅ | Removed inline button |
| `store_screen.dart` | ✅ AppBar icon | partial | Removed icon + Added physics |

### Intentionally Skipped
- `maintenance_screen.dart` — standalone CTA button for app restart, not a list.
- `banner_management_tab.dart` — refresh button re-fetches remote app config (not the stream).
- `store_resource_grid.dart` — retry button in error/empty state, not a top-level header.

### Risks Identified
- None. All changes are purely UI-layer with no logic changes.

### Test Criteria
- No `Icons.refresh` in AppBar `actions` on any screen.
- Pull-down gesture triggers reload on all list and detail screens.
- `dart analyze` returns zero issues.

**Status: Resolved**
- All 10 screens updated. `dart analyze` confirmed zero issues.
- Committed to `bugfxing` branch as `[Phase 47] Replace all manual refresh buttons with pull-to-refresh across all screens`.

---
