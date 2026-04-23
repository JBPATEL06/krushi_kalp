# Krushi Kalp Context

## Project Overview
- **Name**: Krushi Kalp
- **Goal**: Agriculture Education & Resource Platform
- **Tech Stack**: Flutter, Supabase, Riverpod, Isar

## Current Status
- **Active Branch**: `feature/payment-access-schema`
- **Active Phase**: Phase 10: Final Audit
- **Completed Phases**:
  - Phase 7.7: Dashboard Simplification (Remove Search, Ordering) ✅
  - Phase 7.8: Activity Summary & Full Activity View (Pagination & Search) ✅
  - Phase 8: UI Refinement (Overflows, Decimal Formatting) ✅
  - Phase 9: Manual Access Granting (Fixed ID collisions and Resource filtering) ✅
- **Pending Phases**: 
  - Production Deployment
  - App Store Submission

## Key Decisions
- **Manual Access**: Uses `access_type = 'manual_granted'` in the `access` table.
- **Filtering**: Manual grant screen hides items already owned by the user.
- **Batching**: AdminService uses `upsert` for efficient batch access granting.
- **Decimals**: Standardized to 2 decimal places for price/scores.

## Known Risks / Constraints
- **Supabase Quota**: High volume of manual grants should be batched (implemented).
- **Concurrency**: `upsert` handles potential race conditions on manual grants.
