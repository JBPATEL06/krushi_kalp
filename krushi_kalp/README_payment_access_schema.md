# Branch: `feature/payment-access-schema`

## What This Branch Does

This branch introduces a cleaner data architecture by replacing the
`orders` + `order_items` tables with two purpose-built tables:
`payment` and `access`. It also cleans up the `mock_tests` table.

---

## Summary of Changes

### 1. `mock_tests` table — Column Cleanup + New Flag

| Change | Detail |
|--------|--------|
| ✅ Added | `is_public BOOLEAN DEFAULT true` |
| ❌ Removed | `slug` — unused in Flutter code |
| ❌ Removed | `start_date` — unused in Flutter code |
| ❌ Removed | `end_date` — unused in Flutter code |

**`is_public` behaviour:**
- `true` → Test is **visible in the Store** and purchasable by any user.
- `false` → Test is **hidden from the Store**. Access is granted
  privately by admin inserting a row into the `access` table.

---

### 2. New `payment` Table (replaces `orders`)

**Purpose:** Pure financial transaction record.

**Key Design Decisions:**
- **No foreign keys** — Deleting a user or test does NOT corrupt
  payment history. The user's identity is preserved in `user_snapshot`.
- `user_snapshot` (JSONB) stores `{ "email": "...", "username": "..." }`
  at the moment of purchase.
- Supports multiple gateways: `razorpay`, `free`, `admin_grant`.
- `status` values: `PENDING`, `SUCCESS`, `FAILED`, `REFUNDED`.

**Columns:**

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID PK | Same UUID as migrated `order_id` |
| `user_id` | UUID | No FK — plain reference |
| `user_snapshot` | JSONB | `{email, username}` at purchase time |
| `amount` | NUMERIC | Total charged |
| `discount_amount` | NUMERIC | Discount applied |
| `offer_code` | TEXT | Offer code string (not FK) |
| `gateway` | TEXT | `razorpay` / `free` / `admin_grant` |
| `gateway_payment_id` | TEXT | Razorpay `pay_xxx` ID |
| `gateway_order_id` | TEXT | Razorpay `order_xxx` ID |
| `status` | TEXT | CHECK: PENDING/SUCCESS/FAILED/REFUNDED |
| `metadata` | JSONB | Raw gateway response (optional) |
| `created_at` | TIMESTAMPTZ | |
| `updated_at` | TIMESTAMPTZ | |

---

### 3. New `access` Table (replaces `order_items`)

**Purpose:** User entitlement record — who can access what.

**Key Design Decisions:**
- **No foreign keys** — Admin can delete users or tests without losing
  access history. Item identity is preserved in `item_snapshot`.
- **Covers both content types** via `item_type`:
  - `item_type = 'test'` → `item_id` refers to `mock_tests.test_id`
  - `item_type = 'resource'` → `item_id` refers to `resources.id`
- Unique constraint on `(user_id, item_type, item_id)` — no duplicates.
- `payment_id` is nullable — supports admin-granted (free) access
  without a payment record.
- `expires_at` supports time-limited access in future.

**Columns:**

| Column | Type | Description |
|--------|------|-------------|
| `id` | BIGINT PK | Auto-generated |
| `user_id` | UUID | No FK — plain reference |
| `payment_id` | UUID | No FK — nullable for free/admin grants |
| `item_type` | TEXT | CHECK: `test` / `resource` |
| `item_id` | BIGINT | No FK — test_id or resource id |
| `item_snapshot` | JSONB | `{title, category, price}` at grant time |
| `price_paid` | NUMERIC | Actual amount paid for this item |
| `granted_at` | TIMESTAMPTZ | When access was granted |
| `expires_at` | TIMESTAMPTZ | Nullable — for time-limited access |
| `is_active` | BOOLEAN | Admin can revoke by setting false |

---

## Data Migration

All existing data was migrated:

| Source | Destination | Rows |
|--------|-------------|------|
| `orders` | `payment` | 278 rows |
| `order_items` (tests) | `access` | 26 rows |
| `order_items` (resources) | `access` | 0 rows (none existed) |

Old tables (`orders`, `order_items`) are **kept** — not dropped.
They remain for backward compatibility until Flutter code is fully migrated.

---

## RLS Policies

Both new tables have Row Level Security enabled:

| Table | Policy | Rule |
|-------|--------|------|
| `payment` | User SELECT | `user_id = auth.uid()` |
| `payment` | Admin ALL | `role = 'Admin'` |
| `access` | User SELECT | `user_id = auth.uid()` |
| `access` | Admin ALL | `role = 'Admin'` |

---

## Flutter Files to Migrate (Next Phase)

> DB migration is done. Flutter code migration is a **separate phase**.

### Data Services
- `lib/data/services/test_service.dart`
  - `fetchPurchasedTestIds()` → query `access` table
  - `fetchUserTests()` → query `access` table
  - `streamPurchasedTests()` → stream `access` table
  - `claimFreeTest()` → insert into `access` (no payment)
  - `createDirectOrder()` → insert into `payment` table
  - `checkout()` → update `payment` + insert `access`
  - `deleteMockTest()` → remove FK error check (no FK anymore)
- `lib/data/services/cart_service.dart`
  - `checkOwnership()` → check `access` table
- `lib/data/services/resource_service.dart`
  - Resource purchase checks → check `access` table

### Domain Models
- `lib/domain/models/payment.dart` → **NEW**
- `lib/domain/models/access.dart` → **NEW**

### Presentation Layer
- Store screen → filter by `is_public = true`
- Library screen → read from `access` table
- Admin panel → read from `payment` table, insert into `access`

---

## Why No Foreign Keys?

Admin requirements:
1. Admin needs to **delete users** — FK would block deletion or cascade-delete payment history.
2. Admin needs to **delete mock tests** — FK would block deletion if any user purchased it.
3. **History must be preserved** — Snapshots in JSONB ensure full context even after deletion.

This pattern is standard for financial/audit systems.

---

*Migration executed: 2026-04-23 | Branch: feature/payment-access-schema*
