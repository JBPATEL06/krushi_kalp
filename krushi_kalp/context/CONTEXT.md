# 🚀 Krushi Kalp Context

## 🎯 Project Overview
- **Project Name:** Krushi Kalp
- **Goal:** Comprehensive agricultural education platform (Mock Tests, eBooks, PYQs, GK).
- **Tech Stack:** Flutter, Riverpod, Supabase, Isar, Infinite Scroll Pagination.

## 🏗 Architecture
- **Clean Architecture:** Presentation, Domain, Data layers.
- **State Management:** Riverpod.
- **Local DB:** Isar (caching and offline support).
- **Backend:** Supabase (Auth, DB, Storage).

## 🛠 Active Phase
- **Phase 9: Admin Pagination Standardization**
  - Refactoring `AdminUserActivityScreen` to use `infinite_scroll_pagination`.
  - Ensuring consistent loading, error, and empty states using `PagedListView`.
  - Maintaining scroll state across tabs using `AutomaticKeepAliveClientMixin`.

## ✅ Completed Phases
- Phase 1-6: Core features (Auth, Store, Tests, PDF).
- Phase 7: New Payment & Access schema migration.
- Phase 8: Batch Access Control & Unified Grant Access Flow.

## 📋 Pending Phases
- Production Release & Play Store submission.
- Final UI/UX walk-through.

## 🔑 Key Decisions
- **Access Tracking:** Using `access` table with `item_snapshot` for historical integrity.
- **Pagination:** Standardizing on `infinite_scroll_pagination` for all admin list screens.
- **Search:** Using 500ms debounce for all search inputs to respect API limits.

## 🚨 Known Risks
- API Rate Limits: Mitigated by debouncing and standardized pagination.
- State Loss: Handled by `AutomaticKeepAliveClientMixin` in tabbed views.
