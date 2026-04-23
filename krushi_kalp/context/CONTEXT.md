# Krushi Kalp App Context

## Project Overview
Krushi Kalp is a Flutter-based educational/agricultural application providing mock tests, resources (ebooks, PYQs, GK), and banners.

## Tech Stack
- Frontend: Flutter, Riverpod, GoRouter
- Backend: Supabase (Auth, Storage, Database)
- PDF: PDF package for report generation

## Current Phase: Phase 6H - Secure Claims & Smart Refresh (2026-04-23)
- **Status**: COMPLETE.
- **Goal**: Resolve free item claim failures, implement smart throttling for Store refreshes, and verify payment security.
- **Completed (Phase 6 Architecture)**:
    - Transitioned to snapshot-based access architecture ( `access` and `payment` tables).
    - Implemented atomic `complete_checkout_v1` RPC.
    - Decoupled from legacy `orders` table for historical persistence.
    - Migrated notification infrastructure to Firebase Firestore.
- **Stabilization Work Completed**:
    - **Secure Claims**: Implemented `process_item_claim` RPC to handle free item access granting on the server, ensuring items with price `0.0` (like "Demo") are claimable.
    - **Smart Refresh**: Implemented 15-second throttling in `StoreScreen` and `FreeContentScreen`.
    - **Manual Bypass**: Manual refresh (AppBar button and Pull-to-Refresh) now bypasses the throttle for mandatory Supabase sync.
    - **Payment Security**: Verified `calculate_secure_price` (Direct) and `calculate_secure_cart_price` (Cart) RPCs for server-side price validation.
    - **Razorpay**: Confirmed UPI configuration allowing manual UPI ID entry.
    - **Schema Fixes**: Corrected `CartService.checkOwnership` and `DownloadActionButton` mappings.

## Architecture Overview (Krushi Kalp 2.0)
- **State Management**: Riverpod (Notifiers)
- **Access Control**: Table-driven (`access` table) with `item_snapshot` (JSONB) persistence.
- **Data Integrity**: Server-side RPCs for sensitive transactions (checkout, manual grant).
- **Notifications**: Firestore-based real-time listener for cross-platform reliability.

## Previous Phases
- Phase 30: PDFrx Stabilization (Complete)
- Phase 31: Data Cleanup (Complete)
- Phase 1-15: Legacy UI/UX & Admin Tools (Complete)
