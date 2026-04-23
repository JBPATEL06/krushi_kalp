# Krushi Kalp Discussion Log

### Phase 7.5: Admin Revenue Optimization & Item Mapping
**Status:** Completed & Stabilized
**Goal:** Migrate revenue reporting to `payment` table and implement historical snapshot mapping.

#### Key Implementation Details:
- **Database Decoupling:** Fully removed dependencies on the deprecated `orders` table for revenue reporting.
- **Data Integrity:** Implemented historical mapping in `AdminService` using `item_snapshot` from the `access` table, ensuring item titles and types remain accurate even if parent items are deleted.
- **Offer Metadata Integration:** Integrated `offers` table lookups for detailed discount breakdowns in transaction receipts.
- **Stability Fix:** Implemented robust null-safety and fallback logic for cases where coupon metadata or item snapshots are missing, preventing `NoSuchMethodError` crashes.
- **UI Enhancement:** Redesigned the Transaction Detail dialog with a premium aesthetic, type badges, and clear discount transparency.

### Status Tracking:
- [x] Phase 7.5: Admin Revenue Analytics Migration (Payment/Access Schema)
- [x] Phase 7.6: Access Type Classification (Paid, Free, Manual)
- [x] Phase 7.7: Dashboard Simplification (Remove Search, Ordering)
- [x] Phase 7.8: Activity Summary & Full Activity View (Pagination & Search)
- [ ] Phase 8.1: Fix RenderFlex Overflow in User Details
- [ ] Phase 9: Final Quality Audit & Production Prep

### Phase 7.8: Activity Summary & Full Activity View
**Status:** Completed
**Goal:** Implement a summary view in the user details dashboard (max 4 items) and a dedicated full activity screen with pagination and search.

#### Key Implementation Details:
- **Summary Mode**: Updated `AdminUserDetailsScreen` to display only the first 4 items from the activity streams using `.take(4)`.
- **Show All Navigation**: Added a `TextButton.icon` below each list to navigate to `AdminUserActivityScreen` with appropriate `initialIndex`.
- **Paginated Service**: Added `getUserOrdersPaginated` and `getUserResultsPaginated` to `AdminService` with support for server-side `ilike` searching.
- **Dedicated Activity Screen**: Created `AdminUserActivityScreen` with `TabBar`, debounced server-side search, and infinite-scroll pagination (200px prefetch).
- **Resilience**: Implemented `NetworkErrorState` integration and robust error handling for paginated loads.
- **Consistent UI**: Reused `ModernCard` and specific status badge styling across both summary and full views.

### Phase 7.7: Dashboard Simplification (Remove Search & Ordering)
**Status:** Completed
**Goal:** Simplify the Admin User Details view by removing redundant search bars and ensuring activity streams are sorted correctly (latest first).
### Phase 8.1: UI Overflow Fix
**Status**: Completed
**Goal**: Resolve RenderFlex overflow in AdminUserDetailsScreen.
- **Implementation**: Wrapped `Column` widgets in `_buildPurchasesStream` and `_buildAttemptsStream` with `SingleChildScrollView`.
- **Outcome**: The activity summaries now scroll correctly within the TabBarView, preventing layout crashes on smaller devices or long lists.
- **Verification**: `dart analyze` confirmed zero syntax errors or warnings.

#### Key Implementation Details:
- **Search Removal**: Removed `TextEditingController` and search query state from `AdminUserDetailsScreen`. Removed the search bar UI from both "Purchased" and "Attempted" tabs.
- **Direct Streaming**: StreamBuilders now directly consume and display snapshots without in-memory filtering, improving code clarity and reducing state complexity.
- **Ordering Verification**: Confirmed that `AdminService.streamUserOrders` and `AdminService.streamUserResults` use `descending: true` on their respective timestamp columns (`granted_at` and `attempt_date`).
- **UI Consistency**: Maintained the premium badge system and detailed payment transparency while reducing visual clutter.

### Phase 7.6: Access Type Classification
**Status:** Completed
**Goal:** Categorize user access records into "Manual Grant", "Free Claim", or "Paid" types for accurate administrative tracking.

#### Key Implementation Details:
- **Database Schema**: Added `access_type` (TEXT) column to the `access` table.
- **Migration**: Categorized existing records based on `payment_id` and `price_paid` values.
- **Automated Logic (RPCs)**: 
    - Updated `process_item_claim` to automatically tag new claims as `free_claim`.
    - Updated `complete_checkout_v1` to tag successful purchases as `paid`.
- **Manual Grant Logic**: Updated `AdminService.grantAccess` to explicitly set `manual_granted` type.
- **UI Enhancement**: Overhauled the `AdminUserDetailsScreen` activity list with:
    - **Color-coded Badges**: Green (Paid), Blue (Free), Orange (Manual).
    - **Offer Transparency**: Displayed discount names, percentage (if applicable in snapshot), and actual amounts saved.
    - **Payment Integration**: Stream now joins with the `payment` table to fetch live discount metadata for paid items.

#### Outcome:
Admins can now instantly see how a user obtained any piece of content, including details of which offer was applied and how much was saved.

### Phase 7.5: Admin Dashboard Enhancements (User Details)

### Discussion Log
- **User Requirement**: Show item names, precise timestamps (date + time) and search functionality in "Purchased Tests" and "Attempted Tests" tabs.
- **Decision**: 
    - In "Purchased Tests", switch from `payment` table stream to `access` table stream. This automatically includes item snapshots (names) and captures both purchases and manual grants.
    - Implement search controllers for both tabs to filter items by name/title in-memory for zero latency.
    - Use `DateFormat` for readable precise timestamps.
- **Risks**: None significant. Null safety handles missing snapshots.

### Implementation Details
- **File**: `admin_service.dart` -> Modified `streamUserOrders` to fetch from `access` and `streamUserResults` for consistency.
- **File**: `admin_user_details_screen.dart` -> Added search bars, search controllers, and updated `ListTile` UI with multi-line subtitles.
- **Status**: Complete.

### Phase 7: Admin Panel Data Migration (Final)
- **Problem**: Admin dashboard performance cards and revenue stats were still querying the legacy `orders` table.
- **Solution**: 
    - Refactored `get_admin_performance` RPC to use `payment` (revenue) and `access` (sales).
    - Updated `AdminService` to use `access` table for all counting operations (tests sold, resource stats).
- **Outcome**: Admin dashboard is now 100% migrated to the new schema. Legacy `orders` table can be safely archived.

### Phase 7.1: Store Refresh Optimization
- **Requirement**: Prevent Supabase API abuse by enforcing a 10-15s throttle even on manual refresh.
- **Implementation**: 
    - Modified `StoreScreen._refreshAll` to respect the `_lastSyncTime` throttle.
    - If user triggers refresh < 15s since last sync, UI falls back to Isar local cache.
- **Outcome**: Improved performance and reduced API costs while maintaining manual control.

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
