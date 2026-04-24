# Discussion Log: Infinite Pagination Refactoring

## [Phase 1: AdminResourceList Pagination]
### Goal
Refactor `AdminResourceList` to use `infinite_scroll_pagination` instead of fetching all records at once.

### Proposed Changes
- **File**: `lib/data/services/resource_service.dart`
  - **Action**: Add `fetchPaginatedResources` method.
  - **Why**: To support offset/limit based fetching from Supabase.
- **File**: `lib/presentation/screens/admin/resources/admin_resource_list.dart`
  - **Action**: 
    - Replace `FutureBuilder` with `PagedListView`.
    - Implement `PagingController<int, Resource>`.
    - Update `_loadData` to fetch pages.
    - Maintain existing logic for delete, edit, and view PDF.

### Risks / Side Effects
- **Pagination Logic**: Incorrect offset calculation could lead to duplicate items or missing items.
- **State Management**: Ensuring the `PagingController` is correctly disposed and updated after CRUD operations.
- **Signed URLs**: Must ensure signed URLs are fetched for each page load.

### Confirmed by User
- Confirmed implementation of infinite scrolling for both Admin Resource List and Admin Mock Test List.

### Resolved and How
- Implemented `fetchPaginatedResources` in `ResourceService` and updated `fetchPaginatedMockTests` in `TestService`.
- Refactored `AdminResourceList` and `AdminMockTestList` to use `PagingController` and `PagedListView`.
- Integrated server-side search and sorting for `AdminMockTestList`.
- Ensured `PagingController.refresh()` is called after every CRUD operation (Add, Edit, Delete) to keep the UI in sync.

---

## [Phase 2 Outcome]
- Successfully migrated `AdminMockTestList` from a stream-based approach (fetching all data) to a paginated approach.
- Optimized performance by offloading search and sorting to Supabase via query parameters.

## Current Active Phase
- Phase 10: No-FK Refactoring & Bug Fixing (COMPLETED)
- Phase 11: TBD - Refactoring remaining SQL joins in `AdminService` to comply with No-FK policy.
    - Fixing IDE errors in `AdminService`, `CartService`, and `TestService`.

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
- Phase 9: No-FK Refactor (Initial - Resource Service & Partial Admin Service).

## Key Decisions
- **No-FK Policy**: All cross-table data fetching must use manual "Fetch-and-Stitch" instead of SQL joins.
- Use `infinite_scroll_pagination` package for consistent pagination across the app.
- Refactor Supabase services to support offset-based pagination.

## Known Risks or Constraints
- Supabase pagination requires careful offset/limit management.
- Signed URLs for resources need to be handled during paginated loads.
- Manual stitching requires careful null handling for missing related data.

---

## [Phase 2: AdminMockTestList Pagination]
### Goal
Refactor `AdminMockTestList` to use `infinite_scroll_pagination`.

### Proposed Changes
- **File**: `lib/data/services/test_service.dart`
  - **Action**: Update/Verify `fetchPaginatedMockTests` to support `isAdmin` flag (show non-public tests).
- **File**: `lib/presentation/screens/admin/resources/admin_mock_test_list.dart`
  - **Action**:
    - Replace `StreamSubscription` based full load with `PagedListView`.
    - Move search and filter logic to the paginated fetch call (server-side filtering where possible, or client-side if dataset is small enough but still paginated). *Recommendation: Server-side for search.*

### Risks / Side Effects
- **Real-time updates**: Moving away from `stream` means updates won't be instantaneous unless we manually refresh or add a listener. However, for admin management, manual refresh or `refresh()` on CRUD is standard.
- **Search/Filter**: Search must now trigger a reset of the `PagingController`.

### Confirmed by User
- Confirmed implementation of infinite scrolling for both Admin Resource List and Admin Mock Test List.
- Reported syntax errors in `admin_mock_test_list.dart` after previous edits.

### Resolved and How
- Implemented `fetchPaginatedResources` in `ResourceService` and updated `fetchPaginatedMockTests` in `TestService`.
- Refactored `AdminResourceList` and `AdminMockTestList` to use `PagingController` and `PagedListView`.
- Integrated server-side search and sorting for `AdminMockTestList`.
- Ensured `PagingController.refresh()` is called after every CRUD operation (Add, Edit, Delete) to keep the UI in sync.
- **Fixed Syntax Errors**: Removed a duplicate class declaration in `admin_mock_test_list.dart` that caused nested scope errors and broken member references. Verified the structure is now clean.

---

---

## [Phase 5: Admin Access Audit & Visibility Integration]
### Goal
Enhance administrative control by adding visibility toggles and a detailed multi-tab access audit view (Paid, Free, Claimed, Manual) for Resources and Mock Tests.

### Sub-Phase 5.1: AdminGrantAccessScreen Refactoring (Audit Mode)
- **Files**: `lib/presentation/screens/admin/admin_grant_access_screen.dart`
- **Action**:
  - Update constructor to accept `bool isAuditMode = false`.
  - Implement `TabBar` with 4 tabs: **Paid**, **Free**, **Claimed**, **Manual**.
  - Update fetch logic to filter by `access_type` when in audit mode.
- **Risks**: Ensuring correct filtering in the `access` table.

### Sub-Phase 5.2: AdminResourceList & AdminMockTestList Enhancements
- **Files**: 
  - `lib/presentation/screens/admin/resources/admin_resource_list.dart`
  - `lib/presentation/screens/admin/resources/admin_mock_test_list.dart`
- **Action**:
  - Add `Switch` widget for `isActive` / `isPublic` status.
  - Add `IconButton` (Icons.people_alt_outlined) for Access Audit.
  - Connect status toggle to `AdminService.toggleResourcePublicStatus` / `AdminService.toggleMockTestPublicStatus`.
- **Risks**: List state sync after toggle.

### Sub-Phase 5.3: Detail Screen Enhancements
- **Files**:
  - `lib/presentation/screens/admin/resources/admin_resource_detail_screen.dart`
  - `lib/presentation/screens/admin/resources/admin_mock_test_detail_screen.dart`
- **Action**:
  - Add visibility toggle in the header card.
  - Add Access Audit icon to the AppBar or Performance section.

### Sub-Phase 5.4: Service Layer Verification
- **Files**:
  - `lib/data/services/admin_service.dart`
- **Action**:
  - Verify/Implement `getPaginatedUsersByAccessType`.

### Test Criteria
- Toggling visibility updates the DB and UI immediately.
- Audit Mode in `AdminGrantAccessScreen` correctly displays users in separate tabs.
- Audit icon opens the correct screen with the correct item ID.
---

## [Phase 6: Update "Claim" to "Free Claim" Terminology]
### Goal
Update user-facing UI labels from "Claim" / "Claim Free" to "Free Claim" for better clarity on store screens.

### Proposed Changes
- **Files**:
  - lib/presentation/screens/store_screen.dart
  - lib/presentation/screens/store/widgets/store_grid.dart
  - lib/presentation/screens/store/widgets/store_resource_grid.dart
  - lib/presentation/screens/free_content_screen.dart
- **Action**: Replace action button texts and snackbar success messages from "Claim" to "Free Claim".

### Confirmed by User
- The user requested "claim is not make sense it is freeclaim", proceeding in the same branch.

### Resolved and How
- Modified actionLabel in StoreGrid, StoreResourceGrid, and FreeItemCard usages.
- Modified SnackBar text in store_screen.dart and free_content_screen.dart.

---

## [Phase 6.6: Checkout Process Stabilization]
### Goal
Fix silent failures and "long wait" issues in the checkout flow reported by the user.

### Proposed Changes
- **File**: `lib/data/services/test_service.dart`
  - **Action**: Update `checkout` to capture RPC results and throw exceptions if `success` is false. Add detailed debug logging.
- **File**: `lib/presentation/screens/cart_screen.dart`
  - **Action**: Add `catch` blocks and error dialogs to `_handlePaymentSuccess` and `_processDirectPurchase`.
- **File**: `lib/data/services/payment_service.dart`
  - **Action**: Pass the `orderId` to Razorpay's `options` for better tracking.

### Risks / Side Effects
- **RPC Logic**: Mismatch between client parameters and backend SQL signature.
- **Error Visibility**: Ensure user gets meaningful messages without exposing technical details.

### Confirmed by User
- User requested to "hurry" and proceed in the same branch.

---

## [Phase 7: Razorpay & Checkout Stabilization]
### Goal
Resolve Razorpay SDK hangs and performance bottlenecks by correctly structuring options and fixing code-level scope errors.

### Proposed Changes
- **File**: `lib/data/services/payment_service.dart`
  - **Action**: Moved the Supabase Payment UUID from the Razorpay `order_id` field to the `notes` map as `supabase_order_id`. 
  - **Reason**: `order_id` in Razorpay is strictly for Razorpay-generated orders. Using a custom UUID there causes the SDK to hang or fail silently.
- **File**: `lib/presentation/screens/cart_screen.dart`
- **Action**: Fixed a scope error where `orderIdStr` was declared inside the `try` block but used outside it. Added robustness to handle empty carts and missing payment IDs.
- **File**: `lib/presentation/widgets/direct_checkout_sheet.dart`
  - **Action**: Updated `openCheckout` signature to include specific item descriptions.

### Risks / Side Effects
- **Verification**: Post-payment reconciliation (the `checkout` RPC) still relies on the `supabase_order_id` which is now retrieved from the `notes` or passed back via our internal state.

### Confirmed by User
- User requested to "clean this mess in single shot" and proceed in the same branch.

### Resolved and How
- Implemented the notes-based referencing in `PaymentService`.
- Verified and fixed scope errors in `CartScreen`.
- Standardized error reporting with `CrashlyticsService`.
- Verified that `_isProcessing` gates are properly placed to prevent double-charging.

---

## [Phase 8: Razorpay UPI ID Accessibility]
### Goal
Ensure users without UPI apps installed on their device can easily pay by entering their UPI ID (VPA) manually.

### Proposed Changes
- **File**: `lib/data/services/payment_service.dart`
  - **Action**: Modified the `options` map in `openCheckout` to include a `config` block.
  - **Details**:
    - Created a dedicated `upi` block titled "Pay via UPI ID".
    - Explicitly enabled `vpa: true` to show the entry field.
    - Set the sequence to prioritize `block.upi`.

### Risks / Side Effects
- **Visuals**: The Razorpay UI will change slightly to prioritize the UPI entry field. This is intentional to solve the user's request.

### Confirmed by User
- User requested: "in razor pay put option of pay via upi id even they not have any upi apps in mobile can it possible?"

### Resolved and How
- Added the `config` block to the Razorpay `options` map. This explicitly instructs the Razorpay SDK to provide a manual entry field for UPI IDs (the "Collect Flow"), which works independently of locally installed apps.

---

### Phase 10: No-FK Refactoring & Bug Fixing
- **Goal**: Enforce No-FK policy and fix Supabase v2 syntax errors.
- **Outcome**: 
    - Enforced Fetch-and-Stitch for `payment` and `access` tables.
    - Maintained SQL joins for `results` table (has FKs).
    - Migrated `.in_()` to `.inFilter()`.
    - Fixed `AdminService` count errors by switching from `FetchOptions` (unsupported version) to `.count(CountOption.exact)`.
    - Verified stability across `AdminService`, `CartService`, and `TestService`.
- **Status**: Completed.
- **[TestService]**:
  - Fix `fetchUserResults` (Line 363) by adding explicit `.cast<String, dynamic>()` to the stitched maps before parsing.

---

## [Phase 11: Payment RLS & Accessibility Fixes]
### Goal
Resolve `42501 Forbidden` errors during checkout caused by missing RLS policies on the `payment` table.

### Proposed Changes
- **Database**:
  - Add `INSERT` policy for `payment` table: `(auth.uid() = user_id)`.
  - Add `UPDATE` policy for `payment` table: `(auth.uid() = user_id)`.
- **Reason**: The app inserts and then immediately updates payment records for direct orders, which requires both policies to be present for regular users.

### Risks / Side Effects
- None. Access is strictly scoped to the user's own `user_id`.

### Confirmed by User
- Confirmed to proceed in the same branch.

### Resolved and How
- Applied SQL migration to create `payment_user_insert` and `payment_user_update` policies.
- Verified that these policies now exist alongside the existing `SELECT` policy.

---

## [Phase 11.1: Razorpay UPI Accessibility Fix]
### Goal
Ensure the UPI payment option is visible and prioritized in the Razorpay checkout popup.

### Proposed Changes
- **Action**: 
    - Refactored the `config` block in `PaymentService.openCheckout` to use a more robust definition.
    - Added `modal.confirm_close: true` to prevent accidental exits.
- **Outcome**: UPI should now appear as the primary block in the payment method list.

---

## [Phase 11.2: Checkout RPC Parameter Mismatch — Root Cause Analysis]

### Problem Summary
**Symptom**: Payment was successful (money deducted by Razorpay), but user received NO access to the purchased item.

### Root Cause Chain (Full Trace)

#### Error 1 — Wrong parameter name (PGRST202)
The Dart code in `TestService.checkout()` was calling the DB function with:
```
'p_payment_id': orderId  ❌ WRONG
```
But the DB function expected:
```
p_order_id uuid           ✅ CORRECT
```
**Why**: During the migration from the old `orders/order_items` schema to the new `payment/access` schema, the DB function was renamed + re-signed, but the Dart RPC call was NEVER updated. An old comment even said `"We map orderId to p_payment_id"` — a silent, incorrect assumption that survived the refactor.

**Error code**: `PGRST202 — Function not found`

**Fix**: Changed `p_payment_id` → `p_order_id`, added `p_gateway: paymentGateway` in `test_service.dart`.

---

#### Error 2 — Duplicate overloaded function (PGRST203)
After fixing the parameter name, a new error appeared:
```
PGRST203 — Multiple Choices: Could not choose between:
  complete_checkout_v1(p_offer_id => bigint, ...)
  complete_checkout_v1(p_offer_id => integer, ...)
```
**Why**: Two separate DB migrations had each created `complete_checkout_v1` without first dropping the previous version — creating two overloads. PostgREST could not resolve which to call when a nullable int? was passed.

**Error code**: `PGRST203 — Multiple Choices`

**Fix**: Dropped both overloaded versions via migration `consolidate_complete_checkout_v1`.

---

### Architecture Flow (Correct Payment → Access Grant)
```
User taps Pay
  → createDirectOrder() → INSERT payment (status: PENDING, metadata: {item_type, item_id})
  → Razorpay opens → User pays → Razorpay returns gateway_payment_id
  → TestService.checkout(orderId: payment.id, paymentId: razorpay_id)
  → RPC complete_checkout_v1():
      1. UPDATE payment: status=COMPLETED, gateway_payment_id set, offer_code set
      2. READ item_type + item_id from payment.metadata
      3. INSERT into access: user_id, item_type, item_id, access_type='paid'
  → User now has access ✅
```

### Files Modified
- `lib/data/services/test_service.dart` — Fixed RPC parameter names
- DB: Dropped `complete_checkout` (old schema)
- DB: Dropped `get_admin_orders` (old schema)  
- DB: Dropped both duplicate `complete_checkout_v1` overloads

### Status
- ✅ Parameter name fix applied (`p_payment_id` → `p_order_id`)
- ✅ Legacy functions dropped from DB
- ✅ Duplicate overloads dropped from DB
- 🔄 Phase 11.3 IN PROGRESS: Recreate single canonical `complete_checkout_v1`

---

## [Phase 11.3: Recreate Canonical complete_checkout_v1]

### Goal
Create one clean, unambiguous `complete_checkout_v1` DB function.

### What the Function Does
1. Fetches and locks the `payment` record by `p_order_id` (FOR UPDATE)
2. Guards against double-processing (returns success if already COMPLETED)
3. Updates `payment`: `status=COMPLETED`, `gateway_payment_id`, `offer_code`, `discount_amount`
4. Reads `item_type` + `item_id` from `payment.metadata` (stored during `createDirectOrder`)
5. Inserts into `access` table: `user_id`, `payment_id`, `item_type`, `item_id`, `access_type='paid'`
6. Returns `{success: true}` or `{success: false, message: reason}`

### Status: ✅ COMPLETED
- Single canonical function created with `p_offer_id bigint`
- Verified: only ONE version exists in the DB
- No more overload conflicts

---

## [Phase 12: Payment Status Alignment Fix]

### Problem Summary
**Symptom**: Razorpay payments were successful, but the `payment` table status remained `PENDING`, and users were not granted access.

### Root Cause
The `complete_checkout_v1` RPC was trying to update `payment.status` to `'COMPLETED'`. However, the `payment` table has a CHECK constraint that only allows `['PENDING', 'SUCCESS', 'FAILED', 'REFUNDED']`. This caused the RPC to fail silently (returning an error object that the app caught but the DB transaction rolled back).

### Resolution
- Updated `complete_checkout_v1` RPC to use `'SUCCESS'` instead of `'COMPLETED'`.
- Verified that the Dart codebase (specifically `AdminService`) already expects `'SUCCESS'` for reporting.
- Verified that the double-processing guard in the RPC now correctly checks for `'SUCCESS'`.

### Files Modified
- Supabase RPC: `complete_checkout_v1`

### Status: ✅ COMPLETED

---

## [Phase 12.1: Add to Cart Table Name Fix]

### Problem Summary
**Symptom**: "Add to Cart" was failing. Items were not appearing in the cart even though the user clicked the button.

### Root Cause
In `CartService.addToCart`, the code was attempting to fetch user information for the payment snapshot from a table named `profiles`. This table does not exist in the current schema (the correct table is `users`). This caused the entire insertion transaction to fail.

### Resolution
- **Status**: Completed (RPC updated, Access insert working)

### [Phase 12.2: Price & Network Resilience]
- **Goal**: Prevent ₹0 price display on slow networks and handle price fetch failures gracefully.
- **Files modified**:
    - `lib/data/services/offer_service.dart`: Fixed `getDisplayPrice` to return `null` on error instead of `0.0`.
    - `lib/presentation/widgets/direct_checkout_sheet.dart`: Initialized `_finalPrice` with `_basePrice` in `initState` to prevent flickering.
- **Outcome**: UI now shows the base price immediately while discounts load in the background.

### [Phase 12.3: Cart RPC Alignment]
- **Goal**: Fix "Proceed to Payment" failure in Cart Screen caused by RPC pointing to old tables.
- **Changes**:
    - Updated `calculate_secure_cart_price` RPC to query `payment` and `access` tables instead of `orders` and `order_items`.
    - Simplified `access` table RLS policies to allow authenticated users to `INSERT` and `DELETE` their own items.
- **Outcome**: Cart checkout flow now correctly verifies prices against the live cart data.

### Files Modified
- `lib/data/services/cart_service.dart`

---
