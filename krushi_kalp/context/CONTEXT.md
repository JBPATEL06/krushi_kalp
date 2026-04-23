# Krushi Kalp App Context

## Project Overview
Krushi Kalp is a Flutter-based educational/agricultural application providing mock tests, resources (ebooks, PYQs, GK), and banners.

## Tech Stack
- Frontend: Flutter, Riverpod, GoRouter
- Backend: Supabase (Auth, Storage, Database)
- PDF: PDF package for report generation

## Phase 17: Layout Reversion (Attempted) (2026-04-21)
- **Goal**: Attempted to revert to "Infinite Vertical Page" layout.
- **Outcome**: Reversion successful but revealed critical platform limits (truncated at 74 questions on most mobile viewers).
- **Status**: SUPERSEDED by Phase 18.

## Phase 18: Multi-Page PDF Stabilization (2026-04-21)
- **Goal**: Final stabilization of PDF generation for long-form tests (105+ questions).
- **Actions**:
    - Replaced `pw.Page` with `pw.MultiPage` using standard A4 format.
    - Added "Page X of Y" numbering for professional navigation.
    - Implemented `mainAxisSize: min` on cards to eliminate massive blank spaces.
    - Removed `dynamicHeight` calculation to bypass platform canvas limits.
- **Result**: Guaranteed visibility of 100% of questions regardless of test length.
- **Status**: FINISHED.

## Phase 19: Layout Optimization (2026-04-21)
- **Goal**: Maximize content density on A4 pages.
- **Actions**: Redesigned header to horizontal, reduced card margins, switched to compact stat cards.
- **Status**: FINISHED.

## Phase 20: Extreme Compaction & Font Fixes (2026-04-22)
- **Goal**: Resolve "Atomic Pagination" white gaps and Helvetica console warnings.
- **Actions**: Explicit font passing to all sub-components, reduced font sizes, removed redundant header padding.
- **Status**: COMPLETE.

## [2026-04-21] Phase 25: Open-Source Table Refactor
- **Goal**: Eliminate "Idiot Space" (large whitespace gaps) by using a non-greedy table architecture.
- **Actions**:
    - Scrapped `Syncfusion` pivot; stuck to open-source `pdf` package for lower cost and easier maintenance.
    - Switched from atomic "Flat Widget List" to `pw.Table` rows for granular page splitting.
    - Forced `NotoSansGujarati` font for all text blocks to eliminate fallback height calculation errors.
- **Outcome**: PDF engine can now split questions across page boundaries between header, text, and options.
- **Status**: COMPLETE.
- Use sequential synchronized execution (await-based) for admin forms (Replaced "Fire and Forget" for reliability).
- Local PDF generation for results: PDFs are now generated and viewed locally to resolve backend latency and handshake errors.
- Single-Page PDF Fix: Increased the PDF page budget to accommodate long-form reports instead of implementing complex pagination, ensuring layout integrity.
- Native Language Support: Auto-translation middleware removed; items now use the original provided language for accuracy.
- Check Answer PDF Style: Standardized PDF results to match the in-app check-answer UI (All options shown).
- Dynamic Font Fallback: NotoSansGujarati is used as a fallback for all PDF text to prevent crashes on non-latin characters.
- PDF Theme Persistence: PDF theme choice (Light/Dark) is now persisted per user via SharedPreferences.

## Phase 26: PDF Viewer Aesthetic Refinement (2026-04-22)
- **Goal**: Resolve "Idiot Space" perception by matching Chrome's professional PDF layout.
- **Actions**:
    - Forced a dark professional grey background (`#323639`) for the viewer to provide contrast against white pages.
    - Optimized `PDFView` for fluid scrolling (`pageFling: true`, `pageSnap: false`).
    - Added floating page indicators for easier navigation.
    - Simplified AppBar UI to keep the focus on the document.
- **Outcome**: The viewer now clearly demarcates page boundaries, eliminating the visual confusion caused by white-on-white page gaps.
- **Status**: COMPLETE.

## Phase 29: PDFrx Pro Migration & Feature Expansion (2026-04-22)
- **Goal**: Superior performance and desktop-grade features (Search, Jump).
- **Actions**:
    - Replaced `flutter_pdfview` with **PDFrx**.
    - Implemented **Interactive Search** with AppBar integration and Next/Prev matches.
    - Added **Go to Page** functionality for long document navigation.
    - Optimized "Total Flattening" generation to ensure the new viewer has absolutely zero pagination gaps.
    - Simplified network loading with native streaming URI support.
- **Outcome**: Premium, high-performance viewing experience with advanced document navigation tools.
- **Status**: COMPLETE.

## Phase 30: PDFrx Stabilization & Layout Crash Fix (2026-04-22)
- **Goal**: Final stabilization of PDFrx viewer and resolution of infinite height PDF generation crashes.
- **Actions**: 
    - Fixed compilation errors in `PdfViewerScreen` and `NetworkPdfViewerScreen`.
    - Refactored `PdfService.buildFlatRow` to use `pw.Table` for safe layout constraints.
    - Cleaned up unused imports and standardized code style.
- **Outcome**: 100% stable PDF generation and viewing workflow.
- **Status**: COMPLETE.

## Phase 31: Data Cleanup & Mock Reset (2026-04-22)
- **Goal**: Wipe all mock tests and resources to prepare for fresh production data.
- **Actions**:
    - Truncated `public.mock_tests` with CASCADE (wiping results, order items, and reviews).
    - Truncated `public.resources` with CASCADE (wiping order items and reviews).
    - Deleted all storage objects in the `mock_test` bucket (Resources, JSON files, Covers, and Results).
- **Outcome**: Database and Storage cleared of all temporary/mock entities.
- **Status**: COMPLETE.

## Completed Phases
- Phase 1: Authentication & Navigation (v1-v4)
- Phase 2: Administrative Stabilization (v5-v7)
- Phase 3: PDF Generation & Localization (v7)
- Phase 4: UX & Cart Refinements (v7)
- Phase 5: Email Authentication Implementation (v8)
- Phase 6: Stabilization & Error Handling (v9)
- Phase 7: Demo Data & Store Optimization (v10)
- Phase 8: Background Transfer UX & Redirection (v11)
- Phase 9: Resiliency & Stability Refinement (v12)
- Phase 10: Notification Visibility & Transfer Persistence (v13)
- Phase 11: Foreground Notification Real-Time Progress (v14)
- Phase 12: Store Rebranding & Data Stability (v15)
- Phase 13: Release Preparation (v16)
- Phase 14: PDF UI Standardization (v17)
- Phase 15: Admin Stabilization & Library Fixes (v18)

## Completed Status Details
- **Email Auth**: Verified profile creation, T&C gating, and duplicate prevention.
- **Stabilization**: Fixed LateInitializationError by replacing `late` fields with safe nullables.
- **Demo Data**: Standardized 15 agriculture items with "2-Free, 1-Paid" pattern.
- **Transfers**: 21-minute retry window, mounted checks, and real-time progress notifications (MIUI-safe).
- **Library**: Fixed visibility for DIRECT_CHECKOUT (Free) items and normalized category mapping.
- **Android 14**: Watchdog timer for foreground services to prevent timeout crashes.
- **PDF**: Copy-to-copy match with English framing and vector status icons.
