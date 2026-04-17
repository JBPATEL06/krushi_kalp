# Krushi Kalp App Context

## Project Overview
Krushi Kalp is a Flutter-based educational/agricultural application providing mock tests, resources (ebooks, PYQs, GK), and banners.

## Tech Stack
- Frontend: Flutter, Riverpod, GoRouter
- Backend: Supabase (Auth, Storage, Database)
- PDF: PDF package for report generation

## Current Stabilization Phase
- Goal: Fix critical bugs in Admin panel, PDF generation, and UX.
- Admin Panel: RLS policies, high-trust form submission (await-based), and storage access.
- User Part: Unique PDF storage paths, dynamic font loading, and PYQ filters.

## Key Decisions
- Use sequential synchronized execution (await-based) for admin forms (Replaced "Fire and Forget" for reliability).
- Unique PDF storage paths using userId/timestamp for collision prevention.
- Dynamic font loading (NotoSansGujarati) in PdfService for multi-language support.
- RLS policy standardization for 'authenticated' role.

## Completed Phases
- Phase 1: Authentication & Navigation (v1-v4)
- Phase 2: Administrative Stabilization (v5-v7)
- Phase 3: PDF Generation & Localization (v7)
- Phase 4: UX & Cart Refinements (v7)

## Pending Phases
- Cloud Function integration for checkout (v8)
- Real-time notification hardening (v9)

## Current Phase: Email Authentication Implementation
- Goal: Add professional Email/Password auth alongside Google Auth.
- Status: COMPLETE; Verified profile creation, T&C gating, and duplicate prevention.

## Current Phase: Stabilization & Error Handling (2026-04-02)
- Goal: Fix LateInitializationError and refine Auth Error Handling.
- Entities: Fixed `ResourceEntity`, `OfferEntity`, and `MockTestEntity` by replacing `late` fields with safe nullables.
- Auth: Improved error mapping in `ErrorService` and `AuthNotifier` to handle account conflicts gracefully.
- Status: COMPLETE.

## Current Phase: Demo Data & Store Optimization (2026-04-07)
- Goal: Finalize high-fidelity demo environment and stabilize Store data syncing.
- Content: Standardized 15 agriculture items (Mock Tests, E-books, PYQs, Current Affairs, Study Material).
- Pricing: Implemented "2-Free, 1-Paid" pattern with demo branding.
- Syncing: Enabled `forceRefresh: true` in `StoreScreen` to bypass local Isar cache for real-time accuracy.
- Visibility: Removed price filters to ensure all demo content (including free items) is visible in the Shop.
- Stability: Resolved "Unmodifiable list" crashes in sorting logic and fixed Android Predictive Back warnings.
- Status: COMPLETE.
## Current Phase: Background Transfer UX & Redirection (2026-04-07)
- Goal: Stabilize file transfers (Uploads/Downloads) with non-blocking UX.
- Implementation: Immediate redirection and "Safe to Background" feedback after metadata save.
- Backgrounding: Refactored `MockTest` and `Resource` admin forms to offload assets to `BackgroundUploadService`.
- User Feedack: Added initiation SnackBars to `DownloadActionButton` for transparency.
- Optimization: Enforced 1MB limit for Resource cover images; increased background upload timeout to 180s and retries to 5x for stability.
- Status: COMPLETE.
## Current Phase: Resiliency & Stability Refinement (2026-04-08)
- Goal: Fix 70% background transfer failure rate and UI disposal crashes.
- Implementation: Increased background upload retry window to 21 minutes (8x retries, 5s initial delay).
- Stability: Added `mounted` checks to `StoreScreen` and wrapped `AdminService` dashboard streams in `RetryHelper`.
- Status: COMPLETE.
## Current Phase: Notification Visibility & Transfer Stability (2026-04-08)
- Goal: Fix foreground notification visibility and prevent crashing during file selection.
- Implementation: Branch `fix/upload-notification-freeze`.
- Fixes:
  - Channel ID dedicated to `krushi_background_service` with `Importance.high`.
  - Explicit `setAsForegroundService` call in `onStart` for immediate visibility.
  - Added `_isPicking` guards to `AdminResourceForm` and `MockTestEditScreen` to prevent overlapping `FilePicker` calls and the associated `NullPointerException`.
- Status: COMPLETE.
## Current Phase: Resumé-Safe Picking & Notification visibility (2026-04-08)
- Goal: Resolve the MIUI-specific NullPointerException (NPE) and improve progress notification visibility.
- Implementation: Branch `fix/upload-notification-freeze`.
- Strategy:
  - Implement `PickerLifecycleMixin` to reset picking states on app resume.
  - Upgrade notification channel importance for progress tracking.
- Status: COMPLETE.

## Current Phase: Store Rebranding & Data Stability (2026-04-17)
- Goal: Finalize rebranding nomenclature and resolve blank store states.
- Rebranding: Standardized categories to "Daily CA", "Study Material", and "E-Books" across Store, Library, and Downloads.
- Stability: Added manual Refresh mechanism in `StoreScreen` AppBar and Retry buttons in empty states (`StoreResourceGrid`).
- Logic: Standardized category keys in `MyResourcesScreen` and `HomeScreen` navigation mapping.
- Status: COMPLETE.
## Current Phase: Release Preparation (2026-04-17)
- Goal: Increment version and generate production AAB.
- Implementation: Branch `chore/prepare-release-1.0.1-4`.
- Version: `1.0.1+4`.
- Build: Generated `app-release.aab` (69MB).
- Status: COMPLETE.
