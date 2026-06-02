---
name: krushi-riverpod-provider
description: Create, update, or debug Riverpod providers in Krushi Kalp using the project's Riverpod 3.0 + code-generation pattern. Use when adding state, async data fetching, or notifiers.
metadata:
  model: claude-sonnet-4-5
  last_modified: Sun, 24 May 2026 00:00:00 GMT
---
# Riverpod Providers in Krushi Kalp

## Contents
- [Provider Patterns](#provider-patterns)
- [State Class Pattern](#state-class-pattern)
- [Naming Conventions](#naming-conventions)
- [Workflow: Creating a Provider](#workflow-creating-a-provider)
- [Examples](#examples)

## Provider Patterns

Krushi Kalp uses **Riverpod 3.0 with code generation** (`riverpod_annotation` + `riverpod_generator`). All providers are annotation-driven — never write `Provider(...)` manually.

| Use Case | Annotation | Generated Name |
|---|---|---|
| Long-lived global state (auth, cart, user) | `@Riverpod(keepAlive: true)` | `*Provider` |
| Scoped / screen-level state | `@riverpod` | `*Provider` |
| Simple computed value | `@riverpod` on a function | `*Provider` |
| Async data (Supabase fetch) | `@riverpod` returning `Future<T>` | `*Provider` |

After any provider change, run:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## State Class Pattern

Krushi Kalp uses `abstract class` for Freezed state classes (required by Freezed 3.0-dev):

```dart
@freezed
abstract class MyState with _$MyState {
  const factory MyState.initial() = _Initial;
  const factory MyState.loading() = _Loading;
  const factory MyState.data(List<Item> items) = _Data;
  const factory MyState.error(String message) = _Error;
}
```

For async providers, prefer `AsyncValue<T>` directly — it already provides `loading`, `data`, and `error` states.

## Naming Conventions

- Provider file: `lib/presentation/providers/feature_name_provider.dart`
- Part file: `part 'feature_name_provider.g.dart';`
- Class: `FeatureNameNotifier extends _$FeatureNameNotifier`
- Generated provider: `featureNameNotifierProvider`
- Watch in widget: `ref.watch(featureNameNotifierProvider)`
- Read for actions: `ref.read(featureNameNotifierProvider.notifier).methodName()`

## Workflow: Creating a Provider

### Task Progress
- [ ] **Step 1**: Create `lib/presentation/providers/feature_provider.dart`
- [ ] **Step 2**: Add `part 'feature_provider.g.dart';`
- [ ] **Step 3**: Annotate with `@riverpod` or `@Riverpod(keepAlive: true)`
- [ ] **Step 4**: Implement `build()` — return initial state or async fetch
- [ ] **Step 5**: Add action methods (refresh, update, etc.)
- [ ] **Step 6**: Run `build_runner` to generate `.g.dart`
- [ ] **Step 7**: Consume in screen with `ref.watch()` / `ref.read()`
- [ ] **Step 8**: Run `flutter analyze` — fix any issues

## Examples

### Async Data Provider (Supabase fetch)

```dart
// lib/presentation/providers/mock_test_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:krushi_kalp/data/services/mock_test_service.dart';
import 'package:krushi_kalp/domain/models/mock_test.dart';

part 'mock_test_provider.g.dart';

@riverpod
class MockTestNotifier extends _$MockTestNotifier {
  @override
  Future<List<MockTest>> build() => _fetch();

  Future<List<MockTest>> _fetch() =>
      MockTestService.instance.fetchActiveTests();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}
```

### Keep-Alive Provider (global auth state)

```dart
// lib/presentation/providers/auth_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() => const AuthState.initial();

  Future<void> signIn(String email, String password) async {
    state = const AuthState.loading();
    try {
      final user = await AuthService.instance.signIn(email, password);
      state = AuthState.authenticated(user);
    } catch (e, st) {
      CrashlyticsService.instance.recordError(e, st, reason: 'signIn');
      state = AuthState.error(e.toString());
    }
  }

  void signOut() {
    AuthService.instance.signOut();
    state = const AuthState.initial();
  }
}
```

### Consuming in a Screen

```dart
class MockTestScreen extends ConsumerStatefulWidget {
  const MockTestScreen({super.key});

  @override
  ConsumerState<MockTestScreen> createState() => _MockTestScreenState();
}

class _MockTestScreenState extends ConsumerState<MockTestScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mockTestNotifierProvider);

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => NetworkErrorState(
        onRetry: () => ref.invalidate(mockTestNotifierProvider),
      ),
      data: (tests) => RefreshIndicator(
        onRefresh: () =>
            ref.read(mockTestNotifierProvider.notifier).refresh(),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: tests.length,
          itemBuilder: (_, i) => MockTestTile(test: tests[i]),
        ),
      ),
    );
  }
}
```

### Simple Computed Provider (no notifier needed)

```dart
@riverpod
int cartItemCount(Ref ref) {
  final cart = ref.watch(cartNotifierProvider);
  return cart.maybeWhen(data: (items) => items.length, orElse: () => 0);
}
```
