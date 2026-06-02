---
name: krushi-analyze-and-fix
description: Run static analysis on the Krushi Kalp codebase, interpret the output, and systematically fix all errors and warnings following project conventions. Use before any commit, build, or Play Store submission.
metadata:
  model: claude-sonnet-4-5
  last_modified: Sun, 24 May 2026 00:00:00 GMT
---
# Static Analysis & Fix Workflow for Krushi Kalp

## Contents
- [Analysis Setup](#analysis-setup)
- [Common Error Patterns](#common-error-patterns)
- [Workflow: Analyze and Fix](#workflow-analyze-and-fix)
- [Pre-Build Checklist](#pre-build-checklist)

## Analysis Setup

Krushi Kalp uses `flutter_lints` (base) + `very_good_analysis` v10.2 (dev). The `analysis_options.yaml` at the project root controls all rules.

Generated files are excluded from analysis — never try to fix `.g.dart` or `.freezed.dart` files. Regenerate them instead:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Common Error Patterns in This Project

| Error | Fix |
|---|---|
| `The class 'X' doesn't have a default constructor` | Freezed model uses old `class` pattern — change to `abstract class` |
| `Part of directive found, but no part declaration` | Missing `part 'x.g.dart'` or `build_runner` not run |
| `Undefined name '_$ClassName'` | Run `build_runner` — generated mixin missing |
| `print` usage | Replace with `CrashlyticsService.instance.log(...)` |
| `Navigator.push` usage | Replace with `context.go()` or `context.push()` |
| Nullable receiver without `?` | Add null check or `?.` operator |
| `dynamic` type inference | Add explicit type annotation |
| Missing `is_active` filter | Add `.eq('is_active', true)` to Supabase query |
| `RefreshIndicator` missing | Wrap list body in `RefreshIndicator` |
| Missing system UI padding | Add `MediaQuery.of(context).padding.bottom` to list padding |

## Workflow: Analyze and Fix

### Task Progress
- [ ] **Step 1**: Run the analyzer
  ```bash
  flutter analyze
  ```
- [ ] **Step 2**: If errors mention `.g.dart` or `.freezed.dart` — regenerate first
  ```bash
  flutter pub run build_runner build --delete-conflicting-outputs
  ```
- [ ] **Step 3**: Re-run analyzer after codegen
  ```bash
  flutter analyze
  ```
- [ ] **Step 4**: Fix errors by category (see Common Error Patterns above)
- [ ] **Step 5**: For mechanical fixes, try auto-fix
  ```bash
  dart fix --dry-run
  dart fix --apply
  ```
- [ ] **Step 6**: Re-run analyzer until zero errors
  ```bash
  flutter analyze
  ```
- [ ] **Step 7**: Format code
  ```bash
  dart format lib/
  ```

## Pre-Build Checklist

Run this before every `flutter build apk --release` or Play Store submission:

- [ ] `flutter analyze` — zero errors, zero warnings
- [ ] `flutter pub run build_runner build --delete-conflicting-outputs` — all generated files up to date
- [ ] No `print` statements in production paths — use `CrashlyticsService`
- [ ] All new screens have `RefreshIndicator` + system UI padding
- [ ] All Supabase queries on user-facing content have `.eq('is_active', true)`
- [ ] `pubspec.yaml` version incremented (`version: X.Y.Z+build`)
- [ ] Run `python check_align.py` to verify 16KB page alignment for Android 15
- [ ] Test on physical device or emulator before submission
