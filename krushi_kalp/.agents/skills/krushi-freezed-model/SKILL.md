---
name: krushi-freezed-model
description: Create or update a Freezed immutable data class in Krushi Kalp using the Freezed 3.0-dev abstract class pattern. Use when defining domain models, state classes, or any immutable data structure.
metadata:
  model: claude-sonnet-4-5
  last_modified: Sun, 24 May 2026 00:00:00 GMT
---
# Freezed Models in Krushi Kalp

## Contents
- [Key Rules](#key-rules)
- [File Locations](#file-locations)
- [Workflow: Creating a Freezed Model](#workflow-creating-a-freezed-model)
- [Examples](#examples)

## Key Rules

Krushi Kalp uses **Freezed 3.0-dev** which requires the `abstract class` pattern:

```dart
// ✅ CORRECT — Freezed 3.0-dev
@freezed
abstract class MyModel with _$MyModel { ... }

// ❌ WRONG — old pattern, will fail
@freezed
class MyModel with _$MyModel { ... }
```

Always run after any model change:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Never edit `.freezed.dart` or `.g.dart` files — they are generated.

## File Locations

| Type | Location |
|---|---|
| Domain models (entities) | `lib/domain/models/model_name.dart` |
| Provider state classes | `lib/presentation/providers/feature_provider.dart` (inline) |
| Local Isar schemas | `lib/data/local/schema_name.dart` |

## Workflow: Creating a Freezed Model

### Task Progress
- [ ] **Step 1**: Create `lib/domain/models/model_name.dart`
- [ ] **Step 2**: Add imports: `freezed_annotation`, `json_annotation` (if JSON needed)
- [ ] **Step 3**: Add `part` directives for `.freezed.dart` and `.g.dart`
- [ ] **Step 4**: Define `@freezed abstract class` with `_$ClassName` mixin
- [ ] **Step 5**: Add `const factory` constructor with all fields
- [ ] **Step 6**: Add `factory fromJson(...)` if the model maps to Supabase/API data
- [ ] **Step 7**: Run `build_runner` to generate files
- [ ] **Step 8**: Run `flutter analyze` — fix any issues

## Examples

### Standard Domain Model (with JSON)

```dart
// lib/domain/models/mock_test.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'mock_test.freezed.dart';
part 'mock_test.g.dart';

@freezed
abstract class MockTest with _$MockTest {
  const factory MockTest({
    required String id,
    required String title,
    required String description,
    required int totalQuestions,
    required int durationMinutes,
    required double price,
    @Default(true) bool isActive,
    @Default(false) bool isPurchased,
    DateTime? createdAt,
  }) = _MockTest;

  factory MockTest.fromJson(Map<String, dynamic> json) =>
      _$MockTestFromJson(json);
}
```

### Sealed State Class (for Riverpod providers)

```dart
// Inline in provider file or separate state file
import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_state.freezed.dart';

@freezed
abstract class PaymentState with _$PaymentState {
  const factory PaymentState.idle() = _Idle;
  const factory PaymentState.processing() = _Processing;
  const factory PaymentState.success({required String orderId}) = _Success;
  const factory PaymentState.failed({required String message}) = _Failed;
}

// Usage in provider:
state.when(
  idle: () => const PayButton(),
  processing: () => const CircularProgressIndicator(),
  success: (orderId) => SuccessView(orderId: orderId),
  failed: (message) => ErrorView(message: message),
);
```

### Model with Custom JSON Parsing (numeric fields)

```dart
// lib/domain/models/order_item.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'order_item.freezed.dart';
part 'order_item.g.dart';

// Custom converter for Postgres numeric → double
class _NumConverter implements JsonConverter<double, dynamic> {
  const _NumConverter();

  @override
  double fromJson(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  @override
  dynamic toJson(double value) => value;
}

@freezed
abstract class OrderItem with _$OrderItem {
  const factory OrderItem({
    required String id,
    required String orderId,
    required String itemId,
    required String itemTitle,
    @_NumConverter() @Default(0.0) double price,
    required DateTime purchasedAt,
  }) = _OrderItem;

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      _$OrderItemFromJson(json);
}
```

### Nested Model

```dart
// lib/domain/models/user_performance.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_performance.freezed.dart';
part 'user_performance.g.dart';

@freezed
abstract class UserPerformance with _$UserPerformance {
  const factory UserPerformance({
    required String userId,
    required String testId,
    required int score,
    required int totalQuestions,
    required int correctAnswers,
    required int timeTakenSeconds,
    required DateTime completedAt,
    @Default([]) List<QuestionResult> questionResults,
  }) = _UserPerformance;

  factory UserPerformance.fromJson(Map<String, dynamic> json) =>
      _$UserPerformanceFromJson(json);
}

@freezed
abstract class QuestionResult with _$QuestionResult {
  const factory QuestionResult({
    required String questionId,
    required int selectedOption,
    required int correctOption,
    required bool isCorrect,
  }) = _QuestionResult;

  factory QuestionResult.fromJson(Map<String, dynamic> json) =>
      _$QuestionResultFromJson(json);
}
```
