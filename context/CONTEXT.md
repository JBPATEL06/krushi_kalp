# Krushi Kalp Context

## Project Overview
Krushi Kalp is a comprehensive platform for agriculture-related mock tests e-books and study materials. It features an Admin Dashboard for performance tracking and a User Store for material acquisition.

## Tech Stack
- **Frontend**: Flutter (Riverpod, GoRouter, Hooks)
- **Backend**: Supabase (PostgreSQL, Edge Functions, Auth, Storage)
- **Monitoring**: Firebase Crashlytics
- **Payments**: Razorpay

## Architecture Overview
Follows Clean Architecture:
- `data/`: Services and Repository implementations.
- `domain/`: Models and Repository contracts.
- `presentation/`: Screens, Widgets, and Providers (Riverpod).
- `core/`: Constants, Theme, and App Router.

## Current Active Phase
- Phase 6: Payment & Access Schema Migration (`feature/payment-access-schema`)
  - DB migration: DONE ✅
  - Flutter code migration: PENDING

## Completed Phases
- [x] Phase 1: Background Upload Stabilization (Isolate Refactor)
- [x] Phase 2: User Dashboard Polishing
- [x] Phase 3: Simplified PDF Generation UX (Inline Progress)
- [x] Phase 4: Profile & Feedback Stability (FutureBuilder & Google Link UX)
- [x] Phase 5: Production Release v1.0.1+7 (Signed AAB Generated)
- [x] Phase 6A: DB Schema — payment + access tables (no FK, with snapshots), is_public on mock_tests
- [x] Authentication with Google and Email/Password.
- [x] Play Store Compliance Audit (Privacy Policy, Account Deletion, Encryption).

## Known Risks or Constraints
- **Database Function Overloading**: Caution is needed when creating RPCs to avoid duplicated signatures (PGRST203).
- **Network Stability**: Streams for top performing items can be sensitive to network resets.
