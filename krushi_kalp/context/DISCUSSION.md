# Krushi Kalp Discussion Log

### Phase 6: Access & Payment Architecture Migration (2026-04-23)
- **Goal**: Decouple entitlements from legacy orders to allow user/item deletion without losing history.
- **Decisions**:
  - **Schema**: Created `payment` and `access` tables (No FKs). 
  - **Transactionality**: Implemented `complete_checkout_v1` RPC to atomically record payments and grant access with JSON snapshots.
  - **Notifications**: Migrated FCM tokens and stream listeners to Firebase Firestore for real-time scalability.
  - **Admin**: Added manual grant/revoke logic with auto-snapshotting.

### Phase 6G: Store Stabilization & Concurrency Control (2026-04-23)
- **Problem**: Store refresh was "not working" (crashing on P0001 errors) and performing inefficient "bulk UI loads".
- **Decision**: 
    1.  **Resilience**: `OfferService.getDisplayPrice` now catches P0001 (inactive item) and returns a null price safely.
    2.  **Queue-Based Loading**: Replaced bulk `Future.wait` with a batching loop (5 items/batch) in `StoreGrid` and `StoreResourceGrid`.
    3.  **Refresh Logic**: Fixed `StoreScreen.onRefresh` to properly await the `_loadData` future.

### Phase 6H: Secure Claims & Smart Refresh (2026-04-23)
- **Problem**: 
    1. Free items were not claimable due to RLS `INSERT` restrictions on the `access` table.
    2. `checkOwnership` was failing due to a schema mismatch (`access_id` vs `id`).
    3. User requested a 15-second cooldown for Store refreshes to prevent excessive DB load while allowing local cache access, but with a manual bypass.
    4. Verification needed for Razorpay UPI acceptance and payment security.
- **Decision**: 
    1.  **RPC Claim**: Created `process_item_claim` RPC (SECURITY DEFINER) to safely grant access after server-side price validation (must be 0.0).
    2.  **Schema Alignment**: Fixed `CartService` and `DownloadActionButton` to use correct primary keys and display titles.
    3.  **Smart Throttling (15s)**: Added `_lastSyncTime` tracking to `StoreScreen` and `FreeContentScreen`. 
    4.  **Manual Bypass**: Fixed the AppBar refresh button and Pull-to-Refresh to pass `bypassThrottle: true`, ensuring a mandatory Supabase hit when the user explicitly asks for it.
    5.  **Payment Security**: Audited `DirectCheckoutSheet` and `CartScreen` to ensure `calculate_secure_price` (RPC) is always used before payment initialization.
    6.  **Razorpay UPI**: Confirmed configuration supports UPI ID entry through the native SDK.
- **Outcome**: Claim system is fixed and secure. Store performance is optimized with tiered caching and explicit refresh control.

**Risks**:
- Razorpay external wallets (PhonePe/GPay) require specific package visibility queries in `AndroidManifest.xml` (already verified).
- `item_snapshot` (JSONB) must be maintained if item schemas change in the future.
