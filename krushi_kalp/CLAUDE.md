# Krushi Kalp — Unified Project Context

> **Merged Project** — Single codebase serving both the **User App** (agricultural e-commerce, exam prep) and the **Admin Panel** (content management, monitoring). Role is determined from `users.role` column. `role == 'Admin'` → admin panel. All others → user app.

---

## What Is This

A Flutter-based **educational e-commerce app** for agricultural/competitive exam preparation in India. Users can browse, purchase, download, and take mock tests. Supports e-books/resources, reviews, and a chat system. Payments via Razorpay (UPI-only). Backend is Supabase + Firebase (FCM for notifications).

The **Admin Panel** is built into the same codebase. Admin accounts land on `AdminMainScreen` (sidebar navigation) after login. Regular users land on `MainScreen` (bottom navigation).

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| State Management | Provider (ChangeNotifier) |
| Backend / DB | Supabase (PostgreSQL) |
| Auth | Supabase Auth + Google Sign-In |
| Payments | Razorpay Flutter (UPI-only) |
| Push Notifications | Firebase Cloud Messaging (FCM) |
| OTP | MSG91 via Supabase Edge Function (`/functions/v1/otp`) |
| FCM Edge Function | Supabase Edge Function (`/functions/v1/send-fcm`) |
| File Storage | Supabase Storage (buckets: `mock_test`, `resources`) |
| Environment | `flutter_dotenv` → `.env` file |
| Encryption | `encrypt` package (AES-256) for session IDs |
| Crash Reporting | Firebase Crashlytics (user app only) |
| Excel Upload | `excel` package + custom JSON converters (admin only) |

---

## Architecture

```
lib/
├── core/
│   ├── theme/          # Design tokens (AppColors, AppSpacing, AppTypography, AppTheme, AppRadius, AppMotion)
│   └── utils/          # db_error_helper.dart (PostgrestException translator)
├── data/
│   ├── repositories/   # mock_repository.dart
│   ├── services/       # 19 service files (API, auth, payment, download, admin, etc.)
│   └── sql/            # SQL migration files
├── domain/
│   ├── models/         # 15 data models (MockTest, Resource, Offer, Order, etc.)
│   └── services/       # pdf_service.dart
├── presentation/
│   ├── providers/      # 9 providers (Auth, Test, Cart, Resource, Offer, Admin, Navigation, Network)
│   ├── screens/
│   │   ├── admin/      # All admin screens (AdminMainScreen, dashboard, users, offers, resources, etc.)
│   │   └── ...         # ~33 user screens (home, store, exam, profile, etc.)
│   ├── utils/          # exam_helper, navigator_key, etc.
│   └── widgets/        # Reusable widgets (UniversalItemCard, DownloadActionButton, etc.)
└── utils/              # price_calculator, network_utils, excel_to_json_converter
```

---

## Role-Based Routing

**Entry Point:** `SplashScreen` → checks `AuthProvider.isLoggedIn` + `AuthProvider.userRole`

```
SplashScreen
├── Not logged in → LoginScreen
├── Logged in, role == 'Admin'
│   ├── maintenance mode → MaintenanceScreen (even admin sees it? No — admin bypasses)
│   └── → AdminMainScreen (sidebar nav: Dashboard, Analytics, Users, Alerts, Manage App)
└── Logged in, role != 'Admin'
    ├── maintenance mode → MaintenanceScreen
    └── → MainScreen (bottom nav: Home, Mocks, Store, Downloads, Profile)
```

**Login Screen** also routes based on role after successful authentication.

---

## Key Providers & What They Manage

| Provider | Responsibility |
|----------|---------------|
| `AuthProvider` | Login/logout, Google Sign-In, session monitoring, role checking (`isAdmin`) |
| `AdminProvider` | Admin panel nav index state (`navIndex`) |
| `TestProvider` | Fetch all/purchased mock tests, purchase status tracking |
| `ResourceProvider` | Fetch resources, purchased resources, categories |
| `CartProvider` | Cart items, add/remove, cart total |
| `OfferProvider` | Active offers/coupons, sale offers |
| `NavigationProvider` | Bottom nav index (user), selected store category |
| `NetworkProvider` | Online/offline status |

---

## Admin Panel Screens

Located in `lib/presentation/screens/admin/`:

| Screen | Purpose |
|--------|---------|
| `AdminMainScreen` | Sidebar layout: drawer (mobile), rail (tablet), persistent (desktop) |
| `AdminHomeScreen` | Dashboard stats: revenue, users, tests, resources |
| `AdminAnalysisScreen` | Revenue analytics charts |
| `AdminUserListScreen` | All users table with search |
| `AdminUserDetailsScreen` | User profile, orders, support history |
| `AdminNotificationScreen` | Broadcast + personal FCM alerts |
| `AdminOfferListScreen` | Coupon/offer list |
| `AdminOfferManageScreen` | Create/Edit offer forms |
| `AdminOrderListScreen` | Transaction monitor (Razorpay orders) |
| `AdminProfileScreen` | Admin profile card |
| `AdminReviewsScreen` | Review moderation |
| `AdminChatListScreen` | Support conversations list |
| `AdminChatDetailScreen` | Individual chat thread |
| `MockTestEditScreen` | Edit test metadata (title, price, MRP) |
| `RevenueDetailsScreen` | Transaction detail popup with items |
| `ManageAppScreen` | AppConfig tabs (maintenance, flags, banners, legal) |
| `AdminResourcesDashboard` | Resources section dashboard |
| `AdminMockTestList` | Mock test list management |
| `AdminMockTestDetailScreen` | Detail view with PDF actions |
| `AdminResourceList` | Resource list management |
| `AdminResourceDetailScreen` | Resource detail with share |
| `AdminResourceForm` | Create/Edit resource form |

---

## Admin-Specific Capabilities

### 1. Mock Test Engine
- **Excel Upload**: Admins upload Excel → converted to JSON → pushed to Supabase Storage.
- **Metadata Management**: Titles, categories, pricing, MRP.
- **Signed URL Generation**: Access tokens for premium content.

### 2. Configuration Control (`app_config`)
- **Maintenance Mode**: Toggle global lock + custom message.
- **Feature Flags**: Enable/Disable reviews, change banner scroll speed.
- **Contact Info**: WhatsApp, Telegram, Support Email.
- **Legal**: Privacy Policy and Terms URLs.

### 3. Notification Hub
- **Broadcasts**: Push to all users.
- **Personal Alerts**: Push to specific user.
- **System Integration**: Automated alerts for new tests/sales.

### 4. User & Transaction Monitoring
- **User Records**: View profiles, roles, support history.
- **Transactions**: Monitor Razorpay SUCCESS/COMPLETED orders and items.
- **DbErrorHelper**: Translates `PostgrestException` codes (e.g., 23503) into actionable messages.

---

## User App Screens (Brief)

| Screen | Purpose |
|--------|---------|
| `HomeScreen` | Banners, quick navigation, featured tests |
| `StoreScreen` | All tests + resources, filter by category |
| `PurchasedTestsScreen` | User's purchased mock tests |
| `DownloadsScreen` | Downloaded test files |
| `ProfileScreen` | Account, settings, contact |
| `ExamScreen` | Active mock test / exam UI |
| `TestResultScreen` | Score, analysis, time breakdown |
| `ResourceDetailScreen` | PDF resource detail + purchase |
| `MockTestDetailScreen` | Test detail + purchase/download |
| `CartScreen` | Cart management + checkout |
| `ChatScreen` | User ↔ Admin support chat |
| `FreeContentScreen` | Free materials browser |

---

## Database Tables (Supabase)

- `users` — id, email, username, role, language, phonenumber, session_id
- `mock_tests` — test_id, title, price, mrp, content_url, total_questions, etc.
- `resources` — id, title, price, type, file_url, thumbnail_url, category
- `orders` — order_id, user_id, status (SUCCESS/COMPLETED), created_at
- `order_items` — order_id, test_id, resource_id
- `reviews` — id, item_id, item_type, user_id, rating, comment
- `offers` — id, code, discount_type, discount_value, is_sale, valid dates
- `app_config` — key-value store for feature flags, maintenance mode, legal URLs
- `home_banners` — banner images and links
- `notifications` — push notification records

---

## App Config (Remote Feature Flags)

Stored in `app_config` table, accessed via `AppConfigService`:
- `feature_reviews` → `show_reviews`, `allow_writing`
- `app_status` → `maintenance_mode`, `message`, `min_version`
- `contact_info` → `whatsapp`, `email`, `telegram`
- `legal_urls` → `privacy_policy`, `terms_conditions`
- `banner_settings` → `interval`, `auto_scroll`

---

## Payment Flow

1. User taps "Buy Now" → `DirectCheckoutSheet` or `CartScreen` → `CheckoutScreen`
2. Optional coupon code → `OfferService.verifyCoupon()`
3. Order created via `TestService.createDirectOrder()`
4. Razorpay opens (UPI-only)
5. On success → `TestService.checkout()` updates order status to SUCCESS
6. **Known gap:** No server-side Razorpay signature verification

---

## Download Flow (Mock Tests)

1. User → purchased test → `DownloadActionButton`
2. Checks `DownloadService().isFileDownloaded(filename, userId: currentUserId)`
3. Files stored in `getApplicationDocumentsDirectory()/user_{userId}/`
4. Not downloaded → downloads JSON from Supabase Storage
5. Downloaded → `ExamHelper.startExam()` → language selection → exam screen

---

## Environment Variables (.env)

```
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
RAZORPAY_KEY_ID=...
```

**NEVER** commit `.env` to git. It's in `.gitignore`.

---

## Sensitive Files (NEVER commit)

- `**/service-account.json`
- `**/firebase-service.json`
- `*.env`
- `**/google-services.json`
- `**/diff_log.txt`, `temp_truth.ts`, `test_deno.ts`, `**/test_auth.js`

---

## Design System

### Token Law (Anti-Gravity Rule)
No raw values in UI. Always use tokens:

```dart
AppTheme.colors.primary       // Colors
AppSpacing.md                 // Spacing (8pt grid)
AppTypography.bodyLarge       // Typography
AppRadius.md                  // Radius
AppMotion.normal              // Animation durations
```

### Edge-to-Edge Navigation / System UI Overlaps
For premium design, **do not** use `SafeArea(bottom: true)` as a catch-all. It creates boxy "dead zones" above the gesture bar. Instead, achieve a native edge-to-edge look by adding system padding to the bottom of the scrolling content. This ensures background colors bleed to the edge while interactive elements remain protected:

```dart
padding: EdgeInsets.fromLTRB(
  AppSpacing.md, // Left
  AppSpacing.md, // Top
  AppSpacing.md, // Right
  AppSpacing.md + MediaQuery.of(context).padding.bottom, // Bottom (Base + System)
)
```

### The "Stitch Rule" — Store Card Math

| Property | Rule |
|---|---|
| Card dimensions | **92%** screen width, **25%** screen height |
| Internal split | **40%** Image / **60%** Content (horizontal) |
| Typography | Title font size = **7%** of card height |
| Spacing | All padding/margins = **5%** of card dimensions |

### Dual Theme
- Light: Indigo + Saffron
- Dark: Forest Sage with Emerald Accent (#2DD4BF)
- `ThemeMode.system` — auto-detects device setting

---

## Build & Run

```bash
# Run in debug
flutter run

# Build release APK (always use obfuscation)
flutter build apk --obfuscate --split-debug-info=debug-info/

# Clean build
flutter clean && flutter pub get && flutter run
```

---

## Git Conventions

- **Main branch** — commit directly
- Always verify no secrets in staged files
- `.gitignore` blocks all sensitive files
- `node_modules/` exists under `krushi_kalp/` (Supabase Edge Functions tooling)

---

## Known Issues / Technical Debt

### Active
- **Signal 3 (ANR) Crash** (Admin): Persistent main-thread blocking during startup/dashboard transition. Partially mitigated via lazy loading in `AdminMainScreen`. **Status: Unresolved**
- **Security**: Client-side pricing logic. **Fix needed**: Backend price validation.
- **Payment Reliability**: No Razorpay webhooks. **Fix needed**: Server-side webhook Edge Functions.
- **Performance**: N+1 Signed URL fetching for thumbnails. **Fix needed**: Batch URL signing + 50min TTL Cache.

---

## 🚀 Enterprise Refactoring Roadmap (Post-Merge)

| Phase | Goal | Key Action |
|---|---|---|
| **Phase A** | Stability | Fix Race conditions, Memory leaks, Dispose logic |
| **Phase B** | Scalability | Standardize Service Patterns (Singletons) & Repositories |
| **Phase C** | Performance | Signed URL Caching & Batching |
| **Phase D** | Security | Razorpay Webhooks (Edge Functions) |

---

## Merge Progress Log

| Phase | Description | Status |
|---|---|---|
| **Phase 0** | Planning & Documentation | ✅ Complete |
| **Phase 1** | Foundation — main.dart + AdminProvider + pubspec audit | ⬜ Pending |
| **Phase 2** | Core Routing — splash_screen + admin route | ⬜ Pending |
| **Phase 3** | Admin Screen Migration (16+ screens) | ⬜ Pending |
| **Phase 4** | Admin Service Migration | ⬜ Pending |
| **Phase 5** | Core/Widget Parity + db_error_helper | ⬜ Pending |
| **Phase 6** | End-to-End Testing | ⬜ Pending |
| **Phase 7** | Cleanup + Final CLAUDE.md Update | ⬜ Pending |

---

## Historical Improvements (Brief)

### User App (Pre-Merge)
1. **Download Sandbox**: Per-user storage (`user_{userId}/`) with `_manifest.json`.
2. **Global Network Gate**: `NetworkAwareWrapper` intercepts navigation on offline.
3. **Premium Dual-Theme**: Material 3 (Indigo+Saffron & Forest Sage), `ThemeMode.system`.
4. **Initialization Stability**: `runZonedGuarded` prevents Zone mismatch crashes.
5. **System-Wide SafeArea Audit**: `SafeArea` on all interaction-heavy screens.
6. **Native PDF Theming**: Auto light/dark + manual Night Mode toggle.
7. **Timezone Compliance**: UTC-to-Local in `TestResult` model, IST display.
8. **Sync Gate Stabilization**: Parallel background fetches in `ResourceProvider` + `TestProvider`.
9. **Free Material UI Overhaul**: `FreeItemCard` + animated pills + search bar.
10. **Real-time Cost Optimization**: `StreamBuilder` → `FutureBuilder` on "All Mock Tests".
11. **Refresh Safety**: 20s timeout + parallelized HomeScreen pull-to-refresh.
12. **Dark Mode Green Accent**: Emerald green (#2DD4BF) replaces red in dark mode.
13. **Splash Screen Redesign**: Premium progress bar, playstore icon, academic branding.
14. **System Navigation Bar Overlap Audit**: Reactive `MediaQuery` padding applied globally to 35+ screens.

### Admin Panel (Pre-Merge)
1. **Phase 1**: Core token sync, `ThemeMode.system`, light/dark themes.
2. **Phase 2**: Token applied to all common widgets (`AppButton`, `AppCard`, etc.).
3. **Phase 3**: All high-traffic admin screens migrated (Home, Profile, ManageApp).
4. **Phase 4**: Global theme sweep, package imports standardized, 0 lint errors.
5. **Phase 5**: Sidebar Navigation + Top App Bar architecture. Row-based Material 3 aesthetic.
6. **Phase 6**: `fetchOrderById` for rich transaction joins. Interactive detail popups.
7. **Phase 7**: Premium full-screen detail views for resources + mock tests. PDF sharing.
8. **Phase 8**: `DbErrorHelper` for friendly PostgrestException translation.
9. **Phase 9**: Premium splash screen with progress bar. Login logo at `130x130`.
10. **Global UI Resilience**: System navigation bar overlap audit and fix across all management screens.

---

<!-- Updated by Gemini: System Nav Bar Overlap Audit Complete (35+ screens) — 2026-03-07 -->
