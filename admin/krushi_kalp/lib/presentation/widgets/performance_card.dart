import 'package:flutter/material.dart';
import '../../domain/models/test_result.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

class PerformanceCard extends StatelessWidget {
  final TestResult? result;
  final VoidCallback? onTap;

  const PerformanceCard({
    super.key,
    this.result,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              HSLColor.fromColor(colorScheme.primary)
                  .withLightness(0.55)
                  .toColor(),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Latest Result",
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (result != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Row(
                        children: [
                          Text(
                            "View Details",
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Icon(Icons.arrow_forward_rounded,
                              size: 14, color: colorScheme.onPrimary),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              if (result != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      result!.scoreObtained.toStringAsFixed(1),
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: colorScheme.onPrimary,
                        height: 1.0,
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          bottom: 10.0, left: AppSpacing.xs),
                      child: Text(
                        "/ ${result!.totalMarks.toInt()}",
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onPrimary.withOpacity(0.7),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        result!.isPassed ? "PASSED" : "NOT PASSED",
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: result!.isPassed
                              ? colorScheme.primary
                              : colorScheme.error,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  result!.testTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatDate(result!.attemptDate),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimary.withOpacity(0.6),
                  ),
                ),
              ] else ...[
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.assignment_outlined,
                          size: 40,
                          color: colorScheme.onPrimary.withOpacity(0.4)),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        "No test attempts yet",
                        style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Your performance summary will appear here.",
                        style: TextStyle(
                            color: colorScheme.onPrimary.withOpacity(0.6),
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} • ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}
