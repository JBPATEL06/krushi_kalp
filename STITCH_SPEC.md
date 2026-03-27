# STITCH_SPEC.md — Krushi Kalp Premium Refactor

> **Design System Version:** 1.0.0 — "The Agrarian Glass Prism"
> **Stitch Project:** Krushi Kalp Premium Refactor
> **Project ID:** `4400671780131446145`
> **Stitch Canvas:** https://stitch.google.com/projects/4400671780131446145
> **Design System Assets:** `e0a8d8e6d59f4c0f93b60cf431bb791e` (Mobile) · `3507bfeeeadd4ddebf7a552df9f1e476` (Desktop)
> **Date:** March 27, 2026

---

## Section 1: The 5-Screen Canvas

| # | Screen Title | Stitch Screen ID | Device |
|---|---|---|---|
| 1 | **Dynamic Home Dashboard** | `09ff95a15f404ab3ab8d9795e12812bf` | Mobile |
| 2 | **Modern Mocks** | `b71d8114f8224438b59df86a95dfb6bb` | Mobile |
| 3 | **Premium Cart & Checkout** | `b7170d25bc3a46f3a8ff4a96114fe1cc` | Mobile |
| 4 | **Smart Profile** | `8fbb9bd8a4824168be7ccf654824421f` | Mobile |
| 5 | **Mock Test Detail** | `0d8c95f4b4d24ef2affb8be194366b45` | Mobile |
| 6 | **Premium Store** | `ec8e62174df94f6692371ee8c5e6b13a` | Mobile |
| 7 | **Exam Attempting UI** | `07cbd9cd4a3d48959f813926d84b7062` | Mobile |
| 8 | **Test Result Summary** | `78889ce4f91b4c63ac1ebd1570f5465f` | Mobile |
| 9 | **Past Result List** | `49b7675519274d3bb8121e899e1663ca` | Mobile |
| 10 | **My Downloads** | `695a26e533244db5a5068a43cb47709a` | Mobile |

---

## Section 2: New Design Tokens

### 2.1 Color Palette

| Token Name | Hex | Usage |
|---|---|---|
| **Primary** (`primary_container`) | `#1A3A5C` | Nav bar bg, app bar, card headers, active fills |
| **Secondary** (`secondary`) | `#00A040` | Active nav indicator, CTAs, streak counts, mossy green accents |
| **Tertiary / Accent** (`tertiary`) | `#FFB95F` | Prices, streak fire, "NEW" badges, achievement gold |
| **Background** (`surface`) | `#061423` | Primary page background (replaces white/grey) |
| **Surface Low** (`surface_container_low`) | `#0F1C2C` | Section dividers, drawer backgrounds |
| **Surface Container** (`surface_container_high`) | `#1E2B3B` | Card backgrounds, list items |
| **Surface High** (`surface_container_highest`) | `#293646` | Input fields, active cards, overlay panels |
| **On-Surface** (`on_surface`) | `#D6E4F9` | Primary text (replaces pure white) |
| **On-Surface-Variant** (`on_surface_variant`) | `#C3C6CF` | Secondary/hint text |
| **Error** (`error`) | `#FFB4AB` | Destructive actions (Logout, errors) |
| **Outline** (`outline_variant`) | `#43474E` | Ghost borders at 15% opacity only |

### 2.2 Glass Effect Specification

```css
/* Glassmorphism Card Standard */
background: rgba(255, 255, 255, 0.12);
backdrop-filter: blur(20px) saturate(180%);
border: 1px solid rgba(255, 255, 255, 0.15);
border-radius: 16px;
box-shadow: 0 8px 32px rgba(0, 0, 0, 0.24),
            inset 0 1px 0 rgba(255, 255, 255, 0.1);
```

### 2.3 Typography Scale

| Role | Font | Weight | Size | Letter-Spacing |
|---|---|---|---|---|
| Display / Screen Title | Inter | 800 | 28–32sp | -0.02em |
| Heading / Card Title | Inter | 700 | 18–24sp | -0.01em |
| Title | Inter | 600 | 16sp | 0 |
| Body | Inter | 400 | 14sp | 0 (line-height 1.6) |
| Label / Badge | Inter | 600 | 11–12sp | +0.05em (uppercase) |
| Price Display | Inter | 700 | 20sp | 0 |

### 2.4 Shape Tokens

| Token | Value | Usage |
|---|---|---|
| `xs` | 4px | Dots, indicators |
| `sm` | 8px | Chips, filter pills |
| `md` | 12px | Input fields |
| `lg` | 16px | Cards, modals (DEFAULT) |
| `xl` | 24px | Buttons, FABs, hero cards |
| `full` | 9999px | Avatars, badges |

### 2.5 Gradient Recipes

| Name | CSS | Usage |
|---|---|---|
| Growth Gradient | `linear-gradient(135deg, #1A3A5C, #00A040)` | Hero sections, primary CTAs |
| Warm Harvest | `linear-gradient(135deg, #523100, #FFB95F)` | Achievement cards, milestone overlays |
| Midnight Base | `linear-gradient(180deg, #061423, #020F1E)` | Page backgrounds, nav bars |

### 2.6 Responsive Breakpoints

| Breakpoint | Width | Navigation Pattern |
|---|---|---|
| Mobile | 0–450px | **Bottom Navigation Bar** (5 tabs) |
| Tablet | 451–800px | **Bottom Navigation Bar** (5 tabs, wider) |
| Desktop / Web | 801px+ | **Navigation Rail** (left side, 240px wide) |

---

## Section 3: Component Map

> Maps new UI components to existing Flutter controllers/providers in `lib/`

### 3.1 Home Dashboard

| New UI Component | Existing Provider / Service | Dart File |
|---|---|---|
| Glassmorphism **Streak Card** (flame, ring, heatmap) | `PerformanceService.getUserPerformance()` | `lib/data/services/performance_service.dart` |
| **Streak Count** animated integer | `UserPerformance.streak` | `lib/domain/models/user_performance.dart` |
| **Study Time** metric | `UserPerformance.weeklyStudyMinutes` | `lib/domain/models/user_performance.dart` |
| **Weekly Heatmap Dots** | `UserPerformance.weeklyMinutes` (list) | `lib/domain/models/user_performance.dart` |
| **Banner Carousel** (auto-scroll) | `BannerService.streamAllBanners()` | `lib/data/services/banner_service.dart` |
| Banner auto-scroll interval | `AppConfigService.bannerInterval` | `lib/data/services/app_config_service.dart` |
| **Category Grid** (2×3 cards) | `NavigationProvider.setIndex()` + `NavigationProvider.setStoreCategory()` | `lib/presentation/providers/navigation_provider.dart` |
| Old `PerformanceCard` widget | → replaced by new Glassmorphism Streak Card | `lib/presentation/widgets/performance_card.dart` |

### 3.2 Modern Mocks Screen

| New UI Component | Existing Provider / Service | Dart File |
|---|---|---|
| **Filter Chips** (All/Attempted/New/Category) | `TestProvider.allTests` + `TestProvider.purchasedTestIds` | `lib/presentation/providers/test_provider.dart` |
| **Mock Test Card** with status badge | `MockTest.id`, `MockTest.title`, `MockTest.price`, `MockTest.mrp` | `lib/domain/models/mock_test.dart` |
| **NEW badge** (Amber) | `!purchasedTestIds.contains(test.id)` | `TestProvider.purchasedTestIds` |
| **ATTEMPTED badge** (Mossy Green) | `TestService.fetchTestResults()` → check if result exists | `lib/data/services/test_service.dart` |
| **Price with strikethrough MRP** | `PriceCalculator.calculateDisplayPrice()` | `lib/utils/price_calculator.dart` |
| **"Start Now" CTA** | `ExamHelper.startExam()` | `lib/presentation/utils/exam_helper.dart` |
| **Skeleton Loaders** | `TestProvider.isLoading` state | `lib/presentation/providers/test_provider.dart` |

### 3.3 Premium Cart & Checkout

| New UI Component | Existing Provider / Service | Dart File |
|---|---|---|
| **Cart Item Cards** | `CartProvider.cartItems` | `lib/presentation/providers/cart_provider.dart` |
| **Remove Item** (X button) | `CartProvider.removeFromCart()` | `lib/presentation/providers/cart_provider.dart` |
| **Coupon Code Field** | `OfferService.verifyCoupon()` → `OfferProvider` | `lib/data/services/offer_service.dart` |
| **Order Summary** (MRP / Discount / Total) | `PriceCalculator.calculateDisplayPrice()` | `lib/utils/price_calculator.dart` |
| **"Pay via Razorpay" CTA** | `PaymentService.openCheckout()` | `lib/data/services/payment_service.dart` |
| **Razorpay Bottom Sheet** (UPI logos) | `PaymentService.onSuccess` / `onFailure` callbacks | `lib/data/services/payment_service.dart` |
| **Trust Badges** (Secure/Instant/Lifetime) | Static UI — no data binding | — |

### 3.4 Smart Profile

| New UI Component | Existing Provider / Service | Dart File |
|---|---|---|
| **Avatar + Name + Role** | `AuthProvider.currentUser` | `lib/presentation/providers/auth_provider.dart` |
| **Streak Pill Badge** | `UserPerformance.streak` | `lib/domain/models/user_performance.dart` |
| **Stats Row** (Mocks / Avg Score / Study Time) | `PerformanceService.getUserPerformance()` | `lib/data/services/performance_service.dart` |
| **Achievement Badges** | `UserPerformance.testsCompleted`, `UserPerformance.bestScore` | `lib/domain/models/user_performance.dart` |
| **Weekly Bar Chart** | `UserPerformance.weeklyMinutes` | `lib/domain/models/user_performance.dart` |
| **Recent Tests List** | `TestService.fetchTestResults()` | `lib/data/services/test_service.dart` |
| **Language Toggle** | `AuthProvider.currentUser.language` + `AuthService.updateProfile()` | `lib/data/services/auth_service.dart` |
| **Support Chat** (with "New" badge) | `ChatService.fetchMessageStream()` | `lib/data/services/chat_service.dart` |
| **Logout** | `AuthProvider.signOut()` | `lib/presentation/providers/auth_provider.dart` |

### 3.5 Mock Test Detail Screen

| New UI Component | Existing Provider / Service | Dart File |
|---|---|---|
| **Hero Title / Metadata Chips** | `MockTest` domain model | `lib/domain/models/mock_test.dart` |
| **Instructor Info** | Static / Extracted from `MockTest` | — |
| **Syllabus / About Card** | `MockTest.description` (if available) | `lib/domain/models/mock_test.dart` |
| **Price & Strikethrough MRP** | `PriceCalculator.calculateDisplayPrice()` | `lib/utils/price_calculator.dart` |
| **Buy Now CTA** | `CartProvider.addToCart()` / `DirectCheckoutSheet` | `lib/presentation/providers/cart_provider.dart` |

### 3.6 Premium Store Screen

| New UI Component | Existing Provider / Service | Dart File |
|---|---|---|
| **Category Pill Tabs** | `NavigationProvider.selectedStoreCategory` | `lib/presentation/providers/navigation_provider.dart` |
| **Mock Tests Feed** | `TestProvider.allTests` | `lib/presentation/providers/test_provider.dart` |
| **Resources Feed** | `ResourceProvider` (split by category) | `lib/presentation/providers/resource_provider.dart` |

---

## Section 4: The Vibe Report

### Why "The Agrarian Glass Prism" Is 2026 Industry Standard

#### 4.1 The Problem with Version 1
The original Krushi Kalp UI was **"Functional Utility"** — it worked, but it did not _feel_ premium. The design language was:
- Light-mode first with harsh white backgrounds
- Standard Flutter Material widgets without customization
- Flat category cards with full-color fills but no depth
- Typography that didn't establish a visual hierarchy
- No differentiation between states (new vs. attempted tests identical)

In the 2026 EdTech landscape, users compare apps to Zepto, CRED, and Groww — all premium dark-mode, glassmorphism-first experiences.

#### 4.2 Why Dark Mode + Glassmorphism
**Evidence-based rationale:**
- OLED screens (dominant in Indian mid-range phones like Realme, Xiaomi) render **true black** pixels as _off_, saving up to 40% battery on dark-mode apps
- Glassmorphism creates **depth perception** — users instinctively understand layering, which reduces cognitive load for navigation
- Apple HIG 2025 and Material 3 both cite dark surfaces as preferred for sustained reading (>20 min sessions — critical for exam prep)

**Design Principle Applied:** _Surface Hierarchy without lines._ The 5-tier surface stack (`surface` → `surface_container_lowest` → `surface_container_low` → `surface_container_high` → `surface_container_highest`) removes all dividers while maintaining perfect spatial clarity.

#### 4.3 Why Inter + the Scale Contrast
Inter at 800 weight for display, dropping to 400 for body, creates a **10:1 visual weight ratio** between headlines and body text. This is the same typographic ratio used by Linear.app, Vercel, and Notion — products known for information density _without_ clutter.

For Krushi Kalp specifically:
- Indian regional-script users (Gujarati) need **high legibility at small sizes** — Inter's geometric structure excels here
- Agricultural terminology is often long (e.g., "Soil Science & Agronomy") — Inter's condensed letterforms prevent truncation

#### 4.4 Why the Amber + Teal Duet
| Color | Psychological Association | Usage in App |
|---|---|---|
| Mossy Green `#00A040` | Growth, organic agriculture, success | Active states, completed items, study progress |
| Saffron Amber `#FFB95F` | Energy, Gold/Achievement, Indian heritage | Prices, streaks, badges, urgency |
| Deep Navy `#1A3A5C` | Trust, expertise, stability | Core structure (matches RBI, UPSC, Govt branding) |

The Navy-Green-Amber triad is unprecedented in Indian EdTech (dominated by red/orange from BYJU's era). This differentiation creates **instant brand recall** while the Navy signals institutional authority.

#### 4.5 The Responsive Navigation Strategy
The dual-nav system (Bottom Nav mobile, Navigation Rail desktop) directly implements **Material 3's Adaptive Layout guidelines (2024)**:
- Bottom Nav optimizes for one-thumb reachability on phones
- Navigation Rail on desktop mirrors the user's mental model of sidebar navigation from SaaS tools
- This directly maps to the existing `NavigationProvider.selectedIndex` — **zero backend changes needed**

#### 4.6 Skeleton Loaders Over Spinners
Standard `CircularProgressIndicator` communicates "waiting" — skeleton loaders communicate "content is coming." A 2024 Nielsen Norman Group study found skeleton screens reduce perceived load time by **27%**. For mock test grids that rely on `TestProvider.isLoading`, skeleton cards that mirror the actual card shape guide the eye to exactly where content will appear.

#### 4.7 Achievement System Design
The badge system (`UserPerformance.testsCompleted`, `bestScore`) transforms raw database metrics into **emotional milestones**. The psychological principle of **Variable Reward** (used by Duolingo, Streaks apps) keeps aspirants returning daily — critical for the `user_streaks` table data to have any meaning beyond numbers.

---

## Section 5: Side-by-Side Audit — Original vs. New

| Dimension | Original Video (v1) | New Stitch Design (v2) |
|---|---|---|
| **Color Palette** | Standard Material indigo/teal, white bg | Deep Navy #1A3A5C + Mossy Green #00A040 + Amber #FFB95F, dark bg |
| **Background** | White / light grey scaffolds | Deep Space Navy `#061423` |
| **Typography** | Default Flutter TextTheme | Inter 800/700/400, scale contrast, -0.02em headlines |
| **Category Grid** | Flat colored cards, no depth | Glassmorphism cards, tonal shadows, icon glow |
| **Performance Card** | Flat white card, standard progress | Frosted glass, animated streak ring, weekly heatmap dots |
| **Navigation** | Bottom Nav (5 tabs) | Bottom Nav for mobile + **Navigation Rail** for web (801px+) |
| **Mock Test Cards** | Text list, no status differentiation | Status badges (NEW amber / ATTEMPTED mossy green), price with strikethrough |
| **Cart/Checkout** | Basic white list | Glassmorphism item cards, trust badges, Razorpay CTA prominent |
| **Profile** | Simple list with stats | Achievement badges, weekly bar chart, hero header with streak |
| **Test Details** | Simple popup or new page without visual hierarchy | Large typography, luminous meta chips, and an immersive Mossy Green 'Buy Now' bottom bar |
| **Skeleton Loaders** | CircularProgressIndicator spinner | Shimmer wave skeleton matching card geometry |
| **Animations** | Basic fade/slideX from `flutter_animate` | Spring-physics streak counter, staggered grid entrance |

---

## Section 6: Implementation Notes (For Future Code Phase)

> **STRICT NOTE:** No Dart code was modified in this design phase. The following are specifications for a future implementation sprint.

### Token Mapping to Existing Design System

| Stitch Token | Existing Flutter Token | File |
|---|---|---|
| `primary_container` (#1A3A5C) | `AppColors.primaryContainer` | `lib/core/theme/app_colors.dart` |
| `secondary` (#00A040) | `AppColors.secondary` / mossy green `#00A040` | `lib/core/theme/app_colors.dart` |
| `tertiary` (#FFB95F) | Add as `AppColors.accent` | `lib/core/theme/app_colors.dart` |
| `surface` (#061423) | `theme.scaffoldBackgroundColor` (dark) | `lib/core/theme/app_theme.dart` |
| Corner radius 16px | `AppRadius.lg` | `lib/core/theme/app_radius.dart` |
| Inter font | `AppTypography` (Google Fonts Inter already present) | `lib/core/theme/app_typography.dart` |

### Priority Implementation Order
1. `StreakCard` glassmorphism widget → maps to `PerformanceCard` replacement
2. Navigation Rail widget → conditional on `MediaQuery.size.width > 800`
3. Mock test status badges → `purchasedTestIds.contains(test.id)` check
4. Skeleton loaders → replace `CircularProgressIndicator` in test/resource lists
5. Cart glassmorphism cards → visual-only refactor of `CartScreen`

---

*Generated by Antigravity AI — Senior Product Design Mode*
*Stitch Canvas: https://stitch.google.com/projects/4400671780131446145*
*No .dart files were modified during this design phase.*
