# Krushi Kalp Discussion Log

## 2026-04-01: Stabilization Phase
- Problem: Admin resource editing not working, PDF font issues, PYQ filter missing mock tests, Cart redirection.
- Decisions:
  - Fixed PDF service for Gujarati fonts (dynamic).
  - Fixed PYQ filter by including mock tests with 'PYQ' in their metadata.
  - Applied standardized RLS policies for `resources` and `banner` to allow authenticated users (admin role).
  - Fixed AdminResourceForm to properly await storage/DB operations.

## Status:
- Admin Resource Form: COMPLETE (Refactored to high-trust sequential await)
- PDF Generation: COMPLETE (Fixed font rendering & unique user storage paths)
- PYQ Filter: COMPLETE (Now includes properly tagged Mock Tests)
- Cart Actions: COMPLETE (Added SnackBar feedback; no redirection bugs found)
- RLS Policies: COMPLETE (Standardized policies for banner/resources and storage)

## Phase 2: Technical Audit & Scalability Analysis (2026-04-01)

### Discussion: System Scalability & Stability Review
- **Goal**: Determine user capacity and identify potential crash points.
- **Findings**:
  - **Architecture**: Confirmed solid Clean Architecture (Layer-first) in the codebase, despite legacy docs suggesting Feature-first.
  - **Scalability**: High capacity (~500+ concurrent users on Pro) due to **Isar caching** reducing DB hits.
  - **Bottlenecks**: **RLS subqueries** identified as the primary long-term scalability risk.
  - **Stability**: **PGRST203** (SQL ambiguity) and missing `mounted` checks in async UI logic are the main crash risks.
- **Outcome**: Detailed audit report created in `implementation_plan_v13.md`.
- **Recommendation**: Prioritize RLS optimization in the next stabilization phase.

## Phase 3: Navigation Standardization & Stability Refinement (2026-04-01)

### Discussion: Scalability & Navigation Refactor
- **User Question**: Handling 1,000 total customers vs. 50 simultaneous users.
- **Clarification**: 1,000 total users is perfectly safe; concurrency limits (50 on Free, 500+ on Pro) only apply to simultaneous database hits.
- **PGRST203**: Ambiguous SQL function naming error; must maintain unique function signatures to avoid crashes.
- **Decision**: Systematically refactor all `Navigator.pop` calls (114 instances) to `context.pop()` (GoRouter) for consistency and safety.
- **Action**: Audit `lib/presentation` for legacy navigation and migrate.
- **Outcome**: Implementation plan created as `implementation_plan_v14.md`.

## Phase 4: Email Authentication Integration (2026-04-02)

### Discussion: Professional Email Auth Requirements
- **User Request**: Implement Email Sign Up and Login, T&C checkbox, Proper Profile Creation, No Multiple Registration.
- **Plan**:
  - Refactor `AuthService` and `AuthNotifier`.
  - Create `SignUpScreen`.
  - Update `LoginScreen`.
  - Enforce T&C compliance.
  - Handle account linking/prevention for duplicate emails.
- **Outcome**: Implementation plan created in conversation-specific artifact.

## Phase 5: Stabilization & Auth Error Handling (2026-04-02)

### Discussion: LateInitializationError & Account Prevention
- **Problem**: App crash when loading resources from Isar (`LateInitializationError: updatedAt`).
- **Problem**: Multi-account prevention worked but lacked user-friendly error messages.
- **Decisions**:
  - Refactored all Isar entities (`ResourceEntity`, `OfferEntity`, `MockTestEntity`) to use nullable types with safe fallbacks in domain conversion.
  - Regenerated Isar code to reflect schema safety.
  - Enhanced `ErrorService` to map Supabase `AuthException` (User already registered/registered with provider) to helpful strings.
  - Updated `AuthNotifier` to properly catch and propagate these errors to the UI.
- **Outcome**: Both crashes and UX edge cases resolved.
- **Status**: COMPLETE.

## Phase 6: Demo Data & Store Sync Stabilization (2026-04-07)

### Discussion: Demo Visibility & Refresh Strategy
- **Problem**: Store only showed 1/3 mock tests due to free-item filtering.
- **Problem**: Store items didn't update immediately after Supabase changes due to local Isar caching.
- **Decisions**:
  - Removed "Price > 0" filter in `StoreScreen` to make all 15 demo items visible.
  - Implemented `forceRefresh: true` for `fetchTests`, `fetchAll`, and `fetchActiveOffers` in the Store.
  - Standardized all 15 items with "2-Free, 1-Paid" structure and demo disclaimers.
  - Converted legacy offer codes to a single "Automatic Launch Sale" (ID 9).
- **Stability Fixes**:
  - **Crash Resolution**: Fixed `Unsupported operation: Cannot modify an unmodifiable list` by wrapping state-derived lists in `List.from()` before sorting.
  - **Manifest**: Added `android:enableOnBackInvokedCallback="true"` to `AndroidManifest.xml` to fix Predictive Back system warnings.
- **Outcome**: Demo environment is fully populated, synchronized, and stable.
- **Branch Gate**:
  - **Branch**: `fix/store-refresh-visibility` (Confirmed by user).
  - **Status**: COMPLETE.
## Phase 7: Background Transfer UX & Redirection (2026-04-07)

### Discussion: Decoupling UI from File Transfers
- **Problem**: Admin screens (Mock Test, Resources) blocked the UI until large assets finished uploading. This caused poor UX and potential timeouts on slow connections.
- **Problem**: Users weren't notified that they could safely background the app during long downloads.
- **Decisions**:
  - **Decoupled Transfers**: Switched from sequential `await` of file uploads to a non-blocking `BackgroundUploadService` pattern.
  - **Immediate Redirection**: Screens now `pop(context, true)` immediately after the database record (metadata) is confirmed, rather than waiting for binary assets.
  - **User Feedback**: Added clear SnackBar messaging ("Safe to Background") to both Admin and User flows.
  - **Data Integrity**: Database records are still saved synchronously *before* backgrounding to ensure valid IDs for storage paths. Background tasks update the record with final URLs upon completion.
  - **Security**: Maintained existing Isar/Supabase RLS patterns for all background tasks.
  - **Performance**: Enforced 1MB limit for Resource cover images; increased timeout to 180s and retries to 5 (from 3) for background transfers to fix timeout failures on slow networks.
- **Outcome**: Admin and User experience is now fluid and "non-blocking" for all file operations, with high resiliency against transient network drops.
- **Branch Gate**:
  - **Branch**: `feature/background-transfer-ux-redirection` (Confirmed by user).
  - **Status**: COMPLETE.

## Phase 7.2: Extreme Resiliency & UI Stability (2026-04-08)

### Discussion: Resolving Persistent Background Failures
- **Problem**: Users reported a 70% failure rate for background uploads. Logs showed that even with 5 retries, the ~30s retry window was insufficient for mobile devices in extended dead zones.
- **Problem**: `StoreScreen` crashed with "ref used after dispose" when users navigated away during data loading.
- **Problem**: Admin dashboard streams generated repetitive `SocketException` logs during signal drops.
- **Decisions**:
  - **Extreme Backoff**: Upgraded `RetryHelper` to support `maxDelay` and custom `initialDelay`.
  - **21-Minute Window**: Increased background upload retries to 8x with a 5s initial delay, stretching the retry window to ~21 minutes. This ensures tasks survive longer signal outages.
  - **UI Hardening**: Added `mounted` checks to `StoreScreen._loadData` to safely handle navigation during async operations.
  - **Log Suppression**: Wrapped `AdminService` dashboard streams in `RetryHelper` to handle transient network errors gracefully.
- **Outcome**: Upload reliability is drastically increased, and UI stability is improved for navigating users.
- **Branch Gate**:
  - **Branch**: `feature/background-transfer-ux-redirection` (Existing branch).
  - **Status**: COMPLETE.
