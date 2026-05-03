# Project Structure

## Top-Level

```
krushi_kalp/
├── lib/                  # All Dart source code
├── android/              # Android platform project
├── ios/                  # iOS platform project
├── assets/
│   ├── images/           # App images, logos, banners
│   └── fonts/            # Custom fonts (NotoSansGujarati)
├── .env                  # Environment variables (never commit)
├── pubspec.yaml
└── analysis_options.yaml
```

## lib/ Architecture

Clean Architecture with three layers: Domain → Data → Presentation.

```
lib/
├── main.dart             # App entry point, service initialization
├── core/
│   ├── env/              # Envied-generated env access (Env class)
│   ├── router/           # GoRouter setup + RouteConstants
│   ├── theme/            # AppTheme (light/dark MaterialTheme)
│   └── utils/            # Core-level utilities
├── domain/
│   ├── models/           # Freezed data classes (MockTest, Resource, OrderItem, etc.)
│   └── services/         # Abstract service interfaces
├── data/
│   ├── services/         # Concrete service implementations (singleton pattern)
│   ├── repositories/     # Data access / repository layer
│   ├── local/            # Isar local database schemas and helpers
│   └── sql/              # Supabase SQL init/migration scripts
├── presentation/
│   ├── providers/        # Riverpod notifiers + generated .g.dart files
│   ├── screens/          # Full-page UI screens
│   │   └── admin/        # Admin-only screens
│   ├── widgets/          # Reusable UI components
│   └── utils/            # Presentation helpers (navigator key, etc.)
└── utils/                # Global utilities (Crashlytics, network, retry, etc.)
```

## Key Conventions

- **File naming**: `snake_case.dart` for all files
- **Class naming**: `PascalCase`
- **Services**: Singleton via `ServiceName._()` private constructor + `static final instance`
- **Providers**: `@Riverpod(keepAlive: true)` for long-lived state; standard `@riverpod` for scoped
- **Code generation**: Files ending in `.g.dart` are generated — do not edit manually. Regenerate with `build_runner`
- **No foreign keys in Supabase queries**: Related data is fetched separately and stitched manually in services
- **Error logging**: Always use `CrashlyticsService.instance.log/recordError` — never bare `print` in production paths
- **Route navigation**: Use `context.go()` / `context.push()` from GoRouter; route paths defined in `RouteConstants`
- **Responsive UI**: Use `ResponsiveBreakpoints.of(context)` or the `responsive.dart` utility for layout decisions

## Generated Files (do not edit)

| File pattern | Generator |
|---|---|
| `*.g.dart` | build_runner (Riverpod, Isar, Envied) |
| `*.freezed.dart` | freezed |
| `lib/core/env/env.g.dart` | envied |
