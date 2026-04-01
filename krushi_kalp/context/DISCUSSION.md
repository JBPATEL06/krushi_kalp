# Krushi Kalp Discussion Log

## 2026-04-01: Stabilization Phase
- Problem: Admin resource editing not working, PDF font issues, PYQ filter missing mock tests, Cart redirection.
- Decisions:
  - Fixed PDF service for Gujarati fonts (dynamic).
  - Fixed PYQ filter by including mock tests with 'PYQ' in their metadata.
  - Applied standardized RLS policies for `resources` and `banner` to allow authenticated users (admin role).
  - Fixed AdminResourceForm to properly await storage/DB operations.

## Status:
- Admin Resource Form: FIXED (awaiting verification)
- PDF Generation: FIXED (testId + Fonts)
- PYQ Filter: FIXED
- Cart Navigation: INVESTIGATED (added SnackBar for confirmation)
