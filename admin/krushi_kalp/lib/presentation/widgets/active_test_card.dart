import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';

enum TestStatus { running, newTest, evaluated }

class ActiveTestCard extends StatelessWidget {
  final String category;
  final String title;
  final String subtitle;
  final TestStatus status;
  final VoidCallback onTap;
  final String? time;
  final int? questionCount;
  final String? imageUrl;

  const ActiveTestCard({
    super.key,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onTap,
    this.time,
    this.questionCount,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon Container OR Image
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  width: 60,
                  height: 60,
                  color: _getIconBackgroundColor(colorScheme, status),
                  child: imageUrl != null && imageUrl!.isNotEmpty
                      ? Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                _getIconData(status),
                                color: _getIconColor(colorScheme, status),
                                size: 28,
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Icon(
                            _getIconData(status),
                            color: _getIconColor(colorScheme, status),
                            size: 28,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (status == TestStatus.newTest) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color:
                                colorScheme.onSurfaceVariant.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            time ?? '',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color:
                                  colorScheme.onSurfaceVariant.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.list_alt_rounded,
                            size: 14,
                            color:
                                colorScheme.onSurfaceVariant.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${questionCount ?? 0} Qs',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color:
                                  colorScheme.onSurfaceVariant.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (status == TestStatus.evaluated) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: colorScheme.tertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Evaluated Recently',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.tertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Action Button
              _buildActionButton(context, status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, TestStatus status) {
    final colorScheme = Theme.of(context).colorScheme;

    IconData icon;
    Color bgColor;
    Color iconColor;

    switch (status) {
      case TestStatus.running:
        icon = Icons.play_arrow_rounded;
        bgColor = colorScheme.primary;
        iconColor = colorScheme.onPrimary;
        break;
      case TestStatus.newTest:
        icon = Icons.arrow_forward_rounded;
        bgColor = colorScheme.surfaceVariant.withOpacity(0.5);
        iconColor = colorScheme.primary;
        break;
      case TestStatus.evaluated:
        icon = Icons.analytics_rounded;
        bgColor = colorScheme.tertiaryContainer.withOpacity(0.5);
        iconColor = colorScheme.tertiary;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }

  Color _getIconBackgroundColor(ColorScheme colorScheme, TestStatus status) {
    switch (status) {
      case TestStatus.running:
        return colorScheme.primary.withOpacity(0.1);
      case TestStatus.newTest:
        return colorScheme.secondary.withOpacity(0.1);
      case TestStatus.evaluated:
        return colorScheme.tertiary.withOpacity(0.1);
    }
  }

  Color _getIconColor(ColorScheme colorScheme, TestStatus status) {
    switch (status) {
      case TestStatus.running:
        return colorScheme.primary;
      case TestStatus.newTest:
        return colorScheme.secondary;
      case TestStatus.evaluated:
        return colorScheme.tertiary;
    }
  }

  IconData _getIconData(TestStatus status) {
    switch (status) {
      case TestStatus.running:
        return Icons.menu_book_rounded;
      case TestStatus.newTest:
        return Icons.edit_note_rounded;
      case TestStatus.evaluated:
        return Icons.task_alt_rounded;
    }
  }
}
