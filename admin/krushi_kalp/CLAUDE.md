# Krushi Kalp Admin — Project Context

## What Is This
The **Admin Dashboard** for the Krushi Kalp ecosystem. While the User App is for consumers (students), this app is for the content managers and administrators. It shares the same **Supabase** backend and **Firebase** infrastructure.

### Parallel Operation logic
The Admin and User projects operate as two sides of the same coin:
- **Shared Database**: Both apps connect to the same PostgreSQL tables (e.g., `mock_tests`, `resources`, `users`, `app_config`).
- **Real-time Sync**: Changes made in Admin (like updating a price or enabling maintenance mode) reflect instantly in the User app via Supabase Realtime and `AppConfigService`.
- **Content Management**: Admin uploads JSON/Images to Storage buckets (`mock_test`, `resources`), which the User app then downloads and renders.
- **Support System**: Admin responds to user messages in the `ChatService`, creating a bidirectional communication loop.

---

## Admin-Specific Capabilities

### 1. Mock Test Engine
- **Excel Upload**: Admins can upload an Excel file which is converted to JSON locally before being pushed to Supabase Storage.
- **Metadata Management**: Controlling test titles, categories, pricing, and MRP.
- **Signed URL Generation**: Managing the access tokens for premium content.

### 2. Configuration Control (`app_config`)
Admins have a dedicated UI to manage the `AppConfigService` flags used by the User app:
- **Maintenance Mode**: Toggle the global lock and custom message.
- **Feature Flags**: Enable/Disable reviews, change banner scroll speeds.
- **Contact Info**: Update WhatsApp, Telegram, and Support Email strings globally.
- **Legal**: Update Privacy Policy and Terms URLs without a new app release.

### 3. Notification Hub
- **Broadcasts**: Send push notifications to all users simultaneously.
- **Personal Alerts**: Send specific alerts to individual users.
- **System Integration**: Automated notifications for new test additions or sales.

### 4. User & Transaction Monitoring
- **User Records**: View profile details, roles, and support history.
- **Transactions**: Monitor Razorpay SUCCESS/COMPLETED orders and order items.

---

## Tech Stack (Mirroring User Project)
| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| State Management | Provider |
| Backend | Supabase |
| Communication | Firebase CM (Admin-side sending) |
| Excel Logic | `excel` package + custom JSON converters |

---

## Architecture (Differences from User App)
```
lib/
├── presentation/
│   ├── screens/
│   │   ├── admin_home_screen.dart       # Dashboard stats
│   │   ├── mock_test_upload_screen.dart # Excel-to-JSON engine
│   │   ├── config_management_screen.dart# AppConfig editor
│   │   └── broadcast_screen.dart        # FCM dispatcher
```

1. **Phase 1: Admin Theme Sync (Core Tokens):** Synchronized core design tokens (`premium_palettes`, `app_spacing`, `app_radius`, `app_motion`) from User project. Configured `main.dart` for `ThemeMode.system` with full `lightTheme`/`darkTheme` support.
2. **Phase 2: Common Widget Refinement:** Applied premium theme tokens to all common widgets (`AppButton`, `AppCard`, `CustomTextField`, `UniversalItemCard`, `GlassContainer`). Synced `AppTypography` and `AppColors` for cross-project visual parity.
3. **Phase 3: Screen Migration & Final Polish:** Successfully migrated all high-traffic Admin screens (`HomeScreen`, `ProfileScreen`, `ManageApp` tabs). Refactored `ui_helpers.dart` for consistent dialogs and form cards. Validated 8-point grid and dark mode across all migrated components.
4. **Phase 4: Global Theme Enforcement:** Conducted a comprehensive sweep of the entire project. Standardized relative imports to package identifiers, resolved all build-time lint errors, and ensured 100% theme token compliance across every administrative screen and widget.
5. **Phase 5: Professional Google-Level UI Overhaul:** Successfully implemented Sidebar Navigation + Top App Bar architecture. Refactored high-traffic management screens (Revenue, Offers, Reviews, Notifications) into a standardized, row-based Material 3 aesthetic. Enforced strict 8dp grid compliance and premium typography tokens across all dashboard components.
6. **Phase 6: Transaction Details & Theme Compliance:** Implemented `fetchOrderById` for on-demand rich joins. Added interactive transaction detail popups with full visibility into items, users, and offers. Resolved `RenderShrinkWrappingViewport` dialog constraints and enforced 100% theme token compliance across Login, Chat, and Revenue screens for perfect Dark Mode support.
7. **Phase 7: Resource & Mock Test Detail Overhaul:** Successfully implemented premium full-screen detail views for both resources and mock tests. Integrated real-time performance stats (sales, visibility) via `AdminService`. Added robust PDF processing with "Share" capabilities and enhanced the `PdfViewerScreen` with AppBar sharing actions.
8. **Phase 8: User-Friendly Error Handling:** Implemented `DbErrorHelper` to logically translate technical `PostgrestException` codes (e.g., 23503) into actionable admin instructions. Updated `TestService` and `ResourceService` to provide descriptive feedback, preventing confusion when attempting to delete purchased items.

---

## Known Issues & Status
- **Signal 3 (ANR) Crash**: Persistent main-thread blocking during startup/dashboard transition. Despite optimizations in `AuthProvider` (realtime filters) and `AdminMainScreen` (lazy loading), frame skipping remains high on some devices. Currently marked as **Unresolved**.

---

## Environment Variables (.env)
Uses the same `SUPABASE_URL` and `SUPABASE_ANON_KEY` as the user app to ensure they point to the same data source.

---

## Build & Run
```bash
flutter run # Runs the Admin Panel
```

9. **Phase 9: Splash Screen Redesign & UI Polishing:** Successfully implemented a premium, Material 3 splash screen with an animated progress bar and academic management branding. Consistently used the official playstore icon across both apps. Increased the Login screen logo size to `130x130` for a more prominent branding presence.

---

<!-- Updated on 2026-03-07 — Phase 9 Complete -->
