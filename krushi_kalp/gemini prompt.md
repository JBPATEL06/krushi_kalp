Here's the complete prompt:

---

**CONTEXT:** You have the full Krushi Kalp project context (CLAUDE.md). Read it carefully before making any changes.
claude md path = krushi_kalp\CLAUDE.md
---

## Task: Update Mock Test JSON Format

### Background
Migrating from **old flat format** (`11.json`):
```json
[{"id":1,"text":"Question?","options":["A","B","C","D"],"correctOptionIndex":2}]
```
To **new tableConvert format**:
```json
[{"No.":1,"Question":"Question?","Option A":"A","Option B":"B","Option C":"C","Option D":"D","Correct Answer":"C"}]
```

**No backward compatibility needed.** Admin will re-upload all tests via the edit form.

---

## Files To Change

### 1. `lib/domain/models/question.dart`
- **You have full permission to change this file.**
- Remove `correctOptionIndex`.
- Add `correctAnswer` as a `String` field.
- Updated model must be:
```dart
Question {
  int id,
  String text,
  List<String> options,
  String correctAnswer  // exact option text string
}
```
- Update `fromJson()` and `toJson()` accordingly.

### 2. `lib/utils/excel_to_json_converter.dart`
- Output must now produce the **new tableConvert format**.
- `Correct Answer` = the **matching option text string** (not an index).
- Variable option count still supported (Option A, B, C, D, E... based on columns).

### 3. Wherever new format JSON is parsed back into `List<Question>`
- Find the file/function that reads JSON from Supabase Storage and converts it into `List<Question>`.
- Update parser for **new format only**:
  - `No.` → `id`
  - `Question` → `text`
  - `Option A/B/C/...` → `options[]`
  - `Correct Answer` text string → `correctAnswer`
- **Trim and case-insensitive match** when storing `correctAnswer` to keep it clean.
- If `Correct Answer` value doesn't match any option in the list, **throw a descriptive error** (e.g. `"Question #3: Correct Answer 'Venus' not found in options"`). Never silently default.

---

## Cascading Changes Required
Because `Question` model is changing from `correctOptionIndex` (int) to `correctAnswer` (String), you **must** find and update every file that references `correctOptionIndex` or uses `Question` for answer checking. Key places to check:

- `ExamScreen` — answer comparison logic
- `TestResultScreen` — score calculation
- `TestAnalysisScreen` — correct vs user answer display
- `PdfService` — result PDF generation
- `test_results` DB persistence (if correctOptionIndex is stored anywhere)
- Any other file referencing `question.correctOptionIndex`

For each of these, replace index-based comparison with string-based comparison:
```dart
// OLD
userAnswerIndex == question.correctOptionIndex

// NEW
options[userAnswerIndex].trim().toLowerCase() == question.correctAnswer.trim().toLowerCase()
```

---

## Scoring & Engine Must Still Work
- Scoring, negative marking, pass/fail, analysis, PDF generation — **all must work correctly** after this change.
- The answer check is now string comparison, not index comparison. Apply this consistently everywhere.
- Do not break the `ExamScreen` timer, nav lock, or question flow — only touch answer evaluation logic.

---

## Do NOT Touch
- Any provider, theme, auth, payment, download, routing, or notification files
- Any service other than the JSON parsing section and any answer-checking logic
- Any screen other than the minimal answer comparison fix in exam/result/analysis screens
- Anything not directly related to this format migration

---

## Deliverable
Full file content for **every changed file**, with `// CHANGED` comments on every modified line. List all changed files at the top of your response so nothing is missed.

---

## Final Requirement: Update CLAUDE.md

After all code changes are complete, update the `CLAUDE.md` project context file with every change you made. Specifically:

- In the **Mock Test System (Deep Dive)** section, update the JSON format description and parsing logic to reflect the new tableConvert format.
- In the **Domain Models** section, update the `question.dart` row to reflect the new `correctAnswer: String` field replacing `correctOptionIndex: int`.
- In the **Historical Improvements** section, add a new dated entry (2026-03-08 or today's date) documenting:
  - Migration from flat JSON format to tableConvert format
  - `Question` model change (`correctOptionIndex` → `correctAnswer`)
  - All files that were changed and why
- In the **File-by-File Reference** section, update any rows that reference changed files to reflect their new behavior.
- If any new parsing logic or answer comparison pattern was introduced, document it clearly so future developers understand the string-based answer matching approach.

**The CLAUDE.md must be a complete, accurate reflection of the codebase after your changes. Treat it as the single source of truth for this project.**