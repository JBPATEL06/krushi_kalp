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
## 3. Services Layer (`lib/data/services/` & `lib/domain/services/`)

Services handle the heavy lifting: database calls via Supabase, external APIs, and local logic.

### Core Business Services

| File | Purpose | Key Functions |
|------|---------|---------------|
| `auth_service.dart` | Authentication logic. | `signInWithGoogle`, `signInWithEmail`, `signOut`, `getUserRole`. |
| `app_config_service.dart` | Global config fetching. | `fetchConfig`, `getMaintenanceMode`, `getLegalUrls`. |
| `admin_service.dart` | Admin-only DB operations. | `fetchDashboardStats`, `fetchUserList`, `updateUserRole`. |
| `test_service.dart` | Mock test lifecycle. | `fetchMockTests`, `submitTestResult`, `checkout`, `fetchPurchasedTestIds`. |
| `resource_service.dart` | Resource management. | `fetchResources`, `fetchPurchasedResources`, `claimResource`. |
| `cart_service.dart` | Shopping cart persistence. | `fetchCartItems`, `addToCart`, `removeCartItem`, `checkOwnership`. |

### Infrastructure & Communication

| File | Purpose | Key Functions |
|------|---------|---------------|
| `notification_service.dart` | Local & Stream listeners. | `initialize`, `connectUser`, `showLocalNotification`, `fetchNotificationsStream`. |
| `fcm_service.dart` | Push notification setup. | `initialize`, `onMessage.listen`, `_saveTokenToDatabase`. |
| `admin_notification_service.dart` | Sending FCM pushes. | `sendBroadcastNotification`, `sendPersonalNotification`. |
| `background_upload_service.dart` | Non-blocking background uploads. | `uploadFile`, `cancelTask`. |
| `transfer_notification_service.dart` | Unified transfer progress. | `showUploadProgress`, `showDownloadProgress`. |
| `chat_service.dart` | Real-time support chat. | `fetchMessageStream`, `sendMessage`, `getAdminConversations`. |
| `otp_service.dart` | SMS OTP via MSG91. | `sendOtp`, `resendOtp`, `verifyOtp`. |
| `encryption_service.dart` | Security utilities. | `encryptData`, `decryptData` (used for session IDs). |
| `supabase_url_helper.dart`| Signed URL management. | `getFreshSignedUrl`, `forceRefresh`, `extractPathFromUrl`. |
| `crashlytics_service.dart`| Error & Log management. | `init`, `setUser`, `log`, `recordError`. |
| `analytics_navigator_observer.dart`| Screen tracking. | `NavigatorObserver` for Crashlytics breadcrumbs. |

### Specialized Services

| File | Purpose | Key Functions |
|------|---------|---------------|
| `payment_service.dart` | Razorpay integration. | `init`, `openCheckout`, `onSuccess/onFailure` callbacks. |
| `download_service.dart` | Secure per-user storage. | `downloadFileWithProgress`, `verifyOwnership`, `migrateOldDownloads`. |
| `offer_service.dart` | Promo code logic. | `fetchActiveSaleOffers`, `verifyCoupon`, `applyCouponToOrder`. |
| `pdf_service.dart` | Result PDF generation. | `generateExamResultPdf`, `_loadFont` (Gujarati support). |
| `translation_service.dart` | Automatic translations. | `translateQuestion`, `translateBatch` (Google Translate). |
| `review_service.dart` | Rating system. | `submitReview`, `getReviewsForItem`, `getBulkRatingStats`. |
| `banner_service.dart` | Home screen ads. | `fetchBanners`, `uploadBanner`, `deleteBanner`. |
| `secure_file_service.dart` | Sandboxed downloads. | `downloadSecurely`, `isFileDownloaded`. |
| Backend / DB | Supabase (PostgreSQL) |
| Auth | Supabase Auth + Google Sign-In |
| Payments | Razorpay Flutter (UPI-only) |
| Push Notifications | Firebase Cloud Messaging (FCM) |
| OTP | MSG91 via Supabase Edge Function (`/functions/v1/otp`) |
| FCM Edge Function | Supabase Edge Function (`/functions/v1/send-fcm`) |
| File Storage | Supabase Storage (buckets: `mock_test`, `resources`) |
| Environment | `flutter_dotenv` → `.env` file |
| Encryption | `encrypt` package (AES-256) for session IDs |
| Crash Reporting | Firebase Crashlytics (Global: Main + Providers + Auth) |
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
| `CrashlyticsService` (Util) | Global error catching, user tagging, screen breadcrumbs |

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
- **Direct JSON & Excel Upload**: Admins upload Excel (auto-converted) or `.json` (direct) → background upload to Supabase Storage via `BackgroundUploadService`.
- **JSON Export/Download**: Admins can download and share current questions JSON from edit/detail screens via `share_plus`.
- **Metadata Management**: Titles, categories, pricing, MRP.
- **Signed URL Generation**: Access tokens for premium content.
- **Cleanup**: Automatic deletion of JSON and Cover files from `mock_test` bucket on record removal.

### 2. Resource Management
- **Structured Storage**: All resources follow `Resources/[type]/[subfolder]` hierarchy.
  - `[type]` = `ebook`, `study_material`, `pyq`, `current_affair`.
  - `[subfolder]` = `file` (PDFs) or `cover` (Thumbnails).
- **Cleanup**: Automatic storage cleanup on resource deletion.
- **Edit Cleanup**: Old storage artifacts are automatically removed when replacing files during an edit.

### 3. Configuration Control (`app_config`)
- **Maintenance Mode**: Toggle global lock + custom message.
- **Feature Flags**: Enable/Disable reviews, change banner scroll speed.
- **Contact Info**: WhatsApp, Telegram, Support Email.
- **Legal**: Privacy Policy and Terms URLs.

### 3. Notification Hub
- **Broadcasts**: Push to all users via `admin_notification_service`.
- **Personal Alerts**: Push to specific user.
- **System-Wide Automation**:
  - **New Content**: Creating a `MockTest` or `Resource` triggers a broadcast to all users.
  - **Sales Hub**: Successful checkouts notify the `admin_updates` topic for real-time sale monitoring.
  - **Exclusions**: `OfferService` (coupons) does NOT trigger automated notifications.

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

## Pricing & Coupon Logic

### Price Calculator (`PriceCalculator`)
- **Real Sales**: `Final Price = Base Price - Discount`. The UI displays `mrp` as the strike-through price using the original `mrp` stored in the database.
- **Fake Sales (Marketing)**: `Final Price = Base Price`. The UI displays an inflated strike-through price (`database mrp + fake discount`).
- **Base MRP Rule**: The `PriceCalculator` now relies on the original database `mrp` (`baseMrp`) passed to it to strictly ensure visual strikethrough logic remains correct even if multiple discounts are checked.

### Mutual Exclusion
- **Store Sales vs Manual Coupons**: If an automatic store sale (Real or Fake) is actively applied to *any* item in the cart or checkout, the manual student discount/coupon code field is completely **disabled**. 
- Users are presented with a "Store sale discounts are already active" message.
- **Cart Logic**: `CartProvider` and `DirectCheckoutSheet` strictly enforce this lockout.
- **Implementation**: Handled in `PriceCalculator.isAnySaleActive` check within `CartProvider`.

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

### Resolved (2026-03-07 Audit)
- **Sustainability**: Fixed 400 errors from expiring Supabase URLs.
  - **Strategy**: Switched from storing temporary Signed URLs in DB to permanent Storage Paths.
  - **Logic**: Implemented `SupabaseUrlHelper` with 1-hour auto-refreshing cache and 5-min safety margin.
- **Performance**: N+1 Signed URL fetching storm. **Fixed**: Centralized signing in `SupabaseUrlHelper` with 1-hour cache.
- **Billing**: Excessive FCM database writes. **Fixed**: Throttled FCM token updates via `SharedPreferences`.
- **Reliability**: Google Translate rate-limiting. **Fixed**: Implemented chunked translation processing (5 items/batch).

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
| Phase 1 | Foundation — main.dart + AdminProvider + pubspec audit | ✅ Complete |
| Phase 2 | Core Routing — splash_screen + admin route | ✅ Complete |
| Phase 3 | Admin Screen Migration (16+ screens) | ✅ Complete |
| Phase 4 | Admin Service Migration | ✅ Complete |
| Phase 5 | Core/Widget Parity + db_error_helper | ✅ Complete |
| Phase 6 | End-to-End Testing | 🚧 In Progress |
| Phase 7 | Cleanup + Final CLAUDE.md Update | 🚧 In Progress |

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
9. **Phase 9**: Premium splash screen with progress bar. Login logo at `130x130`. Splash logo size increased for better branding.
10. **Global UI Resilience**: System navigation bar overlap audit and fix across all management screens.

### Historical Improvements (Audit & Recovery)
- **[2026-03-08]**: Accidental deletion of 24 core files during audit; fully restored via Git and verified with `flutter analyze`.
- **[2026-03-08]**: Fixed "Quiz & Tests" navigation in Admin Dashboard to correctly point to `AdminStoreScreen`.
- **[2026-03-08]**: Successfully migrated Mock Test JSON format to "tableConvert" structure.
- **[2026-03-08]**: Updated `Question` model to use string-based `correctAnswer` for better resilience and multi-language support.
- **[2026-03-08]**: Broad scoring logic update: All screens (`ExamScreen`, `TestAnalysisScreen`, `TestAttemptScreen`) now use trimmed, case-insensitive string matching.
- **[2026-03-08]**: Updated `PdfService` to use string-based correct answer identification in generated reports.
- **[2026-03-08]**: Enhanced `DownloadActionButton` UX: fixed RenderFlex overflow and enabled human-readable notification titles.
14. **Global Responsiveness Audit & Fixes (2026-03-08)**:
    - Conducted a full project audit for hardcoded pixel dimensions and layout overflows.
    - **Batched Implementation**: Migrated all 10 batches (55+ screens) to use `context.sp()`, `AppSpacing`, and `AppRadius` tokens.
    - **User App**: Fixed Home, Store, Cart, Checkout, Exam, Results, Analysis, and Profile screens.
    - **Admin Panel**: Fixed Dashboard, Analytics, User Management, Content Management, Orders, Notifications, and Profile screens.
    - **Edge-to-Edge Strategy**: Applied reactive `MediaQuery.padding.bottom` to all scrolling content for native gesture bar support.
    - **Constraint Enforcement**: Added `Flexible`/`Expanded` to all potentially overflowing Rows and `FittedBox` for dynamic currency displays.
15. **Post-Audit Stabilization (2026-03-08)**:
    - Unified responsiveness extensions into `lib/utils/responsive.dart` for centralized scaling.
    - Cleaned up 380+ analyze errors caused by missing imports and `const` keyword violations.
    - Updated `AppRadius` tokens to include `xs: 2.0` for checkbox and small component scaling.
    - Standardized `ResponsiveWrapper` to export `responsive.dart`, ensuring backward compatibility for legacy screens.
16. **Admin UI Global Stabilization**:
    - Resolved structural syntax errors in `AdminMainScreen` and `AdminUserDetailsScreen`.
    - Corrected broken relative import paths (`network_utils.dart`) across multiple management screens.
    - Standardized `NetworkErrorState` usage by migrating to the named `message` parameter.
    - Migrated 50+ instances of deprecated Material 3 members: `withOpacity()` → `.withValues(alpha: ...)`, `surfaceVariant` → `surfaceContainerHighest`, and `background` → `surface`.
15. **Mock Test JSON Format Migration (2026-03-08)**:
    - Migrated from flat JSON format to **tableConvert format** for better admin usability.
    - Updated `Question` model: Replaced `correctOptionIndex: int` with `correctAnswer: String`.
    - Implemented **String-Based Answer Matching**: Evaluation now uses trimmed, case-insensitive string comparison.
    - Updated `ExcelToJsonConverter` to output the new table-centric keys and string answers.
    - Refactored `ExamScreen`, `TestResultScreen`, `TestAnalysisScreen`, and `PdfService` to support string answer evaluation.
    - Enhanced `Question.fromJson` with strict validation to ensure the `Correct Answer` exists in the options list.

### Background Transfers & Notification Engine (Gemini Plan 2026-03-08)
1.  **Background Upload Service**: Singleton service (`BackgroundUploadService`) for Admin panel to handle file uploads as background futures, preventing UI lockup and providing progress callbacks.
2.  **Transfer Notification Service**: Unified local notification manager (`TransferNotificationService`) for both uploads (Admin) and downloads (User), displaying real-time progress bars and status updates.
3.  **Maximum-Duration Signed URLs**: Storage URLs are now created with a 1-year expiry (`31536000s`) to ensure long-term availability of shared/cached content.
4.  **Persistent URL Caching**: `SupabaseUrlHelper` utilizes both a 23-hour in-memory cache and a `SharedPreferences`-based persistent layer for signed URLs.
5.  **Chunked Background Downloads**: `DownloadService` supports background downloads using chunked HTTP requests, allowing for granular progress tracking and mid-stream cancellation.
6.  **Session-Aware Cancellation**: All active user downloads are automatically aborted and cleaned up during `AuthProvider.signOut()`, preventing orphaned files and unauthorized access during session switches.
7.  **Bulk URL Pre-signing**: `TestProvider` and `ResourceProvider` pre-fetch signed URLs for all list items in parallel after data fetching to eliminate user-perceived signing latency.

---

# File-by-File Reference


This section provides a detailed breakdown of every file in the project, intended for developers to understand the purpose, logic, and connectivity of each component.

## 1. Core Layer (`lib/core/`)

| File | Purpose | Key Functions/Components |
|------|---------|-------------------------|
| `theme/app_colors.dart` | Defines the global color palette. | `AppColors`: Primary, Secondary, Semantic (Success/Error), Gradients, Shadows. |
| `theme/app_theme.dart` | Main theme configuration. | `AppTheme`: `light`, `dark` - Combines colors, type, and radii into a `ThemeData`. |
| `theme/app_spacing.dart` | Defines the 8pt spacing system. | `AppSpacing`: `xs`, `sm`, `md`, `lg`, `xl` constants. |
| `theme/app_typography.dart` | Defines text styles and fonts. | `AppTypography`: `display`, `heading`, `bodyLabel`, `bodyLarge` using Google Fonts (Inter). |
| `theme/app_radius.dart` | Consistent corner radii. | `AppRadius`: `sm`, `md`, `lg`, `full`. |
| `theme/app_motion.dart` | Animation & transition tokens. | `AppMotion`: `short`, `normal`, `long` durations. |
| `utils/db_error_helper.dart` | Supabase error translation. | `DbErrorHelper.getMessage`: Converts `PostgrestException` codes into user-friendly strings. |

## 2. Domain Models (`lib/domain/models/`)

All models include `fromJson()` and `toJson()` methods for persistence.

| File | Purpose | Key Properties |
|------|---------|----------------|
| `app_config.dart` | App-wide settings. | `maintenanceMode`, `contactInfo`, `legalUrls`, `featureFlags`. |
| `home_banner.dart` | Carousel banner data. | `id`, `imageUrl`, `actionType` (external/route), `actionValue`. |
| `message.dart` | Support chat message. | `id`, `userId`, `message`, `isFromAdmin`, `createdAt`. |
| `mock_test.dart` | Practice exam metadata. | `id`, `title`, `price`, `mrp`, `category`, `language`, `questionsCount`. |
| `notification.dart` | FCM record for history. | `id`, `userId`, `title`, `message`, `type` (personal/broadcast). |
| `offer.dart` | Coupons and sales. | `id`, `code`, `discountValue`, `discountType`, `isActive`, `targetType`. |
| `order.dart` | Purchase record. | `orderId`, `userId`, `totalAmount`, `status` (PENDING/SUCCESS). |
| `order_item.dart` | Individual item in order. | `id`, `orderId`, `testId`, `resourceId`, `priceAtPurchase`. |
| `question.dart` | Exam question structure. | `text`, `options` (List), `correctAnswer` (String). | // CHANGED
| `resource.dart` | E-book/Material data. | `id`, `title`, `type` (ebook/study_material/etc), `fileUrl`, `thumbnailUrl`. |
| `review.dart` | User feedback/rating. | `id`, `userId`, `itemId`, `itemType`, `rating`, `reviewText`. |
| `test_result.dart` | Mock test attempt data. | `id`, `userId`, `testId`, `score`, `isPassed`, `attemptDate`. |
| `transaction.dart` | Payment gateway record. | `id`, `orderId`, `gatewayId`, `amount`, `status`. |
| `user.dart` | Profile and role data. | `id`, `email`, `username`, `role` (Admin/User), `language`. |

## 3. Services Layer (`lib/data/services/` & `lib/domain/services/`)

Services handle the heavy lifting: database calls via Supabase, external APIs, and local logic.

| File | Purpose | Key Functions/Components |
|------|---------|-------------------------|
| `admin_notification_service.dart` | Sending FCM pushes. | `sendBroadcastNotification`, `sendPersonalNotification`. |
| `admin_service.dart` | Admin-only DB operations. | `fetchDashboardStats`, `fetchUserList`, `updateUserRole`. |
| `app_config_service.dart` | Global config fetching. | `fetchConfig`, `getMaintenanceMode`, `getLegalUrls`. |
| `auth_service.dart` | Authentication logic. | `signInWithGoogle`, `signInWithEmail`, `signOut`, `getUserRole`. |
| `banner_service.dart` | Home screen ads. | `fetchBanners`, `uploadBanner`, `deleteBanner`. |
| `cart_service.dart` | Shopping cart persistence. | `fetchCartItems`, `addToCart`, `removeCartItem`. |
| `chat_service.dart` | Real-time support chat. | `fetchMessageStream`, `sendMessage`, `getAdminConversations`. |
| `download_service.dart` | Secure per-user storage. | `downloadFileWithProgress`, `verifyOwnership`, `migrateOldDownloads`. |
| `encryption_service.dart` | Security utilities. | `encryptData`, `decryptData` (used for session IDs). |
| `fcm_service.dart` | Push notification setup. | `initialize`, `onMessage.listen`, `_saveTokenToDatabase`. |
| `notification_service.dart` | Local & Stream listeners. | `initialize`, `connectUser`, `showLocalNotification`. |
| `offer_service.dart` | Promo code logic. | `fetchActiveSaleOffers`, `verifyCoupon`, `applyCouponToOrder`. |
| `otp_service.dart` | SMS OTP via MSG91. | `sendOtp`, `resendOtp`, `verifyOtp`. |
| `payment_service.dart` | Razorpay integration. | `init`, `openCheckout`, `onSuccess/onFailure` callbacks. |
| `resource_service.dart` | Resource management. | `fetchResources`, `fetchPurchasedResources`, `claimResource`. |
| `review_service.dart` | Rating system. | `submitReview`, `getReviewsForItem`, `getBulkRatingStats`. |
| `secure_file_service.dart` | Sandboxed downloads. | `downloadSecurely`, `isFileDownloaded`. |
| `test_service.dart` | Mock test lifecycle. | `fetchMockTests`, `submitTestResult`, `checkout`. |
| `translation_service.dart` | Automatic translations. | `translateQuestion`, `translateBatch` (Google Translate). |
| `pdf_service.dart` | Result PDF generation. | `generateExamResultPdf`, `_loadFont` (Gujarati support). |

## 4. State Management (`lib/presentation/providers/`)

Providers manage the application state and provide a reactive bridge between Services and the UI.

| File | Purpose | Key Responsibilities |
|------|---------|-----------------------|
| `admin_provider.dart` | Minimal state for Admin panel. | Manages `navIndex` and `refreshCounter`. Note: Most admin data uses Streams. |
| `auth_provider.dart` | Core authentication state. | `currentUser`, `userRole`, `isLoggedIn`, session monitoring, Google Sign-In flow. |
| `cart_provider.dart` | User's shopping cart state. | `cartItems`, `cartCount`, `addToCart`, `removeFromCart`, signs URLs for cart items. |
| `navigation_provider.dart` | User app navigation state. | `selectedIndex` (bottom nav), `selectedStoreCategory` for filtering. |
| `network_provider.dart` | Global connectivity monitor. | Singleton that tracks `isConnected` status via `connectivity_plus`. |
| `offer_provider.dart` | Active offers management. | Fetches and caches `activeOffers` for the store. |
| `resource_provider.dart` | Resource state management. | Manages lists for `ebooks`, `studyMaterials`, etc., and user's `purchasedResources`. |
| `test_provider.dart` | Mock test state management. | Fetches all tests, filters/sorts by category/price, tracks `purchasedTestIds`. |
```
## 5. User Presentation Layer (`lib/presentation/screens/`)

The User App screens provide the primary educational experience. They utilize `Provider` for reactive state and various services for core library management.

### App Lifecycle & Auth

| File | Purpose | Key Components | Data Flow |
|------|---------|----------------|-----------|
| `splash_screen.dart` | Initializes the app. | `SplashScreen`: Progress bar, update & auth checks. | Routes to `LoginScreen`, `MainScreen`, or `AdminMainScreen`. |
| `login_screen.dart` | User authentication. | `LoginScreen`: Google Sign-In, Terms agreement. | Updates `AuthProvider.currentUser` upon success. |
| `main_screen.dart` | Primary user navigation. | `MainScreen`: Bottom navigation bar controller. | Switches between Home, Store, Library, and Profile. |

### Discovery & Store

| File | Purpose | Key Components | Data Flow |
|------|---------|----------------|-----------|
| `home_screen.dart` | User dashboard. | `BannerCarousel`, `FeaturedTestsGrid`. | Fetches banners and user profile via `BannerService` & `AuthService`. |
| `store_screen.dart` | Marketplace for content. | `StoreScreen`: Tabbed Categories, Item search. | Streams tests/resources from `TestProvider` & `ResourceProvider`. |
| `mock_test_detail_screen.dart` | Test purchase page. | Purchase buttons, Ratings summary. | Initiates purchase via `CartProvider` or direct checkout. |
| `resource_detail_screen.dart` | PDF resource page. | "Claim Free" / Buy buttons, Sample preview. | Handles resource acquisition via `ResourceService`. |
| `free_content_screen.dart` | Curated freebies list. | `FreeItemCard`, Category filters. | Pulls free items from tests and resources with "Claim" logic. |

### Learning & Examination

| File | Purpose | Key Components | Data Flow |
|------|---------|----------------|-----------|
| `exam_screen.dart` | Practice test engine. | `ExamScreen`: Timer, Nav Lock, Question cards. | Loads local JSON via `DownloadService` or signs Supabase URLs. |
| `test_result_screen.dart` | Score summary. | Score animator, Pass/Fail badge, PDF Gen. | Submits performance via `TestService` and generates PDF via `PdfService`. |
| `test_analysis_screen.dart` | Q&A post-test review. | `AnalysisCard`: Correct vs User answers. | Provides itemized review with optional Gujarati translation. |
| `score_screen.dart` | User's test history. | `ScoreScreen`: Staggered list of past attempts. | Fetches persistence from `test_results` table via `TestService`. |
| `pdf_viewer_screen.dart` | Document reader. | `PdfViewerScreen`: Night mode, Zoom, Nav. | Views secure local files or temporary network streams. |

### Commerce & Library

| File | Purpose | Key Components | Data Flow |
|------|---------|----------------|-----------|
| `cart_screen.dart` | Shopping cart. | `CartScreen`: Coupon field, Subtotal summary. | Managed by `CartProvider` and `OfferProvider`. |
| `checkout_screen.dart` | Payment summary. | `CheckoutScreen`: Simple price breakdown. | Initiates `PaymentService` (Razorpay) for final payment. |
| `my_library_screen.dart` | Purchased content home. | Tabs for Tests and Resources. | Switches between library sub-screens. |
| `purchased_tests_screen.dart` | Owned mock tests list. | Download/Start primary actions. | Filters `TestProvider.allTests` for purchased items. |
| `my_resources_screen.dart` | Owned PDF library. | Category-based PDF list. | Pulls user items from `ResourceProvider`. |
| `downloads_screen.dart` | Offline file manager. | Storage bar, Clean up, Selection mode. | Interacts directly with `DownloadService` file system. |

### Account & Support

| File | Purpose | Key Components | Data Flow |
|------|---------|----------------|-----------|
| `profile_screen.dart` | Profile & Settings. | Language toggle, Support chat, Logout. | Reads from `AuthProvider` and `AuthService.streamUserProfile`. |
| `edit_profile_screen.dart` | Profile editor. | Name, Phone, Language forms. | Updates `users` table via `AuthService.updateProfile`. |
| `notifications_screen.dart` | User notification log. | Dismissible alerts list. | Streams from `notifications` table via `NotificationService`. |
| `chat_screen.dart` | Help desk UI. | `Chat`: Real-time message thread. | Uses `ChatService` and `flutter_chat_ui` for support. |

## 6. Admin Presentation Layer (`lib/presentation/screens/admin/`)

The Admin Panel screens provide management interfaces for administrators. They heavily utilize `StreamBuilder` for real-time data and `AdminService` for backend mutations.

### Core Layout & Dashboard

| File | Purpose | Key Components | Data Flow |
|------|---------|----------------|-----------|
| `admin_main_screen.dart` | The root layout for admins. | `AdminMainScreen`: Responsive sidebar/rail/bottom nav. | Switches between 5 main tabs based on `AdminProvider.navIndex`. |
| `admin_home_screen.dart` | Primary dashboard view. | `_StatCard`, `StreamBuilder` for Top Tests/Users. | Streams dashboard metrics and top performance lists from `AdminService`. |
| `admin_analysis_screen.dart` | Visual analytics and stats. | `AdminAnalysisScreen`: Revenue and content charts. | Pulls aggregated stats via `AdminService.streamDashboardStats()`. |
| `revenue_details_screen.dart` | Transaction audit log. | `RevenueDetailsScreen`: Filterable order list. | Fetches full order details including user/item joins via `AdminService`. |

### User Management

| File | Purpose | Key Components | Data Flow |
|------|---------|----------------|-----------|
| `admin_user_list_screen.dart` | Global user directory. | `AdminUserListScreen`: Searchable user table. | Fetches all user profiles from `AdminService`. |
| `admin_user_details_screen.dart` | In-depth user profile. | `AdminUserDetailsScreen`: Orders, attempts, role management. | Pulls user specific orders and test results. Can promote/demote via `AdminService`. |
| `admin_notification_screen.dart` | Push notification center. | `AdminNotificationScreen`: Broadcast form. | Sends requests to `AdminNotificationService` for bulk/personal pushes. |

### Content & App Management

| File | Purpose | Key Components | Data Flow |
|------|---------|----------------|-----------|
| `manage_app/manage_app_screen.dart` | Tabbed config center. | `ManageAppScreen`: Features/Banners/Content tabs. | Distributes sub-management to specialized tabs. |
| `manage_app/tabs/feature_control_tab.dart` | App status & flags. | Maintenance mode toggle, version control. | Saves global flags to `app_config` via `AppConfigService`. |
| `manage_app/tabs/banner_management_tab.dart` | Ad banner carousel. | Image picker, priority/active management. | Uploads/deletes via `BannerService` and `Supabase Storage`. |
| `manage_app/tabs/content_management_tab.dart` | Legal & Support contact. | Contact info, legal URL fields. | Persists structured JSON to `app_config` via `AppConfigService`. |

### Store & Inventory Management

| File | Purpose | Key Components | Data Flow |
|------|---------|----------------|-----------|
| `admin_offer_list_screen.dart` | Coupons & Sales list. | `AdminOfferListScreen`: Bulk deactivate, filtering. | Streams all offers from `OfferService`. |
| `admin_offer_manage_screen.dart` | Create/Edit offer form. | `AdminOfferManageScreen`: Advanced targeting. | Validates and saves `Offer` objects via `OfferService`. |
| `resources/admin_resources_dashboard.dart` | Resource menu. | `CategoryCard`: E-books, PYQs, GK, etc. | Aggregates count stats via `AdminService.getResourceTypeStats`. |
| `resources/admin_resource_list.dart` | Specific resource list. | `AdminResourceList`: PDF/Cover previews. | Fetches resources by type from `ResourceService`. |
| `resources/admin_resource_form.dart` | Resource editor. | `AdminResourceForm`: Path logic (`Resources/[type]`). | Uploads files to storage and creates DB records via `ResourceService`. |
| `resources/admin_mock_test_list.dart` | Mock test catalog. | `AdminMockTestList`: Filterable test list. | Streams tests from `TestService`. |
| `resources/admin_mock_test_detail_screen.dart`| Test insights. | `AdminMockTestDetailScreen`: Performance charts. | Fetches item-specific sales stats via `AdminService.getMockTestItemStats`. |

## 8. Entry Point & Global Wrappers (`lib/main.dart`)

The app entry point manages critical initialization and global UI interceptors.

| Component | Responsibility |
|-----------|----------------|
| `main()` | Bootstraps the app: `PlatformDispatcher` (Crashlytics), Supabase/Firebase init, `.env` loading, `runZonedGuarded` fallback. |
| `MultiProvider` | Injects all 7+ providers into the widget tree. |
| `MyApp` | Configures `MaterialApp`, global `navigatorKey`, and `ThemeMode.system`. |
| `NetworkAwareWrapper`| A global builder that monitors `NetworkProvider` and prevents navigation to online-only screens when offline. |
| `ResponsiveWrapper` | Ensures consistent scaling (using `Responsive` util) across different screen sizes. |

## 9. Global Utilities (`lib/utils/`)

Helper classes shared across services and presentation layers.

| File | Purpose | Key Logic |
|------|---------|-----------|
| `price_calculator.dart` | The brain of the store's pricing. | `calculateDisplayPrice`: Compares "Real" vs "Fake" offers to show the best perceived discount. |
| `network_utils.dart` | Error signature handling. | `isNetworkError`: Identifies `SocketException`, timeouts, and DNS failures. |
| `excel_to_json_converter.dart`| Mock test file parser. | Converts uploaded Excel bytes into **tableConvert** structured `Question` JSON with string answers. | // CHANGED
| `retry_helper.dart` | Resilience utility. | Provides `retry()` logic with exponential backoff for flaky API calls. |
| `responsive.dart` | Screen scaling engine. | Extension methods on `BuildContext` for relative sizing. |
| `navigator_key.dart` | Global context access. | Provides `navigatorKey` for navigation without `BuildContext`. |

---

## 🏗 Mock Test System (Deep Dive)

### 1. File Ingestion & Format
- **Admin Upload**: Admins upload Excel (`.xlsx`) or JSON (`.json`) in `MockTestUploadScreen`.
- **Parsing (`ExcelToJsonConverter`)**:
  - **Column 0**: ID (Question Number). // CHANGED
  - **Column 1**: Question Text. // CHANGED
  - **Columns 2+**: Options (mapped to `Option A`, `Option B`, etc.). // CHANGED
  - **Correct Answer Detection**: The very last non-empty cell in the row is treated as the key. // CHANGED
- **Format (tableConvert)**: // CHANGED
  ```json
  [{"No.":1, "Question":"Question?", "Option A":"A", "Option B":"B", "Correct Answer":"B"}]
  ```
- **Conversion**: Excel bytes → `List<Question>` format → JSON String → Supabase Storage (`mock_test` bucket).

### 2. MCQ Engine (`ExamScreen`)
- **Loading**: Prefers local sandboxed JSON (from `DownloadService`) for offline stability.
- **Answer Matching**: Uses trimmed, case-insensitive string comparison between the user's selected option and `question.correctAnswer`. // CHANGED
- **Gujarati Translation**: Uses `TranslationService` with **Smart Buffering** (current + next 5 questions) which maps the `correctAnswer` string to its translated counterpart by index. // CHANGED
- **Nav Lock**: Navigation is restricted to `currentQuestionIndex + 10` to prevent users from skipping large portions of the test.

### 3. Scoring & Negative Marking
- **Base Mark**: `MarksPerQ = totalMarks / totalQuestions`.
- **Positive Score**: `correctCount * MarksPerQ`.
- **Negative Penalty**: `if (test.negative_marking)` → `penalty = wrongCount * negativeMarksPerQ`.
- **Final Score**: `(Positive - Penalty)`, clamped to a minimum of **0**.
- **Persistence**: Results are saved to `test_results` table including score, counts, and language meta for PDF regeneration.
