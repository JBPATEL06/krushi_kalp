# Krushi Kalp — Project Context

## What Is This

A Flutter-based **educational e-commerce app** for agricultural/competitive exam preparation in India. Users can browse, purchase, download, and take mock tests. Also supports e-books/resources, reviews, and a chat system. Payments via Razorpay (UPI-only). Backend is Supabase + Firebase (FCM for notifications).

There is also an **admin** project at `../admin/krushi_kalp/` that mirrors the same codebase structure but adds admin panel features.

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
| File Storage | Supabase Storage (buckets: `mock_test`, resources) |
| Environment | `flutter_dotenv` → `.env` file |
| Encryption | `encrypt` package (AES-256) for session IDs |

---

## Architecture

```
lib/
├── core/theme/          # Design tokens (AppColors, AppSpacing, AppTypography, AppTheme)
├── data/
│   ├── repositories/    # mock_repository.dart
│   ├── services/        # 19 service files (API, auth, payment, download, etc.)
│   └── sql/             # SQL migration files
├── domain/
│   ├── models/          # 15 data models (MockTest, Resource, Offer, Order, etc.)
│   └── services/        # pdf_service.dart
├── presentation/
│   ├── providers/       # 8 providers (Auth, Test, Cart, Resource, Offer, etc.)
│   ├── screens/         # ~33 screens + store/widgets subfolder
│   ├── utils/           # exam_helper, navigator_key, etc.
│   └── widgets/         # Reusable widgets (UniversalItemCard, DownloadActionButton, etc.)
└── utils/               # price_calculator, network_utils, excel_to_json_converter
```

### Key Patterns
- **No raw values in UI** — use `AppColors`, `AppSpacing`, `AppTypography` tokens
- **UniversalItemCard** is the standard card widget for all items (tests, resources)
- **DownloadActionButton** dynamically shows "Download" or "Start"/"Open" based on local file status
- **PriceCalculator** handles all price/discount/offer logic centrally
- **ExamHelper** manages the test-start flow (language selection → download check → exam screen)
- Services use `Supabase.instance.client` directly (no repository abstraction for most)

---

## Environment Variables (.env)

```
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
RAZORPAY_KEY_ID=...
```

**NEVER** commit `.env` to git. It's in `.gitignore`.

---

## Sensitive Files (NEVER commit these)

These are in `.gitignore` and must stay there:

- `**/service-account.json` — Firebase service account with private keys
- `**/firebase-service.json` — Firebase credentials
- `*.env` — Environment variables
- `**/google-services.json` — Android Firebase config
- `**/diff_log.txt`, `temp_truth.ts`, `test_deno.ts`, `**/test_auth.js`

---

## Key Providers & What They Manage

| Provider | Responsibility |
|----------|---------------|
| `AuthProvider` | Login/logout, Google Sign-In, session monitoring, role checking |
| `TestProvider` | Fetch all/purchased mock tests, purchase status tracking |
| `ResourceProvider` | Fetch resources, purchased resources, categories |
| `CartProvider` | Cart items, add/remove, cart total |
| `OfferProvider` | Active offers/coupons, sale offers |
| `NavigationProvider` | Bottom nav index, selected store category |
| `NetworkProvider` | Online/offline status |
| `AdminProvider` | Admin role check |

---

## Database Tables (Supabase)

Key tables referenced in code:
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

1. User taps "Buy Now" → `DirectCheckoutSheet` opens (or full `CartScreen` → `CheckoutScreen`)
2. Optional coupon code entry → validated via `OfferService.verifyCoupon()`
3. Order created in `orders` table via `TestService.createDirectOrder()`
4. Razorpay opens with amount (UPI-only enabled)
5. On success → `TestService.checkout()` updates order status to SUCCESS
6. **Known gap:** No server-side Razorpay signature verification exists yet

---

## Download Flow (Mock Tests)

1. User navigates to purchased test → sees `DownloadActionButton`
2. Button checks `DownloadService().isFileDownloaded(filename, userId: currentUserId)`
3. Files stored in `getApplicationDocumentsDirectory()/user_{userId}/`
4. If not downloaded → downloads JSON from Supabase Storage
5. If downloaded → `ExamHelper.startExam()` → language selection → exam screen

---

## Known Issues / Technical Debt

### Audit v2.0 (March 2026) - **NEW**
- **Architecture**: Tight coupling to Supabase. **Fix**: Implement Repository Pattern.
- **Security**: Client-side pricing logic. **Fix**: Backend price validation.
- **Payment Reliability**: No webhooks for Razorpay. **Fix**: Implement Server-side Webhooks.
- **Performance**: N+1 Signed URL fetching for thumbnails. **Fix**: Batch URL signing + 50min TTL Cache.
- **Stability**: Missing `dispose()` logic in 8+ providers; double-tap buy race conditions; **Fixed**: Synchronization Gates blocking parallel fetches in `ResourceProvider`.
- **Garbage Code**: Identified legacy `purchaseMockTest`, `applyCouponToOrder`, and dead `AdminProvider`.

---

## 🚀 Enterprise Refactoring Roadmap

| Phase | Goal | Key Action |
|---|---|---|
| **Phase 1** | Stability | Fix Race conditions, Memory leaks, and Dispose logic. |
| **Phase 2** | Scalability | Standardize Service Patterns (Singletons) & Repositories. |
| **Phase 3** | Performance | Implement Signed URL Caching & Batching. |
| **Phase 4** | Security | Setup Razorpay Webhooks (Edge Functions). |

---

---

## Files That Exist But Are Unused (Kept for Future Use)

These files are not imported anywhere currently. Delete or integrate as needed:
- **Screens:** `checkout_screen`, `my_library_screen`, `network_pdf_viewer_screen`, `test_attempt_screen`
- **Models:** `feedback_model`, `notification`, `order`, `transaction`, `user`
- **Services:** `admin_service.dart` (24KB), `view_options_bottom_sheet`, `responsive.dart`
- **Widgets:** `shimmer_loading`, `custom_text_field`

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

- **Main branch** is the primary branch — commit directly
- Always verify no secrets in staged files before committing
- `.gitignore` is configured to block all sensitive files
- `node_modules/` exists under `krushi_kalp/` (for Supabase Edge Functions tooling)

---

## Recent Improvements (Brief)

1.  **Download Sandbox:** Implemented per-user storage (`user_{userId}/`) with an ownership `_manifest.json` for security.
2.  **Global Network Gate:** A top-level `NetworkAwareWrapper` that intercepts navigation and forces a locked "No Internet" screen.
3.  **Splash & Launch Polishing:** Sized native/flutter logos (180dp), added dark mode splash, and cut startup delays by 50%.
4.  **Premium Dual-Theme:** Implemented Material 3 systems (Indigo+Saffron & Forest Sage) with `ThemeMode.system` auto-detection.
5.  **Initialization Stability:** Moved all setup into `runZonedGuarded` to prevent Zone mismatch crashes.
6.  **System-Wide SafeArea Audit:** Implemented `SafeArea` at the bottom of all interaction-heavy screens (`Exam`, `Chat`, `Cart`, `DirectCheckout`, `TestResult`) to prevent system navigation bar overlaps.
7.  **Native PDF Theming:** Added automatic light/dark mode detection and a manual Night Mode toggle to the PDF viewers, leveraging `flutter_pdfview`'s native inversion logic.
8.  **Timezone Compliance (UTC to Local):** Centralized UTC-to-Local conversion in the `TestResult` model. Improved time formatting with leading zeros for a consistent enterprise-grade feel.
9.  **Icon Clarity standard:** Updated all profile and setting icons to use `theme.colorScheme.primary` tokens, ensuring high visibility and branding consistency in dark mode.
10. **UI Polishing:** Resolved double-timer logic in `ExamScreen`, standardized button sizes in `TestResult`, and removed redundant AppBars to maximize content real estate.
11. **Sync Gate Stabilization:** Refined Synchronization Gates in `ResourceProvider` and `TestProvider` to allow parallel background fetches (e.g., in `MainScreen`) while still preventing redundant UI rebuilds.
12. **Free Material UI Overhaul:** Created a specialized `FreeItemCard` and redesigned the `FreeContentScreen` with an integrated Search/Filter top bar, animated pills, and surface-consistent backgrounds for a premium feel.
13. **Real-time Cost Optimization:** Converted the "All Mock Tests" screen from `StreamBuilder` to `FutureBuilder`. This prevents persistent database connections while the user browses the test list, reducing Supabase costs.
14. **Refresh & Startup Stability:**
    - Added a **20-second safety timeout** and **parallelized background fetches** to the `HomeScreen` pull-to-refresh logic to prevent "infinite loading" hangs.
    - Extended the `SplashScreen` parallel initialization timeout to **5 seconds** for more resilient cold starts.
    - Integrated `RetryHelper` with 10s individual timeouts in `AppConfigService`.
15. **System Nav & Contact Refinement:** Removed WhatsApp from contact options in `ProfileScreen` and implemented `SafeArea` in the "Contact Us" modal to resolve overlaps with the system navigation/gesture bar.
16. **Dark Mode Green Accent:** Replaced red/pink accent colors with a vibrant emerald green in Dark Mode (#2DD4BF) for a more cohesive, high-trust agricultural aesthetic.

---

## The "Stitch Rule" — Store Card Math

The Store Screen (Tests/Resources) uses a strictly responsive "Stitch Math" layout:

| Property | Rule |
|---|---|
| Card dimensions | **92%** screen width, **25%** screen height |
| Internal split | **40%** Image / **60%** Content (horizontal) |
| Typography | Title font size = **7%** of card height |
| Spacing | All padding/margins = **5%** of card dimensions |

**Plan:** Replace `UniversalItemCard` in store grids with the new `StoreItemCard` widget to achieve a premium look while preserving all purchase/download logic.

<!-- Updated by Gemini Flash on 2026-03-07 at 01:00 AM -->
