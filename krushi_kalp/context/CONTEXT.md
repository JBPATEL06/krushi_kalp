# Project: Krushi Kalp
## Goal
A comprehensive platform for agriculture education and resources.

## Tech Stack
- **Framework**: Flutter
- **Backend**: Supabase
- **State Management**: Provider (inferred from common Flutter patterns, will verify if needed)
- **Design System**: Custom tokens (AppTheme, AppSpacing, AppRadius, etc.)
- **Error Tracking**: Firebase Crashlytics

## Architecture Overview
Clean Architecture:
- **Presentation**: UI screens and widgets
- **Domain**: Entities and repository contracts
- **Data**: API services (Supabase) and repository implementations

## Current Active Phase
- Phase 12.1: Cart Stabilization & Table Sync.

## Completed Phases
- Initial project structure and core features (Pre-existing)
- Phase 1: Refactor AdminResourceList for infinite scroll.
- Phase 2: Refactor AdminMockTestList for infinite scroll (Stabilized).
- Phase 3: Implement search and filter in paginated services (Integrated).
- Phase 4.1: Backend Service Prep (toggle status, fetch users by access type).
- Phase 5: Admin Access Audit & Visibility Integration (Sub-phases 5.1-5.3).
- Phase 6: Payment & Access Schema Migration.
- Phase 7: Razorpay & Checkout Stabilization.
- Phase 8: Razorpay UPI ID Accessibility.
- Phase 9: Resource Visibility Policy Enforced.
- Phase 10: No-FK Refactoring & Supabase v2 Bug Fixes.
- Phase 11: Payment RLS & Accessibility Fixes.
- Phase 12: Payment Status Alignment & Access Fix.
- Phase 12.1: Add to Cart Table Name Fix.

## Key Decisions
- Use `infinite_scroll_pagination` package for consistent pagination across the app.
- Refactor Supabase services to support offset-based pagination.

## Known Risks or Constraints
- Supabase pagination requires careful offset/limit management.
- Signed URLs for resources need to be handled during paginated loads.
