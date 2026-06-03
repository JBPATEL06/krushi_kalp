# Negative Marking per Question & Scoring Improvements (Phase 67)

This plan details the implementation of negative marking per question details rendering, completing the remaining Admin panel UI renames for Phase 66, and ensuring correct scoring and display logic is implemented across both Student and Admin facing panels.

## User Review Required

> [!NOTE]
> The user requested to proceed directly on a new branch (`feature/phase-67-negative-marking`) and not wait for manual approval. All changes will be committed, checked via static analysis, and pushed directly.

## Proposed Changes

### UI Components & Screens

#### [MODIFY] [mock_test_edit_screen.dart](file:///f:/krushi_kalp/krushi_kalp/lib/presentation/screens/admin/mock_test_edit_screen.dart)
- Rename "Total Questions" text field label to "Total Mock Tests".
- Rename "Total Marks" text field label to "Marks per Question".
- Initialize `_totalMarksController` with `t.marksPerQuestion` instead of `t.totalMarks`.
- Update `_updateMockTest()` payload:
  - Save `marks_per_question` to database updates.
  - Calculate `total_marks` as `(total_questions * marks_per_question).round()`.

#### [MODIFY] [admin_mock_test_detail_screen.dart](file:///f:/krushi_kalp/krushi_kalp/lib/presentation/screens/admin/resources/admin_mock_test_detail_screen.dart)
- Rename info box label from `QUESTIONS` to `MOCK TESTS`.
- Rename info box label from `TOTAL MARKS` to `MARKS / QUESTION`.
- Display `_test.marksPerQuestion` instead of `_test.totalMarks` in the info box.

#### [MODIFY] [admin_mock_test_list.dart](file:///f:/krushi_kalp/krushi_kalp/lib/presentation/screens/admin/resources/admin_mock_test_list.dart)
- Change questions count text from `"${test.totalQuestions} Questions"` to `"${test.totalQuestions} Tests"`.

#### [MODIFY] [mock_test_files_screen.dart](file:///f:/krushi_kalp/krushi_kalp/lib/presentation/screens/mock_test_files_screen.dart)
- Display negative marking details in the subtitle if enabled, formatted as: `${t.totalQuestions} Tests | ${t.time} | Marks/Q: ${t.marksPerQuestion} | Neg: -${t.negativeMarksPerQ}`.

#### [MODIFY] [store_grid.dart](file:///f:/krushi_kalp/krushi_kalp/lib/presentation/screens/store/widgets/store_grid.dart)
- Display negative marking info in the grid card subtitle if enabled: `${test.totalQuestions} Tests • ${test.marksPerQuestion} Marks/Q • -${test.negativeMarksPerQ} Neg`.

---

## Verification Plan

### Automated Tests
- Run `dart analyze` to ensure 0 compilation issues and warnings.
