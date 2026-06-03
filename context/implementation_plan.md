# Nested Mock Quiz Results and Scoring Improvements

This plan details the implementation of nested quiz attempt improvements, switching from total marks to a marks-per-question system, correcting mock test duration handling, updating result calculations, and fixing mock test launch points.

## User Review Required

> [!IMPORTANT]
> - **Database Migration Required:** We will add a `marks_per_question` column to the `mock_tests` table. We will set a default value of `1.0` and populate existing tests' values as `total_marks / total_questions`.
> - **Repurposing Column `total_questions`:** To avoid schema bloat, we will repurpose the existing `total_questions` column in the `mock_tests` table to store the count of mock tests in a package (e.g. 5 Tests instead of 5 Questions).

## Open Questions

> [!WARNING]
> - **Branch Selection:** Should this work go into a **new branch** or the **existing branch** (`feature/nested-quizzes-refinements`)?

---

## Proposed Changes

### Database Migration

#### [NEW] [migration.sql](file:///f:/krushi_kalp/context/migration.sql)
We will run a SQL migration script via Supabase:
```sql
ALTER TABLE mock_tests ADD COLUMN IF NOT EXISTS marks_per_question NUMERIC DEFAULT 1.0;
UPDATE mock_tests SET marks_per_question = COALESCE(
  CASE WHEN total_questions > 0 THEN total_marks::numeric / total_questions ELSE 1.0 END,
  1.0
) WHERE marks_per_question IS NULL;
```

---

### Domain Models

#### [MODIFY] [mock_test.dart](file:///f:/krushi_kalp/krushi_kalp/lib/domain/models/mock_test.dart)
- Add `marksPerQuestion` (double) to the `MockTest` domain model.
- Parse from `marks_per_question` key in `fromJson` and output key in `toJson` and `copyWith`.

#### [MODIFY] [test_result.dart](file:///f:/krushi_kalp/krushi_kalp/lib/domain/models/test_result.dart)
- Calculate `totalMarks` dynamically in `TestResult.fromJson` if `mock_test_file_id` is present by multiplying the total questions in the attempt (`correctAnswers + incorrectAnswers + skippedAnswers`) by `marks_per_question`. Otherwise, fall back to `totalQuestions * marks_per_question` (or the legacy total marks).

---

### Data Services

#### [MODIFY] [test_service.dart](file:///f:/krushi_kalp/krushi_kalp/lib/data/services/test_service.dart)
- Modify `fetchUserResults`, `fetchPaginatedUserResults`, and `fetchLatestResult` select queries to select `marks_per_question` and `total_questions` from the `mock_tests` table.
- Update `submitTestResult` to take `totalMarks` dynamically and insert correct records.

---

### UI Components & Screens

#### [MODIFY] [exam_screen.dart](file:///f:/krushi_kalp/krushi_kalp/lib/presentation/screens/exam_screen.dart)
- Calculate `marksPerQ` as `widget.test.marksPerQuestion`.
- Calculate `totalScore` as `correctCount * marksPerQ` (minus `wrongCount * negativeMarksPerQ` if negative marking is enabled).
- Submit test result with the calculated dynamic `totalMarks` for the attempt (`_questions.length * marksPerQ`).

#### [MODIFY] [mock_test_detail_screen.dart](file:///f:/krushi_kalp/krushi_kalp/lib/presentation/screens/mock_test_detail_screen.dart)
- Modify bottom bar START button to navigate to `MockTestFilesScreen` using `Navigator.push`.
- In `_buildStatsRow`, change the `Questions` key to "Mock Tests" (value: `${widget.test.totalQuestions}`).
- Change the `Marks` key to "Marks/Q" (value: `${widget.test.marksPerQuestion}`).

#### [MODIFY] [mock_test_files_screen.dart](file:///f:/krushi_kalp/krushi_kalp/lib/presentation/screens/mock_test_files_screen.dart)
- Change header info subtitle from `t.totalQuestions Qs | Marks: t.totalMarks` to `${t.totalQuestions} Tests | Marks/Q: ${t.marksPerQuestion}`.

#### [MODIFY] [store_grid.dart](file:///f:/krushi_kalp/krushi_kalp/lib/presentation/screens/store/widgets/store_grid.dart)
- Change subtitle to `${test.totalQuestions} Tests • ${test.marksPerQuestion} Marks/Q`.

#### [MODIFY] [purchased_tests_screen.dart](file:///f:/krushi_kalp/krushi_kalp/lib/presentation/screens/purchased_tests_screen.dart)
- Change subtitle to `${item.totalQuestions} Tests`.

#### [MODIFY] [free_content_screen.dart](file:///f:/krushi_kalp/krushi_kalp/lib/presentation/screens/free_content_screen.dart)
- Change subtitle to `${test.totalQuestions} Tests`.

#### [MODIFY] [downloads_screen.dart](file:///f:/krushi_kalp/krushi_kalp/lib/presentation/screens/downloads_screen.dart)
- Change subtitle to `${test.totalQuestions} Tests`.

#### [MODIFY] [all_tests_screen.dart](file:///f:/krushi_kalp/krushi_kalp/lib/presentation/screens/all_tests_screen.dart)
- Update card/row questions count to tests count.

#### [MODIFY] [mock_test_upload_screen.dart](file:///f:/krushi_kalp/krushi_kalp/lib/presentation/screens/mock_test_upload_screen.dart)
- Rename "Total Questions" text field to "Total Mock Tests".
- Rename "Total Marks" text field to "Marks per Question".
- Send `marks_per_question` (parsed double) in database insertion payload.

#### [MODIFY] [mock_test_edit_screen.dart](file:///f:/krushi_kalp/krushi_kalp/lib/presentation/screens/admin/mock_test_edit_screen.dart)
- Rename "Total Questions" text field to "Total Mock Tests".
- Rename "Total Marks" text field to "Marks per Question".
- Send `marks_per_question` in database update payload.

#### [MODIFY] [admin_mock_test_detail_screen.dart](file:///f:/krushi_kalp/krushi_kalp/lib/presentation/screens/admin/resources/admin_mock_test_detail_screen.dart)
- In the stats box row, rename "QUESTIONS" to "MOCK TESTS" and "TOTAL MARKS" to "MARKS / QUESTION" (displaying `marksPerQuestion`).

#### [MODIFY] [admin_mock_test_list.dart](file:///f:/krushi_kalp/krushi_kalp/lib/presentation/screens/admin/resources/admin_mock_test_list.dart)
- Change subtitle in list row from `${test.totalQuestions} Questions` to `${test.totalQuestions} Tests`.

---

## Verification Plan

### Automated Tests
- Run `dart analyze` to ensure that there are no syntax or type errors in the modified files.

### Manual Verification
- Deploy database migrations.
- Log in, navigate to purchased tests, view a mock test package details, check stats.
- Click START, open files screen, attempt a nested quiz.
- Complete attempt, verify correct scores/marks on result screen, verify results database persistence.
