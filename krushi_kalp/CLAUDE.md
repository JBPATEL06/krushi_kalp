# Krushi Kalp — Unified Project Context & AI Rules

> **Merged Project** — Single codebase serving both the **User App** (agricultural e-commerce, exam prep) and the **Admin Panel** (content management, monitoring). Role is determined from `users.role` column. `role == 'Admin'` → admin panel. All others → user app.

---

## 📂 Project Context
- **Rules & Standards:** [context/AGENTS.md](file:///f:/Krushi_kalp1/krushi_kalp/context/AGENTS.md), [context/GEMINI.md](file:///f:/Krushi_kalp1/krushi_kalp/context/GEMINI.md)
- **Implementation History:** [context/implementation_plan.md](file:///f:/Krushi_kalp1/krushi_kalp/context/implementation_plan.md), [context/task_list.md](file:///f:/Krushi_kalp1/krushi_kalp/context/task_list.md)
- **Code Audit:** [context/code_audit_report.md](file:///f:/Krushi_kalp1/krushi_kalp/context/code_audit_report.md)

---

## 🚨 CRITICAL AI DIRECTIVES: DO NOT TOUCH WORKING FUNCTIONALITY 🚨

**The following core systems are CURRENTLY STABLE AND FULLY FUNCTIONAL. As an AI Agent, you MUST NOT modify, refactor, or attempt to "optimize" these systems unless explicitly ordered to by the human user:**

1. **Authentication:** Google Sign-In, Role checks, and routing logic.
2. **Offline-First Caching (ISAR):** [MODERNIZED] Local caching for MockTests, Offers, and Resources. UI loads from Isar immediately; background silent refresh via Supabase.
3. **Secure Pricing (SQL RPC):** [SECURED] Final payment amounts are strictly verified via Supabase SQL RPC (`calculate_secure_price` / `calculate_secure_cart_price`) before opening Razorpay.
4. **Mock Exam Engine:** The test UI, timer, scoring, and string-based answer validation.
5. **Offline Downloads:** Local sandboxing (`DownloadService`), PDF Generation, and JSON caching.
6. **Background Uploads/Downloads:** Real-time transfer notifications and background isolate syncing.
7. **Pagination Core:** `infinite_scroll_pagination` integration and `AdminService` range queries.
8. **Navigation Scaffold:** `GoRouter` configuration and authentication-based redirection.

*Rule of Thumb: If a feature is listed in this document, assume it works perfectly. Do not alter existing business logic when applying UI updates or adding new features.*

---

## Current Progress (Modernization Phases)
- **Phase 1: Database Bill Protection** [COMPLETED] 
  - Integrated `Isar` NoSQL for local caching.
- **Phase 2: Secure Server-Side Pricing** [COMPLETED]
# Krushi Kalp Project Context

## Status & Progress (Last Updated: March 2026)
- **Networking**: Settlement on **Supabase SDK + native HttpClient** (Dio/Retrofit rejected for stability).
- **Download Engine**: Refactored to use **direct file streaming (IOSink)** to prevent ANRs/OOM crashes.
- **Cache Deduplication**: Fixed Isar ID mapping (Backend `id` -> Isar `id`) to prevent duplicate UI entries.
- **UI Architecture**: "Agrarian Glass Prism" aesthetic established with unique `Hero` tag safety.
- **Deduplication Migration**: One-time automatic cache clear implemented in `LocalCachingService`.

## 🛠 Tech Stack
- **Framework**: Flutter 3.27+ (Stable Channel)
- **State Management**: Riverpod 3.0 (AsyncValue / Notifiers)
- **Database**: Isar (NoSQL) for high-speed local caching
- **Networking**: Supabase SDK + Native `HttpClient`
- **Navigation**: GoRouter (Declarative)
- **Design System**: Agrarian Glass Prism (Indigo-Slate theme)

## 📌 Development Standards

### 1. Networking & API
- Always use the `SupabaseUrlHelper` for signed URLs.
- For file downloads, use `DownloadService.downloadFileInBackground` to ensure background streaming.
- **Rule**: Never read large files into byte lists in memory; use `IOSink` streams.

### 2. Local Caching (Isar)
- **Rule**: Always map the backend unique ID (`testId`, `resourceId`, etc.) to the Isar `id` field in the entity's `fromModel` method to ensure "upsert" behavior and prevent duplicates.
- Run `dart run build_runner build --delete-conflicting-outputs` after changing entity schemas.

### 3. UI & UX Safety
- **Anti-Crash**: Never call `Navigator.pop(context)` or `context.push()` directly after a long `await` without checking `if (mounted)`.
- **Auto-Open**: Do not force-open files after download. Use a `ScaffoldMessenger` Snackbar with an action button for completion notifications.

## 🚀 Action Items
- [ ] **Lint Zeroing**: Systematically resolve remaining lint issues.
- [ ] **Typography Refinement**: Integrate `google_fonts` into `AppTheme.dart` (Indigo/Slate palette).
- [ ] **Feature Development**: Proceed with Store and Results screen refinements.
2. **UI Polish:** Full implementation of "Agrarian Glass Prism" aesthetic across consistent widgets (e.g. `UniversalItemCard`).
3. **Final Navigation Cleanup:** Systematically replace remaining `Navigator.push` with `context.push`.
4. **Isar Offline Logic Improvement:** Ensure graceful recovery when database is empty and device is offline.

---

## Sensitive Files (NEVER COMMIT)
- `**/service-account.json`
- `**/firebase-service.json`
- `.env`
- `**/google-services.json`
- `lib/core/env/env.g.dart` (Generated secrets) 