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
- Optimized performance by offloading search and sorting to Supabase via query parameters in `fetchPaginatedMockTests`.
- Added `EasyDebounce` for search inputs to prevent excessive API calls.
- Verified that signed URLs and other metadata are correctly populated during paginated loads.

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