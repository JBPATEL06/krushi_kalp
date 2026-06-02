---
name: krushi-add-feature
description: End-to-end workflow for adding a new feature to Krushi Kalp following its Clean Architecture (Domain → Data → Presentation). Use when building any new screen, data flow, or business capability.
metadata:
  model: claude-sonnet-4-5
  last_modified: Sun, 24 May 2026 00:00:00 GMT
---
# Adding a New Feature to Krushi Kalp

## Contents
- [Architecture Layers](#architecture-layers)
- [Mandatory Conventions](#mandatory-conventions)
- [Workflow: Implementing a New Feature](#workflow-implementing-a-new-feature)
- [Examples](#examples)

## Architecture Layers

Krushi Kalp uses strict Clean Architecture. Never mix layers.

```
lib/
├── domain/models/        ← Freezed immutable data classes
├── domain/services/      ← Abstract service interfaces
├── data/services/        ← Concrete Supabase/Firebase implementations (singleton)
├── data/repositories/    ← Data access + stitching logic
├── data/local/           ← Isar schemas for offline caching
├── presentation/providers/  ← Riverpod Notifiers + .g.dart
├── presentation/screens/    ← ConsumerStatefulWidget screens
└── presentation/widgets/    ← Reusable UI components
```

## Mandatory Conventions

- **Models**: Use `@freezed` with `abstract class`. Run `build_runner` after changes.
- **Services**: Singleton via `ServiceName._()` + `static final instance`. Never instantiate directly.
- **Providers**: Use `@Riverpod(keepAlive: true)` for long-lived state; `@riverpod` for scoped. All generated providers follow `*Provider` naming.
- **No foreign keys in queries**: Fetch related data separately and stitch manually in the service layer.
- **Error logging**: Always use `CrashlyticsService.instance.log/recordError`. Never use bare `print`.
- **Navigation**: Use `context.go()` / `context.push()`. Paths defined in `RouteConstants`.
- **Responsive UI**: Use `ResponsiveBreakpoints.of(context)` — breakpoints: MOBILE (0–450), TABLET (451–800), DESKTOP (801+).
- **Pull-to-Refresh**: Every scrollable list screen MUST use `RefreshIndicator`. Manual refresh buttons in AppBar are **forbidden**.
- **System UI Padding**: All list/scroll views MUST apply `EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md)` to list padding.
- **is_active filter**: Always apply `is_active = true` filter on all user-side content fetches from Supabase.

## Workflow: Implementing a New Feature

Copy this checklist and track progress step by step.

### Task Progress
- [ ] **Step 1: Domain Model** — Create a `@freezed abstract class` in `lib/domain/models/`. Run `build_runner`.
- [ ] **Step 2: Service Interface** — Define abstract methods in `lib/domain/services/`.
- [ ] **Step 3: Supabase Service** — Implement the singleton service in `lib/data/services/`. Fetch related data separately and stitch manually. Log all errors via `CrashlyticsService`.
- [ ] **Step 4: Isar Schema (if offline needed)** — Create schema in `lib/data/local/`. Run `build_runner`.
- [ ] **Step 5: Repository** — Wire service + local cache in `lib/data/repositories/`.
- [ ] **Step 6: Riverpod Provider** — Create `@riverpod` or `@Riverpod(keepAlive: true)` notifier in `lib/presentation/providers/`. Run `build_runner`.
- [ ] **Step 7: Screen** — Create `ConsumerStatefulWidget` in `lib/presentation/screens/`. Apply `RefreshIndicator`, system UI padding, and `NetworkErrorState` for error states.
- [ ] **Step 8: Route** — Add path to `RouteConstants` and register in GoRouter config.
- [ ] **Step 9: Analyze** — Run `flutter analyze` and fix all issues.

## Examples

### Step 1 — Freezed Domain Model

```dart
// lib/domain/models/announcement.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'announcement.freezed.dart';
part 'announcement.g.dart';

@freezed
abstract class Announcement with _$Announcement {
  const factory Announcement({
    required String id,
    required String title,
    required String body,
    required DateTime createdAt,
    @Default(true) bool isActive,
  }) = _Announcement;

  factory Announcement.fromJson(Map<String, dynamic> json) =>
      _$AnnouncementFromJson(json);
}
```

### Step 3 — Singleton Supabase Service

```dart
// lib/data/services/announcement_service.dart
import 'package:krushi_kalp/utils/crashlytics_service.dart';

class AnnouncementService {
  AnnouncementService._();
  static final instance = AnnouncementService._();

  final _client = Supabase.instance.client;

  Future<List<Announcement>> fetchAnnouncements() async {
    try {
      final response = await _client
          .from('announcements')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      CrashlyticsService.instance.recordError(e, st, reason: 'fetchAnnouncements');
      rethrow;
    }
  }
}
```

### Step 6 — Riverpod Notifier

```dart
// lib/presentation/providers/announcement_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'announcement_provider.g.dart';

@riverpod
class AnnouncementNotifier extends _$AnnouncementNotifier {
  @override
  Future<List<Announcement>> build() => _fetch();

  Future<List<Announcement>> _fetch() =>
      AnnouncementService.instance.fetchAnnouncements();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}
```

### Step 7 — Screen with RefreshIndicator + System Padding

```dart
// lib/presentation/screens/announcement_screen.dart
class AnnouncementScreen extends ConsumerStatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  ConsumerState<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends ConsumerState<AnnouncementScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(announcementNotifierProvider);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => NetworkErrorState(
          onRetry: () => ref.invalidate(announcementNotifierProvider),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () => ref.read(announcementNotifierProvider.notifier).refresh(),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(bottom: bottomPad + AppSpacing.md),
            itemCount: items.length,
            itemBuilder: (context, i) => AnnouncementTile(item: items[i]),
          ),
        ),
      ),
    );
  }
}
```
