// NEW FILE
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:krushi_kalp/core/theme/app_theme.dart';
import 'package:krushi_kalp/core/theme/app_spacing.dart';
import 'package:krushi_kalp/core/theme/app_radius.dart';
import 'package:krushi_kalp/presentation/widgets/common/responsive_wrapper.dart';
import 'package:krushi_kalp/domain/models/user_performance.dart';

class PerformanceCard extends StatelessWidget {
  final UserPerformance data;
  final bool isLoading;

  const PerformanceCard({
    required this.data,
    this.isLoading = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Day labels — dynamic, always relative to today
    final dayLabels = List.generate(7, (i) {
      final day = DateTime.now().subtract(Duration(days: 6 - i));
      return ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day.weekday - 1];
    });

    Widget content;

    if (isLoading) {
      content = Row(
        children: [
          Expanded(
            flex: 55,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.75),
                  ],
                ),
              ),
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: context.sp(20),
                      width: context.w(150),
                      color: theme.colorScheme.surfaceContainerHighest),
                  SizedBox(height: AppSpacing.xs),
                  Container(
                      height: context.sp(12),
                      width: context.w(100),
                      color: theme.colorScheme.surfaceContainerHighest),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                          height: context.sp(30),
                          width: context.w(60),
                          color: theme.colorScheme.surfaceContainerHighest),
                      SizedBox(width: AppSpacing.lg),
                      Container(
                          height: context.sp(30),
                          width: context.w(60),
                          color: theme.colorScheme.surfaceContainerHighest),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Container(
                      height: context.sp(30),
                      width: context.w(60),
                      color: theme.colorScheme.surfaceContainerHighest),
                ],
              ).animate(onPlay: (controller) => controller.repeat()).shimmer(
                  duration: const Duration(milliseconds: 1500),
                  color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          Expanded(
            flex: 45,
            child: Container(
              color: theme.colorScheme.surface,
              padding: EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  7,
                  (i) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: Container(
                          height: context.h(40 + (i * 10)),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(AppRadius.sm)),
                          )),
                    ),
                  ),
                ),
              ).animate(onPlay: (controller) => controller.repeat()).shimmer(
                  duration: const Duration(milliseconds: 1500),
                  color: theme.colorScheme.surfaceContainerHighest),
            ),
          ),
        ],
      );
    } else {
      content = Row(
        children: [
          Expanded(
            flex: 55,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.75),
                  ],
                ),
              ),
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text("🔥"),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        "${data.streak} Day Streak",
                        style: TextStyle(
                          fontSize: context.sp(22),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  if (data.streak > 0) ...[
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      "Keep it up!",
                      style: TextStyle(
                        fontSize: context.sp(14),
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "AVG SCORE",
                            style: TextStyle(
                              fontSize: context.sp(11),
                              color: Colors.white.withValues(alpha: 0.6),
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            "${data.avgScore}%",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: context.sp(18),
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "TESTS",
                            style: TextStyle(
                              fontSize: context.sp(11),
                              color: Colors.white.withValues(alpha: 0.6),
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            "${data.testsCompleted}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: context.sp(18),
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "BEST",
                            style: TextStyle(
                              fontSize: context.sp(11),
                              color: Colors.white.withValues(alpha: 0.6),
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            "${data.bestScore}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: context.sp(18),
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 45,
            child: Container(
              color: theme.colorScheme.surface,
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "This Week",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: context.sp(14),
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 3,
                          horizontal: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          "${data.weeklyMinutes[6]}m",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: context.sp(11),
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (i) {
                        final minutes = data.weeklyMinutes[i];
                        final maxVal =
                            data.weeklyMinutes.reduce(max).clamp(1, 9999);
                        final heightFactor = minutes == 0
                            ? 0.08
                            : (minutes / maxVal).clamp(0.12, 1.0);
                        final isToday = i == 6;
                        final barColor = minutes == 0
                            ? theme.colorScheme.surfaceContainerHighest
                            : isToday
                                ? theme.colorScheme.primary
                                : theme.colorScheme.primary
                                    .withValues(alpha: 0.35);

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (isToday && minutes > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      "${minutes}m",
                                      style: TextStyle(
                                        fontSize: context.sp(10),
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                Flexible(
                                  child: FractionallySizedBox(
                                    alignment: Alignment.bottomCenter,
                                    heightFactor: heightFactor,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: barColor,
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(AppRadius.sm),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      7,
                      (i) => Text(
                        dayLabels[i],
                        style: TextStyle(
                          fontSize: context.sp(11),
                          color: i == 6
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight:
                              i == 6 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      height: context.h(180),
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: IntrinsicHeight(
          child: content,
        ),
      ),
    );
  }
}
