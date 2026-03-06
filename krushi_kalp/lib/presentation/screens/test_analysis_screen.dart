import 'package:flutter/material.dart';
import '../../domain/models/question.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/translation_service.dart';
import '../../core/theme/app_spacing.dart';

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
  bool _shouldTranslate = false;
  bool _isLoadingLanguage = true;

  @override
  void initState() {
    super.initState();
    _checkUserLanguage();
  }

  Future<void> _checkUserLanguage() async {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      try {
        final userData = await AuthService.instance.getUserProfile(user.id);

        if (userData != null && userData['language'] == 'gu') {
          if (mounted) {
            setState(() {
              _shouldTranslate = true;
            });
          }
        }
      } catch (e) {
        // Ignore error, default to English
      }
    }
    if (mounted) {
      setState(() {
        _isLoadingLanguage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLanguage) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Analysis: ${widget.testTitle}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
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
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: widget.questions.length,
        itemBuilder: (context, index) {
          final originalQuestion = widget.questions[index];

          return FutureBuilder<Question>(
            initialData: originalQuestion,
            future: _shouldTranslate
                ? TranslationService.translateQuestion(originalQuestion)
                : Future.value(originalQuestion),
            builder: (context, snapshot) {
              // Ensure we have data (initialData guarantees this, but good to be safe)
              final q = snapshot.data ?? originalQuestion;
              final userSelected = widget.selectedAnswers[index];

              return _buildAnalysisCard(q, index, userSelected);
            },
          );
        },
      ),
    );
  }

  Widget _buildAnalysisCard(Question q, int index, int? selectedOption) {
    final isCorrect = selectedOption == q.correctOptionIndex;
    final isSkipped = selectedOption == null;

    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
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
                radius: 12,
                backgroundColor: isSkipped
                    ? theme.colorScheme.outline
                    : (isCorrect
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error),
                child: Icon(
                  isSkipped
                      ? Icons.remove
                      : (isCorrect ? Icons.check : Icons.close),
                  size: 16,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Question ${index + 1}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            q.text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...List.generate(q.options.length, (optIndex) {
            final isSelected = selectedOption == optIndex;
            final isRealAnswer = q.correctOptionIndex == optIndex;

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
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: bgColor ?? theme.colorScheme.surface,
                border: Border.all(
                  color: borderColor,
                  width: (isSelected || isRealAnswer) ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
                          ),
                    ),
                  ),
                  if (icon != null)
                    Icon(
                      icon,
                      color: isRealAnswer
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                      size: 20,
                    ),
                ],
              ),
            );
          }),
          if (isSkipped)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                'You skipped this question',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
