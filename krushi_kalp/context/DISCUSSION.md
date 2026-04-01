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

## Branch Gate:
- **Branch**: `phase-1` (Active branch confirmed by user).
- **Status**: Awaiting approval for navigation refactor.
