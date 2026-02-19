import 'package:flutter/material.dart';
import '../../domain/models/test_result.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          // Gradient Background for Modern Look
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryHover],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.2), // Adjusted alpha
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (result != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            "View Full Report",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: AppSpacing.xs),
                          Icon(Icons.arrow_forward_rounded,
                              size: 14, color: Colors.white),
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
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: Colors.white,
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Text(
                        result!.isPassed ? "PASSED" : "NOT PASSED",
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: result!.isPassed
                                  ? AppColors.primary
                                  : AppColors.error,
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  _formatDate(result!.attemptDate),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                ),
              ] else ...[
                // Empty State
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.assignment_outlined,
                          size: 40, color: Colors.white.withValues(alpha: 0.4)),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        "No test attempts yet",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Your performance summary will appear here.",
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
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
