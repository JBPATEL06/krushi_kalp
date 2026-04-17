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
- Cleaning up mock test detail UI.

## Completed Phases
- [x] Phase 1: Background Upload Stabilization (Isolate Refactor)
- [/] Phase 2: User Dashboard Polishing
- [ ] Phase 3: Analytics Integration
- Store integration with Razorpay.
- Authentication with Google and Email/Password.
- Play Store Compliance Audit (Privacy Policy, Account Deletion, Encryption).

## Known Risks or Constraints
- **Database Function Overloading**: Caution is needed when creating RPCs to avoid duplicated signatures (PGRST203).
- **Network Stability**: Streams for top performing items can be sensitive to network resets.
