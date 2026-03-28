# Krushi Kalp — Unified Project Context & AI Rules

> **Merged Project** — Single codebase serving both the **User App** (agricultural e-commerce, exam prep) and the **Admin Panel** (content management, monitoring). Role is determined from `users.role` column. `role == 'Admin'` → admin panel. All others → user app.

---

## 🚨 CRITICAL AI DIRECTIVES: DO NOT TOUCH WORKING FUNCTIONALITY 🚨

**The following core systems are CURRENTLY STABLE AND FULLY FUNCTIONAL. As an AI Agent, you MUST NOT modify, refactor, or attempt to "optimize" these systems unless explicitly ordered to by the human user:**

1. **Authentication:** Google Sign-In, Role checks, and routing logic.
2. **Offline-First Caching (ISAR):** [MODERNIZED] Local caching for MockTests, Offers, and Resources. UI loads from Isar immediately; background silent refresh via Supabase.
3. **Secure Pricing (SQL RPC):** [SECURED] Final payment amounts are strictly verified via Supabase SQL RPC (`calculate_secure_price` / `calculate_secure_cart_price`) before opening Razorpay.
4. **Mock Exam Engine:** The test UI, timer, scoring, and string-based answer validation.
5. **Offline Downloads:** Local sandboxing (`DownloadService`), PDF Generation, and JSON caching.
6. **Background Uploads/Downloads:** Real-time transfer notifications and background isolate syncing.

*Rule of Thumb: If a feature is listed in this document, assume it works perfectly. Do not alter existing business logic when applying UI updates or adding new features.*

---

## Current Progress (Modernization Phases)
- **Phase 1: Database Bill Protection** [COMPLETED] 
  - Integrated `Isar` NoSQL for local caching.
  - Refactored `TestProvider`, `ResourceProvider`, and `OfferProvider` for offline-first data flow.
- **Phase 2: Secure Server-Side Pricing** [COMPLETED]
  - Deployed SQL RPC functions for price verification.
  - Refactored `DirectCheckoutSheet` and `CartScreen` to use server-side verification.
- **Phase 3: Architecture Upgrades** [IN PROGRESS]
  - Migrated from `flutter_dotenv` to `envied` (Secrets Obfuscation).
  - Enforced API Type Safety in `TestService` (Typed models for all returns).
  - Implemented `RepaintBoundary` on all high-frequency list cards for performance.
  - Starting Migration from `Provider` to `Riverpod 3.0`.

---

## Tech Stack
| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.27+ (Dart) |
| State Management | Provider (Moving to Riverpod 3.0) |
| Local Cache | Isar NoSQL (Offline-First) |
| Backend / DB | Supabase (PostgreSQL) |
| Auth | Supabase Auth + Google Sign-In |
| Payments | Razorpay (Server-Verified via SQL RPC) |
| Environment | `envied` (Obfuscated Secrets) |

---

## Architecture

```
lib/
├── core/
│   ├── env/            # Envied configuration (env.dart)
│   ├── theme/          # Design tokens (AppColors, AppSpacing, AppTypography, AppTheme, AppRadius, AppMotion)
│   └── utils/          # db_error_helper.dart
├── data/
│   ├── local/          # Isar entities and schemas
│   ├── services/       # Core APIs (auth, payment, download, admin, notifications, caching)
├── domain/
│   └── models/         # Data models (MockTest, Resource, Offer, Order, etc.)
├── presentation/
│   ├── providers/      # State management (Transitioning to Riverpod Notifiers)
│   ├── screens/        # Admin and User screens
│   ├── utils/          # exam_helper, responsive scales
│   └── widgets/        # Reusable widgets
└── utils/              # price_calculator, excel_to_json_converter
```

---

## Payment Security (Phase 2 Rule)
- **NEVER** trust client-side math for payments.
- All checkouts MUST call `Supabase.instance.client.rpc('calculate_secure_price', ...)` before initializing `PaymentService.instance.openCheckout`.
- If RPC fails, abort checkout to prevent spoofing.

## Download Flow
- Tracks downloads via `DownloadService().isFileDownloaded()`.
- Files securely housed in `getApplicationDocumentsDirectory()/user_{userId}/`.
- Bypasses Supabase requests natively if downloaded locally.

---

## Design System (Token Law)
**Never use raw values.** Always use tokens from `AppTheme.colors`, `AppSpacing`, etc.
- **Responsive:** Use `ResponsiveBreakpoints` and `.h()`, `.w()`, `.sp()` extensions.
- **Asset Optimization:** Use `CachedNetworkImage` with custom `Shimmer` loaders.

---

## Sensitive Files (NEVER COMMIT)
- `**/service-account.json`
- `**/firebase-service.json`
- `.env`
- `**/google-services.json`
- `lib/core/env/env.g.dart` (Generated secrets)