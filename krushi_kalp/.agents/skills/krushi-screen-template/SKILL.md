---
name: krushi-screen-template
description: Scaffold a production-ready screen in Krushi Kalp with all mandatory patterns applied — RefreshIndicator, system UI padding, NetworkErrorState, Riverpod consumption, and responsive layout. Use when creating any new screen.
metadata:
  model: claude-sonnet-4-5
  last_modified: Sun, 24 May 2026 00:00:00 GMT
---
# Screen Templates for Krushi Kalp

## Contents
- [Mandatory Screen Patterns](#mandatory-screen-patterns)
- [Screen Types](#screen-types)
- [Workflow: Creating a New Screen](#workflow-creating-a-new-screen)
- [Examples](#examples)

## Mandatory Screen Patterns

Every screen in Krushi Kalp MUST follow these rules — no exceptions:

| Rule | Implementation |
|---|---|
| Pull-to-refresh | Wrap list body in `RefreshIndicator` |
| Scroll physics | `AlwaysScrollableScrollPhysics()` on all scrollable lists |
| System UI padding | `EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md)` |
| Error state | `NetworkErrorState(onRetry: ...)` — never raw `Text('Error')` |
| Loading state | `CircularProgressIndicator()` centered |
| No manual refresh buttons | No `IconButton` / `TextButton` for refresh in AppBar |
| Navigation | `context.go()` / `context.push()` — never `Navigator.push` |
| Error logging | `CrashlyticsService.instance.recordError` — never `print` |

## Screen Types

### List Screen
A screen showing a paginated or full list of items (tests, resources, orders).

### Detail Screen
A screen showing a single item's full details (test detail, resource viewer).

### Form Screen
A screen with input fields for creating or editing data (admin upload, profile edit).

### Admin Screen
Lives in `lib/presentation/screens/admin/`. Same rules apply.

## Workflow: Creating a New Screen

### Task Progress
- [ ] **Step 1**: Create file in `lib/presentation/screens/feature_screen.dart`
- [ ] **Step 2**: Extend `ConsumerStatefulWidget` (or `ConsumerWidget` for simple screens)
- [ ] **Step 3**: Watch the relevant Riverpod provider
- [ ] **Step 4**: Implement `loading` / `error` / `data` states via `state.when(...)`
- [ ] **Step 5**: Wrap list body in `RefreshIndicator` with `AlwaysScrollableScrollPhysics`
- [ ] **Step 6**: Apply system UI bottom padding to list padding
- [ ] **Step 7**: Use `NetworkErrorState` for error state with `onRetry`
- [ ] **Step 8**: Add route in `RouteConstants` and GoRouter config
- [ ] **Step 9**: Run `flutter analyze` — fix all issues

## Examples

### List Screen (full template)

```dart
// lib/presentation/screens/resource_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:krushi_kalp/core/router/route_constants.dart';
import 'package:krushi_kalp/core/theme/app_spacing.dart';
import 'package:krushi_kalp/presentation/providers/resource_provider.dart';
import 'package:krushi_kalp/presentation/widgets/network_error_state.dart';
import 'package:krushi_kalp/presentation/widgets/resource_tile.dart';

class ResourceListScreen extends ConsumerStatefulWidget {
  const ResourceListScreen({super.key});

  @override
  ConsumerState<ResourceListScreen> createState() => _ResourceListScreenState();
}

class _ResourceListScreenState extends ConsumerState<ResourceListScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resourceNotifierProvider);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resources'),
        // ❌ No refresh IconButton here — use pull-to-refresh only
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => NetworkErrorState(
          onRetry: () => ref.invalidate(resourceNotifierProvider),
        ),
        data: (resources) => RefreshIndicator(
          onRefresh: () =>
              ref.read(resourceNotifierProvider.notifier).refresh(),
          child: resources.isEmpty
              ? const SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Center(child: Text('No resources available')),
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: bottomPad + AppSpacing.md,
                    top: AppSpacing.sm,
                  ),
                  itemCount: resources.length,
                  itemBuilder: (context, index) => ResourceTile(
                    resource: resources[index],
                    onTap: () => context.push(
                      RouteConstants.resourceDetail,
                      extra: resources[index],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
```

### Detail Screen (single item)

```dart
// lib/presentation/screens/mock_test_detail_screen.dart
class MockTestDetailScreen extends ConsumerStatefulWidget {
  const MockTestDetailScreen({super.key, required this.testId});

  final String testId;

  @override
  ConsumerState<MockTestDetailScreen> createState() =>
      _MockTestDetailScreenState();
}

class _MockTestDetailScreenState extends ConsumerState<MockTestDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mockTestDetailProvider(widget.testId));
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Test Details')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => NetworkErrorState(
          onRetry: () => ref.invalidate(mockTestDetailProvider(widget.testId)),
        ),
        data: (test) => RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(mockTestDetailProvider(widget.testId)),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              bottom: bottomPad + AppSpacing.md,
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(test.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.sm),
                Text(test.description),
                // ... more detail widgets
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

### Responsive Layout (mobile + tablet)

```dart
@override
Widget build(BuildContext context) {
  final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

  return Scaffold(
    body: isTablet
        ? Row(
            children: [
              SizedBox(width: 300, child: _buildSidebar()),
              const VerticalDivider(width: 1),
              Expanded(child: _buildContent()),
            ],
          )
        : _buildContent(),
  );
}
```
