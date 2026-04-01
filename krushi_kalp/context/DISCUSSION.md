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

## Phase: Automated Testing and Verification
- Goal: Verify stabilization changes with automated unit and widget tests.
- Proposed Tests:
  - Unit: PdfService uniqueness & Gujarati logic.
  - Unit: Downloads filtering logic for PYQs.
  - Widget: AdminResourceForm saving visual feedback and persistence.
  - Widget: DownloadsScreen filter responsiveness.

## Branch Gate:
- **Question**: Should this test work go into a **new branch** or the **existing branch**?
- **Status**: Awaiting user decision.
