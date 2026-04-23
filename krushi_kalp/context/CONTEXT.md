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
- **Phase 10: Final Audit & Admin Polish**
  - Refining Admin Grant Access functionality.
  - Consistent UI/UX across Admin tools.

## ✅ Completed Phases
- Phase 1-6: Core features (Auth, Store, Tests, PDF).
- Phase 7: New Payment & Access schema migration.
- Phase 8: Offline support and Isar integration.
- Phase 9: Admin Dashboard expansion.

## 📋 Pending Phases
- Production Release & Play Store submission.

## 🔑 Key Decisions
- **Access Tracking:** Using `access` table with `item_snapshot` for historical integrity.
- **Manual Granting:** Admins can grant items with `manual_granted` access type.
- **Store Performance:** 15s throttled refresh to save Supabase resources.

## 🚨 Known Risks
- RenderFlex overflows in long lists (mitigated but need monitoring).
- Payment gateway deep-linking configuration.
