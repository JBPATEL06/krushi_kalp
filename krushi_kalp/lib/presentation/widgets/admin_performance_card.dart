import 'package:flutter/material.dart';
import 'package:krushi_kalp/core/theme/app_radius.dart';
import 'package:krushi_kalp/core/theme/app_spacing.dart';
import 'package:krushi_kalp/presentation/widgets/common/responsive_wrapper.dart';

class AdminPerformanceCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isLoading;
  const AdminPerformanceCard(
      {required this.data, this.isLoading = false, super.key});

  // Safe getters — never crash on missing keys
  double get _todayRevenue => (data['today_revenue'] as num?)?.toDouble() ?? 0;
  int get _weeklyNewUsers => (data['weekly_new_users'] as num?)?.toInt() ?? 0;
  int get _testsSoldWeek => (data['tests_sold_week'] as num?)?.toInt() ?? 0;
  String get _topTestTitle => (data['top_test_title'] as String?) ?? 'N/A';
  int get _topTestAttempts => (data['top_test_attempts'] as num?)?.toInt() ?? 0;
  double get _platformAvgRating =>
      (data['platform_avg_rating'] as num?)?.toDouble() ?? 0;
  double get _completionRate =>
      (data['completion_rate'] as num?)?.toDouble() ?? 0;

  // Revenue formatting helper
  String get _revenueStr {
    if (_todayRevenue == _todayRevenue.truncateToDouble()) {
      return '₹${_todayRevenue.toInt()}';
    }
    return '₹${_todayRevenue.toStringAsFixed(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (isLoading) {
      return Container(
        height: context.h(200),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: isDark ? 0.2 : 0.4),
          ),
        ),
        child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF10B981))),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: isDark ? 0.2 : 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ADMIN PERFORMANCE CARD",
                style: TextStyle(
                  fontSize: context.sp(10),
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          // 2x2 metric grid
          Row(
            children: [
              _MetricChip(value: _revenueStr, label: "TODAY REVENUE"),
              SizedBox(width: AppSpacing.sm),
              _MetricChip(
                  value: '$_weeklyNewUsers', label: "NEW Users THIS WEEK"),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _MetricChip(
                  value: '$_testsSoldWeek', label: "Items SOLD THIS WEEK"),
              SizedBox(width: AppSpacing.sm),
              _MetricChip(
                  value: '⭐ ${_platformAvgRating.toStringAsFixed(1)}',
                  label: "RATING PLATFORM"),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Divider(color: colorScheme.outlineVariant, height: 1),
          SizedBox(height: AppSpacing.xs),
          // Bottom row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "MOST ATTEMPTED",
                      style: TextStyle(
                        fontSize: context.sp(9),
                        color: colorScheme.onSurfaceVariant,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      "$_topTestTitle · $_topTestAttempts attempts",
                      style: TextStyle(
                        fontSize: context.sp(11),
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "COMPLETION",
                    style: TextStyle(
                      fontSize: context.sp(9),
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    "${_completionRate.toStringAsFixed(1)}%",
                    style: TextStyle(
                      fontSize: context.sp(14),
                      color: const Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String value;
  final String label;
  const _MetricChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: context.sp(20),
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: context.sp(10),
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
