# Project: Krushi Kalp
## Goal
A comprehensive platform for agriculture education and resources.

## Tech Stack
- **Framework**: Flutter
- **Backend**: Supabase (PostgreSQL)
- **State Management**: Riverpod (Notifiers)
- **Design System**: Custom tokens (AppTheme, AppSpacing, AppRadius, etc.)
- **Error Tracking**: Firebase Crashlytics

## Architecture Overview
Clean Architecture:
- **Presentation**: UI screens (ConsumerStatefulWidget) and Riverpod Notifiers.
- **Domain**: Entities (MockTest, Resource, UserPerformance) and repository contracts.
- **Data**: Services (Supabase/PostgREST) and Local Caching (Isar).

## Current Active Phase
- None. Phase 61 completed. Awaiting next phase.

## Previous Active Phase (Completed)
- **Phase 61**: Home Screen Category Card Navigation Fix (Completed)
  - Replaced all 4 broken category card `onTap` entitlement checks in `home_screen.dart → _buildCategoryGrid()` to use `resourceState.purchasedResources.any((r) => r.type == ResourceType.X)` instead of cross-referencing public store lists.
  - Added `import '../../domain/models/resource.dart';` to expose `ResourceType` enum inline.
  - Applies to: Daily CA (`currentAffair`), E-Books (`eBook`), Study Material (`studyMaterial`), PYQs (`pyq`). Mocks and Free Material were already correct.
  - **Branch**: `fix/home-library-navigation` ✅ committed & pushed.

## Phase 60 (Completed)
- **Phase 60**: eBook Multi-Uploads, Access Visibility, Admin PDF Downloads, and Sales Discrepancy Fixes (Completed)
  - Resolved multi-file upload limit bug by appending the loop index `i` to the upload `taskId` in both `AdminResourceForm` and `MockTestEditScreen` to prevent FIFO queue deduplication.
  - Fixed manual access library visibility bug for non-public eBooks/tests (where `resources.is_active = false` or `mock_tests.is_public = false` but user entitlement `access.is_active = true`) by fetching the live database snapshot dynamically in `AdminGrantAccessScreen` before storing the entitlement in the `access` table. This allows the student's Library screen to cleanly fall back on the snapshot when visibility is toggled off.
  - Fixed admin PDF download failure in `ResourceHelper.openResource` by fetching a fresh signed URL from Supabase dynamically using `SupabaseUrlHelper` prior to download initialization.
  - Aligned resource and test sales calculations in `AdminService` to check for `access_type = 'paid'` to filter out free claims and manual admin grants from the sales count.
  - Built the new admin queue monitor screen `AdminUploadQueueScreen` displaying real-time upload progress with cancellation options, adding a quick access dashboard card in `AdminHomeScreen` and a status badge inside `AdminMainScreen` AppBar actions.
  - **Branch**: `fix/android-jvm-ndk-compat` (existing branch)

## Completed Phases
- **Phase 60**: eBook Multi-Uploads, Access Visibility, Admin PDF Downloads, and Sales Discrepancy Fixes (Completed)
  - Resolved multi-file upload limit bug by appending the loop index `i` to the upload `taskId` in both `AdminResourceForm` and `MockTestEditScreen` to prevent FIFO queue deduplication.
  - Fixed manual access library visibility bug for non-public eBooks/tests by fetching the live database snapshot dynamically in `AdminGrantAccessScreen` before storing the entitlement in the `access` table. This allows the student's Library screen to cleanly fall back on the snapshot when visibility is toggled off.
  - Fixed admin PDF download failure in `ResourceHelper.openResource` by fetching a fresh signed URL from Supabase dynamically using `SupabaseUrlHelper` prior to download initialization.
  - Aligned resource and test sales calculations in `AdminService` to check for `access_type = 'paid'` to filter out free claims and manual admin grants from the sales count.
  - Built the new admin queue monitor screen `AdminUploadQueueScreen` displaying real-time upload progress with cancellation options, adding a quick access dashboard card in `AdminHomeScreen` and a status badge inside `AdminMainScreen` AppBar actions.
  - **Branch**: `fix/android-jvm-ndk-compat` (existing branch)
- **Phase 59**: Gradle Wrapper & Caches Synchronization (Completed)
  - Resolved `NullPointerException` in Gradle wrapper by synchronizing the fully extracted gradle wrapper distribution files (`gradle-8.14`, `gradle-8.13`, etc.) and cache configurations from the `C:` drive (`C:\Users\Jeel\.gradle`) to the persistent `F:` cache directory (`F:\gradleAppRun\.gradle`) via `robocopy`.
  - Switched off/stopped the Gradle daemon and synchronized the dependency caches completely, resolving secondary workspace metadata errors.
  - Successfully verified compile via `flutter build apk --debug`.
- **Phase 58**: Cross-Drive Cache Compilation Fix (Completed)
  - Resolved Kotlin compilation different-roots error (`IllegalArgumentException`) by creating `F:\gradleAppRun` on the `F:` drive, migrating `C:\Users\Jeel\.gradle` and `C:\Users\Jeel\AppData\Local\Pub\Cache` contents there, and setting user environment variables `GRADLE_USER_HOME` and `PUB_CACHE` to persist cache on the `F:` drive.
  - **Branch**: `fix/android-jvm-ndk-compat`

- **Phase 57**: Kotlin compilerOptions Migration (Completed)
  - Migrated legacy `kotlinOptions` configuration to the modern `compilerOptions` DSL in both root and app-level Gradle build scripts to support Kotlin 2.2.20. Realigned Android Gradle Plugin to 8.9.1 and mapped the Gradle Wrapper to local Gradle 8.12 package to avoid slow internet downloads.
  - **Branch**: `fix/android-jvm-ndk-compat`

- **Phase 56**: Downloads Screen Files Navigation (Completed)
  - Unified local downloads dashboard to navigate users directly to files repository screens rather than directly opening raw single files, allowing access to multi-file supplementary PDFs offline.
  - **Branch**: `feature/phase-56-downloads-files-navigation`

- **Phase 55**: Context & Global Rules Update + Commit All (Completed)
  - Finalize documentation, update context files, and commit/push all Phase 54/55 changes cleanly.
  - **Branch**: `feature/phase-54-user-resource-files`

- **Phase 54**: User-Side — Open Resource Screen (Completed)
  - Created a new user screen `ResourceFilesScreen` showcasing all attached resource files with backward-compatibility falling back to legacy single PDF.
  - Replaced the direct PDF download buttons and actions in `MyResourcesScreen`, `ResourceDetailScreen`, and `StoreResourceGrid` with premium "Open" action buttons navigating to the files repository screen.
  - Resolved all static analysis errors/warnings in modified screens to confirm 0 issues.
  - **Branch**: `feature/phase-54-user-resource-files`

- **Phase 53**: User-Side — Open Mock Test Screen (Completed)
  - Created a new user screen `MockTestFilesScreen` displaying test covers, stats, a primary full-width attempt CTA, and background queued supplementary downloads using the FIFO download queue.
  - Replaced the direct download buttons in `PurchasedTestsScreen` cards and Store grids with outlined "Open" CTAs that smoothly redirect to this files screen.
  - **Branch**: `feature/phase-53-user-mock-test-files`

- **Phase 52**: Admin Multi-file Mock Test Upload UI (Completed)
  - Added "SUPPLEMENTARY FILES (OPTIONAL)" section to MockTestEditScreen supporting multi-file PDF picking, displaying pending files, and background uploading via FIFO queue.
  - Implemented supplementary files section in AdminMockTestDetailScreen with a premium 3-dots actions menu (Rename, Replace, and Delete) mirroring the premium flow for Resources.
  - **Branch**: `feature/phase-52-mock-test-supplementary-files`

- **Phase 51**: Admin Multi-file Resource Upload UI (Completed)
  - Integrated supplementary files support inside the Admin Resource Form (`admin_resource_form.dart`).
  - Added an "Add Supplementary File" multi-file picker option that enqueues background uploads and inserts records into the `resource_files` table.
  - Implemented a premium management section in the Admin Resource Detail Screen (`admin_resource_detail_screen.dart`).
  - Created a compact, high-trust 3-dots popup menu on supplementary file rows to instantly Rename, Replace (upload upsert), and Delete files with zero lag.
  - **Branch**: `feature/phase-51-admin-multi-file-resource-upload`

- **Phase 50**: Multi-file DB Schema + Models (Completed)
  - Created Supabase SQL migration for `resource_files` and `mock_test_files` supplementary tables.
  - Implemented domain models `ResourceFile` and `MockTestFile`.
  - Added full supplementary files CRUD (fetch, add, delete, rename, reorder) to `ResourceService`.
  - Created `MockTestFileService` to support supplementary test file CRUD operations.
- **Phase 49**: FIFO Download Queue Service (Completed)
  - Created `DownloadQueueService` singleton — FIFO queue serializes all file downloads one at a time.
  - Routed all user background downloads through serial queue in `download_action_button.dart`.
  - Added visual queue position information to `DownloadActionButton` to show users their current queue status (e.g. `In Queue (#1)`).
  - Resolved unused import warning in `download_action_button.dart`.
- **Phase 48**: FIFO Upload Queue Service (Completed)
  - Created `UploadQueueService` singleton — FIFO queue serializes all file uploads one at a time.
  - Routes all admin uploads through serial queue: `admin_resource_form.dart`, `mock_test_edit_screen.dart`, `mock_test_upload_screen.dart`.
  - **Storage structure confirmed** (Supabase MCP inspection):
    - Single private bucket: `mock_test`
    - Existing resource paths: `Resources/{type}/file/{timestamp}_{name}.pdf`
    - New multi-file path convention: `resources/{id}/file_{n}.pdf` (inside `mock_test` bucket)
    - Mock test paths: `mock_test_cover/{id}.jpg` / `mock_test_json_file/{id}.json` (unchanged)
- **Phase 46**: System UI Padding Standardization (Completed)
  - Implemented `MediaQuery.of(context).padding.bottom` across all list/scroll screens to prevent UI clipping by Android 15 gesture navigation bar.
  - Fixed critical syntax error in `PurchasedTestsScreen` `itemBuilder` that caused a compilation failure.
  - Applied consistent padding to admin modules: `AdminUserDetailsScreen`, `AdminGrantAccessScreen`, `AdminUserListScreen`, `AdminReviewsScreen`, `AdminOrderListScreen`, `AdminOfferListScreen`, and `PdfViewerScreen`.
- **Phase 45**: Global Error Handling and Observability (Completed)
  - Standardized error feedback with `NetworkErrorState` widget across all screens.
  - Integrated `CrashlyticsService.instance.recordError` in all core services.
- **Phase 44**: Global Pagination Standardization (Completed)
  - Implemented `infinite_scroll_pagination` across all list-heavy screens.
- **Phase 43**: Global Local Time Standardization (Completed)
  - Removed `.toUtc()` across all services/screens; app uses IST for all logic.
- **Phase 42**: Global Encoding & Typography Fix (Completed)
- **Phase 41**: Profile UI Cleanup (Completed)
- **Phase 40**: Streak Logic (IST) Refactor (Completed)
- **Phase 39**: BoxFit.cover Standardization (Completed)
- **Phase 38**: Search Bar Rendering Fix (Completed)
- **Phase 37**: Background Logic Restoration & Startup Stability (Completed)
- **Phase 36**: Startup Optimization & Background Resilience (Completed)
- **Phase 35**: Admin Upload & Notification Stabilization (Completed)
- **Phase 34**: Global UI Polish & Symbol Cleanup (Completed)
- **Phase 33**: Privacy by Default, Manual Notifications & Store Refresh (Completed)
- **Phase 32**: Android Storage Permission Fix & Admin File Picker Reliability (Completed)
- All previous phases (1–31) completed.

## Key Decisions
- **Snapshot Integrity**: Store full item and user snapshots in transaction tables. Fallback to these snapshots in the user library if live records are missing.
- **Robust Parsing**: Use `_parseNum` and `double.tryParse` for all financial data to handle Postgres `numeric` string conversions safely.
- **Timezone Standardization**: Standardized "Today" metrics to use IST (Asia/Kolkata) in both RPCs and UI filters.
- **Access Type Alignment**: Standardize access types between backend RPCs and UI filters ('claimed', 'paid', 'manual_granted').
- **Isar Migration**: Migrated to `isar_community` for Android 15 16KB page size support.
- **Riverpod/Freezed Upgrade**: Upgraded to Riverpod 3.0-dev and Freezed 3.0-dev to support the latest `build` package requirements.
- **State Pattern**: Implemented `abstract class` pattern for Freezed state classes to comply with latest Dart/Freezed requirements.
- **Provider Naming**: Standardized on `*Provider` naming convention for all generated Riverpod notifiers.
- **Storage Permissions**: Use `WRITE_EXTERNAL_STORAGE` (maxSdkVersion=28) and `READ_EXTERNAL_STORAGE` (maxSdkVersion=32). Never request `MANAGE_EXTERNAL_STORAGE` — Google Play policy violation.
- **File Picker Pattern**: All admin screens must use `safePickFiles()` from `PickerLifecycleMixin`.
- **SAF (Android 13+)**: `file_picker` uses Storage Access Framework on API 33+ automatically — no `READ_MEDIA_*` permissions required.
- **Pull-to-Refresh Pattern**: All scrollable list screens must use `RefreshIndicator`. Manual refresh `IconButton`/`TextButton` in AppBar or inline headers are **forbidden**. Non-list detail screens (e.g., `SingleChildScrollView`) must also wrap with `RefreshIndicator`.
- **System UI Padding Pattern**: All list/scroll views must apply `EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md)` to their list padding.

## Known Risks or Constraints
- **Function Overloading**: Avoid overloading Supabase RPCs to prevent PostgREST ambiguity errors.
- **Snapshot Size**: Increased storage usage for historical auditing.
- **Is_Active Filter**: Must be explicitly applied to all user-side content fetches.
- **Build Version**: Incremented to `1.0.3+17` for the Google Play Store submission.
- **Experimental Versions**: Using pre-release versions of Riverpod and Freezed may introduce unexpected behavior; monitoring is required.
- **16KB Alignment**: Final App Bundle must be verified with `check_align.py` before submission.
- **Active Branch**: `fix/home-library-navigation` ✅ Phase 61 complete
- **Entitlement Source of Truth**: Always use `purchasedResources` (from `access` table) for any check that determines whether a user has access to a category. Never use the public store lists (`ebooks`, `studyMaterials`, etc.) for entitlement checks — they exclude non-public items.
