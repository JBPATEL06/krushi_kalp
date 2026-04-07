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
