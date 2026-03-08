import 'package:flutter/material.dart';
import 'common/responsive_wrapper.dart';

enum TestStatus { running, newTest, evaluated }

class ActiveTestCard extends StatelessWidget {
  final String category;
  final String title;
  final String subtitle; // e.g., "IELTS Academic • Advanced"
  final TestStatus status;
  final VoidCallback onTap;

  // Specific fields for design
  final String? time;
  final int? questionCount;
  final String? imageUrl; // NEW

  const ActiveTestCard({
    super.key,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onTap,
    this.time,
    this.questionCount,
    this.imageUrl, // NEW
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: context.h(16)),
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(context.w(16)),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ), // Slim Primary Border

        boxShadow: [
          if (Theme.of(context).brightness == Brightness.light)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Container OR Image
          // Icon Container OR Image
          ClipRRect(
            borderRadius: BorderRadius.circular(context.w(12)),
            child: Container(
              width: context.w(60),
              height: context.w(60),
              color: _getIconBackgroundColor(context, status),
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            _getIconData(status),
                            color: _getIconColor(context, status),
                            size: 28,
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Icon(
                        _getIconData(status),
                        color: _getIconColor(context, status),
                        size: 28,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: context.sp(16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: context.sp(13)),
                ),
                if (status == TestStatus.newTest) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        time ?? '',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.list,
                          size: 14,
                          color: Theme.of(context).colorScheme.outlineVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${questionCount ?? 0} Questions',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            fontSize: context.sp(12)),
                      ),
                    ],
                  ),
                ],
                if (status == TestStatus.evaluated) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Evaluated Yesterday',
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: context.sp(12)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Action Button
          if (status == TestStatus.running)
            _buildPlayButton(context)
          else if (status == TestStatus.newTest)
            _buildArrowButton(context)
          else
            _buildChartButton(context),
        ],
      ),
    );
  }

  Widget _buildPlayButton(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: context.w(40),
        height: context.w(40),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.primary,
        ),
        child: Icon(Icons.play_arrow,
            color: Theme.of(context).colorScheme.onPrimary,
            size: context.sp(24)),
      ),
    );
  }

  Widget _buildArrowButton(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: context.w(36),
        height: context.w(36),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Icon(Icons.arrow_forward,
            size: context.sp(18),
            color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildChartButton(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: context.w(36),
        height: context.w(36),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Icon(Icons.picture_as_pdf,
            size: context.sp(18),
            color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }

  Color _getIconBackgroundColor(BuildContext context, TestStatus status) {
    final theme = Theme.of(context);
    switch (status) {
      case TestStatus.running:
        return theme.colorScheme.primaryContainer.withValues(alpha: 0.5);
      case TestStatus.newTest:
        return theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5);
      case TestStatus.evaluated:
        return theme.colorScheme.secondaryContainer.withValues(alpha: 0.5);
    }
  }

  Color _getIconColor(BuildContext context, TestStatus status) {
    final theme = Theme.of(context);
    switch (status) {
      case TestStatus.running:
        return theme.colorScheme.primary;
      case TestStatus.newTest:
        return theme.colorScheme.tertiary;
      case TestStatus.evaluated:
        return theme.colorScheme.secondary;
    }
  }

  IconData _getIconData(TestStatus status) {
    switch (status) {
      case TestStatus.running:
        return Icons.menu_book;
      case TestStatus.newTest:
        return Icons.edit_note;
      case TestStatus.evaluated:
        return Icons.task_alt;
    }
  }
}
// ... (Separate chunk for Action Button if needed, but wait, need to check where _buildChartButton is using icon)
