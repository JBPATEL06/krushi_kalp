# Krushi Kalp App Context

## Project Overview
Krushi Kalp is a Flutter-based educational/agricultural application providing mock tests, resources (ebooks, PYQs, GK), and banners.

## Tech Stack
- Frontend: Flutter, Riverpod, GoRouter
- Backend: Supabase (Auth, Storage, Database)
- PDF: PDF package for report generation

## Current Phase: Exam Screen Resilience & Error UX (2026-04-21)
- Goal: Resolve Mock Test crashes due to malformed data and improve error navigation.
- Current Phase: Stabilizing Mock Test Reports and PDF Generation
- Completed: Resilient JSON Parsing (Question Model), ExamScreen Error UX, PDF Infinite Scroll Height Fix
- Pending: Final Production Verification in `ExamScreen` (distinguishing data vs network).
    - Enhanced navigation with "Go Back" button in the error state.
- Status: IN_PROGRESS.

## Key Decisions
- Use sequential synchronized execution (await-based) for admin forms (Replaced "Fire and Forget" for reliability).
- Local PDF generation for results: PDFs are now generated and viewed locally to resolve backend latency and handshake errors.
- Single-Page PDF Fix: Increased the PDF page budget to accommodate long-form reports instead of implementing complex pagination, ensuring layout integrity.
- Native Language Support: Auto-translation middleware removed; items now use the original provided language for accuracy.
- Check Answer PDF Style: Standardized PDF results to match the in-app check-answer UI (All options shown).
- Dynamic Font Fallback: NotoSansGujarati is used as a fallback for all PDF text to prevent crashes on non-latin characters.
- PDF Theme Persistence: PDF theme choice (Light/Dark) is now persisted per user via SharedPreferences.

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
