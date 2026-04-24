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
Phase 3: Search and Filter implementation (Completed alongside Phase 2)

## Completed Phases
- Initial project structure and core features (Pre-existing)
- Phase 1: Refactor `AdminResourceList` for infinite scroll.
- Phase 2: Refactor `AdminMockTestList` for infinite scroll (Stabilized).
- Phase 3: Implement search and filter in paginated services (Integrated).

## Key Decisions
- Use `infinite_scroll_pagination` package for consistent pagination across the app.
- Refactor Supabase services to support offset-based pagination.

## Known Risks or Constraints
- Supabase pagination requires careful offset/limit management.
- Signed URLs for resources need to be handled during paginated loads.
