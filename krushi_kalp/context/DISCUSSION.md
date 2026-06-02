# Discussion Log

## [2026-06-02] — Downloads Screen Filename Mismatch Bug

### Problem
The Downloads screen (`downloads_screen.dart`) is not showing downloaded resources or mock tests even after successful downloads complete.

### Root Cause Analysis
The `_checkDownloads()` method checks for files using **old/wrong filename conventions**:
- Resources: checks `resource_<r.id>.pdf` — but actual downloaded files are named `resource_file_<file.id>.pdf` (per ResourceFile entry)
- Mock tests: checks `mock_test_<t.id>.json` — but actual downloaded files are named `mock_test_file_<file.id>.pdf` (per MockTestFile entry)

The logs confirm downloads complete successfully with the correct file-level filenames, yet `_localStatus` never sets them to `true` because the check uses wrong filenames.

### Discussion Status
Pending user approval before coding begins.
