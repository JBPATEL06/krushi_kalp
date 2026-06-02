# Krushi Kalp - Project Context

## Project Goal
Agricultural education app with resource library (PDFs), mock tests, downloads, and exam functionality.

## Tech Stack
- Flutter (Dart) — Android primary target
- Supabase (auth + storage + DB)
- Riverpod (state management, Riverpod Annotation + Freezed)
- Isar (local NoSQL cache)
- GoRouter (navigation)

## Architecture
Clean architecture: Presentation → Domain → Data

## Current Active Phase
Phase: Fix Downloads Screen — show downloaded resource files and mock test files correctly.

## Completed Phases
- Auth flow (login, signup, forgot password)
- Home screen, Store, Cart, Checkout
- Resource files system (resource_files table, supplementary files)
- Mock test files system (mock_test_files table, supplementary files)
- Download queue service (FIFO background downloads)
- PDF viewer

## Pending Phases
- Fix Downloads Screen filename mismatch bug

## Key Decisions
- Resources use supplementary files via `resource_files` table; filename: `resource_file_<file.id>.pdf`
- Mock tests use supplementary files via `mock_test_files` table; filename: `mock_test_file_<file.id>.pdf`
- Legacy resources use `resource_<resource.id>.pdf` (single file per resource, fileUrl path)
- Legacy mock tests use `mock_test_<test.id>.json` (JSON question file)
- DownloadService stores files per-user: `/user_<userId>/<sanitized_filename>`

## Known Risks
- Downloads screen checks old filename conventions (`resource_<id>.pdf`, `mock_test_<id>.json`) instead of the new file-level conventions (`resource_file_<file.id>.pdf`, `mock_test_file_<file.id>.pdf`)
