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
- **Phase 38**: Search Bar Rendering Fix (In Progress)
- [Phase 38] Resolving white artifact glitch in Downloads screen search bar.
- **Phase 37**: Background Logic Restoration & Startup Stability (Completed)
- [Phase 37] Reverted to UI-isolate based upload logic for stability.
- [Phase 37] Synchronized main() startup to resolve UI lag.
- **Phase 36**: Startup Optimization & Background Resilience (Completed)
- [Phase 36] Eliminated UI lag by removing blocking initializations from main()
- [Phase 36] Fixed background isolate crashes with lightweight notification initialization
- [Phase 36] Increased file size limits to 50MB for all administrative forms
- **Phase 35**: Admin Upload & Notification Stabilization (Completed)
- **Phase 34**: Global UI Polish & Symbol Cleanup (Completed)
- **Phase 33**: Privacy by Default, Manual Notifications & Store Refresh (Completed)
- **Phase 32**: Android Storage Permission Fix & Admin File Picker Reliability (Completed)
- All previous phases (1-31) completed.

## Key Decisions
- **Snapshot Integrity**: Store full item and user snapshots in transaction tables. Fallback to these snapshots in the user library if live records are missing.
- **Robust Parsing**: Use `_parseNum` and `double.tryParse` for all financial data to handle Postgres `numeric` string conversions safely.
- **Timezone Standardization**: Standardized "Today" metrics to use IST (Asia/Kolkata) in both RPCs and UI filters for regional consistency.
- **Access Type Alignment**: Standardize access types between backend RPCs and UI filters ('claimed', 'paid', 'manual_granted').
- **Isar Migration**: Migrated to `isar_community` for Android 15 16KB page size support.
- **Riverpod/Freezed Upgrade**: Upgraded to Riverpod 3.0-dev and Freezed 3.0-dev to support the latest `build` package requirements.
- **State Pattern**: Implemented `abstract class` pattern for Freezed state classes to comply with latest Dart/Freezed requirements.
- **Provider Naming**: Standardized on `*Provider` naming convention for all generated Riverpod notifiers.

## Key Decisions
- **Storage Permissions**: Use `WRITE_EXTERNAL_STORAGE` (maxSdkVersion=28) and `READ_EXTERNAL_STORAGE` (maxSdkVersion=32). Never request `MANAGE_EXTERNAL_STORAGE` — Google Play policy violation.
- **File Picker Pattern**: All admin screens must use `safePickFiles()` from `PickerLifecycleMixin` — never wrap it with manual `isPicking` flags; the mixin manages the flag internally.
- **SAF (Android 13+)**: `file_picker` uses Storage Access Framework on API 33+ automatically — no `READ_MEDIA_*` permissions required.

## Known Risks or Constraints
- **Function Overloading**: Avoid overloading Supabase RPCs to prevent PostgREST ambiguity errors.
- **Snapshot Size**: Increased storage usage for historical auditing.
- **Is_Active Filter**: Must be explicitly applied to all user-side content fetches.
- **Build Version**: Incremented to `1.0.3+17` for the Google Play Store submission.
- **Experimental Versions**: Using pre-release versions of Riverpod and Freezed may introduce unexpected behavior; monitoring is required.
- **16KB Alignment**: Final App Bundle must be verified with `check_align.py` before submission.
