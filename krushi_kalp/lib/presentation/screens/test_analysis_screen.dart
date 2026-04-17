import 'package:flutter/material.dart';
import 'package:krushi_kalp/data/services/auth_service.dart';
import '../../domain/models/question.dart';
import '../../data/services/translation_service.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart'; // FIXED: Added import for radius tokens
import '../widgets/common/responsive_wrapper.dart'; // FIXED: Added import for responsive scaling
import '../../utils/crashlytics_service.dart';

class TestAnalysisScreen extends StatefulWidget {
  final String testTitle;
  final List<Question> questions;
  final Map<int, int> selectedAnswers;

  const TestAnalysisScreen({
    super.key,
    required this.testTitle,
    required this.questions,
    required this.selectedAnswers,
  });

  @override
  State<TestAnalysisScreen> createState() => _TestAnalysisScreenState();
}

class _TestAnalysisScreenState extends State<TestAnalysisScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Analysis: ${widget.testTitle}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: context.sp(18), // FIXED: context.sp(18)
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: AppSpacing.md +
              MediaQuery.of(context)
                  .padding
                  .bottom, // FIXED: AppSpacing.md + bottom padding
        ),
        itemCount: widget.questions.length,
        itemBuilder: (context, index) {
          final q = widget.questions[index];
          final userSelected = widget.selectedAnswers[index];
          return _buildAnalysisCard(q, index, userSelected);
        },
      ),
    );
  }

  Widget _buildAnalysisCard(Question q, int index, int? selectedOption) {
    // CHANGED: Use string-based comparison for correct answer
    final bool isCorrect = selectedOption != null &&
        q.options[selectedOption].trim().toLowerCase() ==
            q.correctAnswer.trim().toLowerCase(); // CHANGED
    final isSkipped = selectedOption == null;

    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.only(
          bottom: context.h(AppSpacing.lg)), // FIXED: context.h(AppSpacing.lg)
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius:
            BorderRadius.circular(AppRadius.lg), // FIXED: AppRadius.lg
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: context.sp(12), // FIXED: context.sp(12)
                backgroundColor: isSkipped
                    ? theme.colorScheme.outline
                    : (isCorrect
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error),
                child: Icon(
                  isSkipped
                      ? Icons.remove
                      : (isCorrect ? Icons.check : Icons.close),
                  size: context.sp(16), // FIXED: context.sp(16)
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              SizedBox(
                  width: context
                      .w(AppSpacing.sm)), // FIXED: context.w(AppSpacing.sm)
              Expanded(
                // FIXED: Added Expanded
                child: Text(
                  'Question ${index + 1}',
                  overflow: TextOverflow.ellipsis, // FIXED: Added ellipsis
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: context.sp(14), // FIXED: context.sp(14)
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
              height:
                  context.h(AppSpacing.md)), // FIXED: context.h(AppSpacing.md)
          Text(
            q.text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                  fontSize: context.sp(16), // FIXED: context.sp(16)
                ),
          ),
          SizedBox(
              height:
                  context.h(AppSpacing.lg)), // FIXED: context.h(AppSpacing.lg)
          ...List.generate(q.options.length, (optIndex) {
            final isSelected = selectedOption == optIndex;
            // CHANGED: Identify correct option by string match
            final isRealAnswer = q.options[optIndex].trim().toLowerCase() ==
                q.correctAnswer.trim().toLowerCase(); // CHANGED

            Color? bgColor;
            Color borderColor = theme.colorScheme.outline;
            IconData? icon;

            if (isRealAnswer) {
              borderColor = theme.colorScheme.primary;
              bgColor = theme.colorScheme.primary.withValues(alpha: 0.1);
              icon = Icons.check_circle;
            } else if (isSelected && !isRealAnswer) {
              borderColor = theme.colorScheme.error;
              bgColor = theme.colorScheme.error.withValues(alpha: 0.1);
              icon = Icons.cancel;
            }

            return Container(
              margin: EdgeInsets.only(
                  bottom: context
                      .h(AppSpacing.sm)), // FIXED: context.h(AppSpacing.sm)
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: bgColor ?? theme.colorScheme.surface,
                border: Border.all(
                  color: borderColor,
                  width: (isSelected || isRealAnswer) ? 2 : 1,
                ),
                borderRadius:
                    BorderRadius.circular(AppRadius.md), // FIXED: AppRadius.md
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      q.options[optIndex],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: (isRealAnswer || isSelected)
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: (isRealAnswer || isSelected)
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: context.sp(14), // FIXED: context.sp(14)
                          ),
                    ),
                  ),
                  if (icon != null)
                    Icon(
                      icon,
                      color: isRealAnswer
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                      size: context.sp(20), // FIXED: context.sp(20)
                    ),
                ],
              ),
            );
          }),
          if (isSkipped)
            Padding(
              padding: EdgeInsets.only(
                  top: context
                      .h(AppSpacing.sm)), // FIXED: context.h(AppSpacing.sm)
              child: Text(
                'You skipped this question',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontStyle: FontStyle.italic,
                  fontSize: context.sp(12), // FIXED: context.sp(12)
                ),
              ),
            ),
        ],
      ),
    );
  }
}
