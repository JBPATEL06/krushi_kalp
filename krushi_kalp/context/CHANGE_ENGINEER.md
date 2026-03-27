# 🔄 Engineer Handoff — Krushi Kalp
**Last Updated:** 2026-03-28 | **Outgoing:** Session AI | **Branch:** `feature-backup`

> ⚠️ **Read this file completely before touching any code.**

---

## 1. Project Overview

Krushi Kalp is an **agricultural education app** (Flutter) with:
- Mock tests (MCQ-based exam preparation)
- Study resources / e-books / PYQs / current affairs
- Razorpay payment integration
- Admin panel (offer management, user management, chat, revenue)
- Firebase Crashlytics + FCM push notifications
- Supabase (PostgreSQL) backend

---

## 2. How to Read the Project

### Primary Context Files

| File | Purpose |
|------|---------|
| [`CLAUDE.md`](../CLAUDE.md) | AI assistant rules — same rules apply to all engineers |
| [`GEMINI.md`](../GEMINI.md) | Architecture & coding standards — **mandatory reading** |
| [`AGENTS.md`](../AGENTS.md) | Tech stack map and feature folder overview |
| [`context/calculate_secure_price.sql`](./calculate_secure_price.sql) | Server-side price validation RPC — deploy to Supabase |
| [`context/calculate_secure_cart_price.sql`](./calculate_secure_cart_price.sql) | Server-side cart price validation RPC — deploy to Supabase |
| [`context/code_audit_report.md`](./code_audit_report.md) | Known issues to fix before launch |

---

## 3. Tech Stack (Do Not Change Without Discussion)

| Layer | Technology | Version |
|-------|-----------|---------|
| Framework | Flutter | 3.27+ Stable |
| State Management | Provider (`ChangeNotifier`) | 6.x — *migration to Riverpod 3.0 is planned but NOT done yet* |
| Local Cache | Isar (NoSQL) + SharedPreferences | 3.1.0 |
| Backend | Supabase (PostgreSQL + PostgREST + Auth) | — |
| Payments | Razorpay | — |
| Navigation | GoRouter (declarative) | — |
| Responsiveness | `responsive_framework` | — |
| Secrets | Envied (compile-time) | 0.5.x |
| Crash Reporting | Firebase Crashlytics | — |
| Push Notifications | Firebase FCM | — |

---

## 4. Database Schema (Data Dictionary)

> **Source of truth is Supabase.** This is a summary — always check Dashboard for latest.

### `users`
| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid (PK) | FK → `auth.users(id)` |
| `username` | text | |
| `email` | text | |
| `role` | text | `'Student'` or `'Admin'` |
| `phonenumber` | text | |
| `phone_verified` | boolean | |
| `language` | text | `'en'` default |
| `session_id` | text | |
| `fcm_token` | text | Push notification target |
| `created_at` | timestamptz | |

### `mock_tests`
| Column | Type | Notes |
|--------|------|-------|
| `test_id` | bigint (PK) | **NOT `id`** |
| `title` | text | |
| `price` | numeric | No `mrp` column — DO NOT query `mrp` |
| `duration_minutes` | integer | |
| `total_questions` | integer | |
| `is_active` | boolean | |
| `slug` | text (UNIQUE) | |
| `category`, `language`, `file_path`, `cover_image_path` | text | |

### `resources`
| Column | Type | Notes |
|--------|------|-------|
| `id` | bigint (PK) | |
| `title` | text | |
| `type` | text | `current_affair`, `study_material`, `ebook`, `pyq` |
| `price` | numeric | No `mrp` column — DO NOT query `mrp` |
| `file_url`, `thumbnail_url` | text | |
| `is_active` | boolean | |

### `offers`
| Column | Type | Notes |
|--------|------|-------|
| `offer_id` | bigint (PK) | **NOT `id`** |
| `code` | text (UNIQUE) | Coupon code |
| `discount_type` | text | `'PERCENTAGE'` or `'FLAT'` |
| `discount_value` | numeric | |
| `target_type` | text | `'ALL'`, `'USER'`, `'TEST'`, `'BUNDLE'` |
| `is_active` | boolean | |
| `is_sale` | boolean | `true` = auto-applied sale, `false` = coupon |
| `is_real` | boolean | `true` = live offer, `false` = test/fake — **always filter `is_real = true`** |
| `min_order_value`, `max_discount` | numeric | |
| `start_date`, `end_date` | timestamptz | |

### `orders`
| Column | Type | Notes |
|--------|------|-------|
| `order_id` | uuid (PK) | **NOT `id`** |
| `user_id` | uuid | FK → `users` |
| `status` | text | `PENDING`, `SUCCESS`, `FAILED`, `DIRECT_CHECKOUT` |
| `total_amount`, `discount_amount` | numeric | |
| `offer_id` | bigint | FK → `offers(offer_id)` |

### `order_items`
| Column | Type | Notes |
|--------|------|-------|
| `item_id` | bigint (PK) | |
| `order_id` | uuid | FK → `orders(order_id)` |
| `test_id` | bigint | FK → `mock_tests(test_id)` — nullable |
| `resource_id` | bigint | FK → `resources(id)` — nullable |
| `price_at_purchase` | numeric | |
| `applied_offer_id` | bigint | FK → `offers(offer_id)` |

### `results`
| Column | Type | Notes |
|--------|------|-------|
| `result_id` | bigint (PK) | |
| `user_id` | uuid | FK → `users` |
| `test_id` | bigint | FK → `mock_tests(test_id)` |
| `score_obtained`, `correct_answers`, `incorrect_answers` | numeric/int | |

---

## 5. ✅ What Is Currently WORKING — Do NOT Break

| Feature | Status | Key Files |
|---------|--------|-----------|
| **Payment — Pay Now (single item)** | ✅ Live | `direct_checkout_sheet.dart` |
| **Payment — Cart Checkout** | ✅ Live | `cart_screen.dart` |
| **Server-side price RPC** | ✅ Live on Supabase | `calculate_secure_price.sql` |
| **Server-side cart RPC** | ✅ Live on Supabase | `calculate_secure_cart_price.sql` |
| **Razorpay gateway** | ✅ Opens correctly | `payment_service.dart` |
| **Isar local DB** | ✅ Working (patched) | See §6 for the patch |
| **Android build** | ✅ Builds on AGP 8.9.1 | See §6 for the patch |
| **Firebase Crashlytics** | ✅ Reporting errors | `crashlytics_service.dart` |
| **FCM Push Notifications** | ✅ Working | `fcm_service.dart` |
| **Offer/Discount logic** | ✅ Server enforced | SQL RPCs filter `is_real = true` |
| **GoRouter Navigation** | ✅ Working | `lib/core/router/` |
| **Admin panel** | ✅ Working | `lib/presentation/screens/admin/` |

---

## 6. ⚠️ Critical Infrastructure Patches (Machine-Specific)

### Isar Namespace Fix (Android)
The `isar_flutter_libs` package (v3.1.0+1) is **incompatible with AGP 8.9.1** out of the box.

**A manual patch was applied to the pub cache** on the development machine:

**File:** `%APPDATA%\Pub\Cache\hosted\pub.dev\isar_flutter_libs-3.1.0+1\android\build.gradle`

The following lines were added:
```gradle
android {
    namespace 'dev.isar.isar_flutter_libs'  // ← ADDED
    compileSdkVersion 34                      // ← CHANGED from 33
}
```

> ⚠️ **Every new developer machine needs this patch applied manually.**
> **Permanent fix:** Migrate to `isar 4.x` (planned, not done yet).

---

## 7. 🔴 Known Bugs — Fix Before Launch

Listed in priority order:

| # | Bug | File | Fix |
|---|-----|------|-----|
| 1 | `Resource.fromJson` crashes if cache has null `id` | `domain/models/resource.dart:45` | Add `(json['id'] as num?)?.toInt() ?? 0` |
| 2 | Duplicate Hero tags crash on navigation | `widgets/common/universal_item_card.dart:104` | Use item ID in hero tag instead of title+price |
| 3 | `get_user_performance` RPC missing on Supabase | `data/services/performance_service.dart` | Create the SQL function on Supabase |
| 4 | `Resource.mrp` / `Resource.discount` ghost fields | `domain/models/resource.dart:17-18` | Remove — not in DB schema |
| 5 | No `RepaintBoundary` on list cards | All item card widgets | Wrap with `RepaintBoundary` |
| 6 | Impeller opt-out deprecated | `AndroidManifest.xml` | Remove `EnableImpeller=false` entry |

---

## 8. Supabase RLS — Verify Before Launch

Open Supabase Dashboard → Authentication → Policies and confirm these tables have RLS **enabled** with user-scoped SELECT policies:

- `orders` — users can only read their own orders
- `order_items` — users can only read their own items
- `results` — users can only read their own results
- `users` — users can only read/update their own row

---

## 9. Environment Variables

Secrets are managed via **Envied** — never hardcode.

`.env` file is git-ignored. New engineers must create it from the team's secret store.

Run after creating `.env`:
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 10. SQL Functions — Must Deploy to Supabase

Both files in `context/` must be deployed using the Supabase SQL Editor (`CREATE OR REPLACE FUNCTION`):

1. `calculate_secure_price.sql` — validates price for single item purchase
2. `calculate_secure_cart_price.sql` — validates price for cart checkout

**These are security-critical.** Without them, the payment buttons will show an error and abort.

---

## 11. Branch Strategy

| Branch | Purpose |
|--------|---------|
| `main` | Production-ready code |
| `feature-backup` | Last stable snapshot before this handoff (2026-03-28) |

---

## 12. First Day Checklist for New Engineer

- [ ] Clone repo, install Flutter 3.27+ stable
- [ ] Apply the Isar pub-cache patch (§6)
- [ ] Create `.env` from team secrets
- [ ] Run `flutter pub get` then `dart run build_runner build --delete-conflicting-outputs`
- [ ] Deploy both SQL files from `context/` to Supabase SQL Editor
- [ ] Verify RLS is enabled on `orders`, `order_items`, `results`, `users`
- [ ] Run app on Android device and verify payment flow end-to-end
- [ ] Read `GEMINI.md` for coding standards before writing any code
