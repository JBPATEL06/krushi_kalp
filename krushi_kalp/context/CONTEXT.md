# Krushi Kalp App Context

## Project Overview
Krushi Kalp is a Flutter-based educational/agricultural application providing mock tests, resources (ebooks, PYQs, GK), and banners.

## Tech Stack
- Frontend: Flutter, Riverpod, GoRouter
- Backend: Supabase (Auth, Storage, Database)
- Completed Phases:
- [x] Phase 7.7: Dashboard Simplification (Remove Search, Ordering)
- [x] Phase 7.8: Activity Summary & Full Activity View (Pagination & Search)
- [x] Phase 8.1: Fix RenderFlex Overflow in User Details
- [x] Phase 8.2: Fix Numeric Formatting & Layout Squeezing
- [ ] Phase 9: Final Quality Audit & Cleanup
- Pending Phases: Production Deployment, App Store Submission

## Architecture Overview (Krushi Kalp 2.0)
- **State Management**: Riverpod (Notifiers)
- **Access Control**: Table-driven (`access` table) with `item_snapshot` (JSONB) persistence.
- **Data Integrity**: Server-side RPCs for sensitive transactions (checkout, manual grant).
- **Notifications**: Firestore-based real-time listener for cross-platform reliability.

## Pending Tasks
- [ ] Create/Update `calculate_total_revenue` RPC in Supabase.
- [X] Update `get_admin_performance` RPC to use `payment` table.
- [X] Update `AdminService` counting logic (tests sold, revenue, etc.) to use `payment`/`access`.
- [X] Enforce 15s throttle for Store refresh (Manual & Auto).
- [X] Verify Razorpay UPI support for any UPI ID.
- [X] Audit Revenue Filters & Item Mapping (Phase 7.5).
- [ ] Production readiness check & RLS audit.

## Previous Phases
- Phase 7: Admin Stats & Payment Schema Stabilization (Complete)
- Phase 6H: Secure Claims & Smart Refresh (Complete)
- Phase 30: PDFrx Stabilization (Complete)
- Phase 31: Data Cleanup (Complete)
- Phase 1-15: Legacy UI/UX & Admin Tools (Complete)
