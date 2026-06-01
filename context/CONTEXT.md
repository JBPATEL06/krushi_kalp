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
- **Phase 49**: FIFO Download Queue Service (Completed)
  - Created `DownloadQueueService` singleton — FIFO queue serializes all file downloads one at a time.
  - Routed all user background downloads through serial queue in `download_action_button.dart`.
  - Added visual queue position information to `DownloadActionButton` to show users their current queue status (e.g. `In Queue (#1)`).
  - Resolved unused import warning in `download_action_button.dart`.
  - **Branch**: `feature/phase-48-multi-file-upload-open`

## Completed Phases
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
- **Active Branch**: All recent work is committed to the `bugfxing` branch.
