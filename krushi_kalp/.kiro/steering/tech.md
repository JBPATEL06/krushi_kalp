# Tech Stack

## Core

- **Flutter**: 3.0.0+ / **Dart**: 3.0.0+
- **State Management**: Riverpod (`flutter_riverpod`) with code generation via `riverpod_annotation` + `riverpod_generator`
- **Navigation**: GoRouter v17
- **Models**: Freezed (immutable data classes with `copyWith`)
- **Environment**: `envied` — reads `.env` and generates obfuscated `lib/core/env/env.g.dart`

## Backend & Services

- **Supabase** v2.12 — primary database (PostgreSQL), auth, storage
- **Firebase** — Crashlytics, Cloud Messaging (FCM), Cloud Firestore
- **Razorpay** — payment processing

## Local Storage

- **Isar** v3.1 — local database (requires `isar_generator` for code gen)
- **shared_preferences** — lightweight key-value storage

## Key UI Libraries

- `responsive_framework` — breakpoints: MOBILE (0–450), TABLET (451–800), DESKTOP (801+)
- `google_fonts`, `flutter_animate`, `shimmer`, `confetti`, `carousel_slider`
- `cached_network_image`, `infinite_scroll_pagination`
- `flutter_chat_ui` v1.6.12 (pinned)

## File & Document Handling

- `file_picker`, `open_filex`, `pdf`, `pdfrx`, `excel`

## Notifications

- `flutter_local_notifications` v19, `flutter_background_service` v5

## Linting

- `flutter_lints` (base) + `very_good_analysis` v10.2 (dev)
- Run: `flutter analyze`

---

## Common Commands

```bash
# Install dependencies
flutter pub get

# Run code generation (Riverpod, Freezed, Isar, Envied) — run after model/provider changes
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode for code generation during development
flutter pub run build_runner watch --delete-conflicting-outputs

# Run app
flutter run

# Analyze code
flutter analyze

# Build Android APK (release)
flutter build apk --release

# Build Android App Bundle (for Play Store)
flutter build appbundle --release

# Generate splash screen assets
flutter pub run flutter_native_splash:create

# Generate launcher icons
flutter pub run flutter_launcher_icons
```

## Environment Setup

Copy `.env` to the project root with these keys before running:

```
SUPABASE_URL=
SUPABASE_ANON_KEY=
RAZORPAY_KEY_ID=
ENCRYPTION_KEY=        # must be exactly 32 characters
GOOGLE_WEB_CLIENT_ID=
```

After updating `.env`, re-run `build_runner` to regenerate `env.g.dart`.
