import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../domain/models/review.dart';
import 'rate_stars.dart';

class ReviewCard extends StatelessWidget {
  final Review review;
  final bool isOwnReview;
  final VoidCallback? onEdit;

  const ReviewCard({
    super.key,
    required this.review,
    this.isOwnReview = false,
    this.onEdit,
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
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colorScheme.primaryContainer,
                  backgroundImage: review.userAvatarUrl != null
                      ? NetworkImage(review.userAvatarUrl!)
                      : null,
                  child: review.userAvatarUrl == null
                      ? Text(
                          review.userName[0].toUpperCase(),
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                // Name & Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        _formatDate(review.updatedAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                // Edit Action (if own review)
                if (isOwnReview)
                  IconButton(
                    icon: Icon(Icons.edit_rounded,
                        size: 20, color: colorScheme.primary),
                    onPressed: onEdit,
                    tooltip: 'Edit Review',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 20,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Rating
            RateStars(
              rating: review.rating,
              size: 16,
              color: const Color(0xFFFFC107), // Keep gold for stars as standard
            ),

            const SizedBox(height: AppSpacing.xs),

            // Review Text
            if (review.reviewText != null && review.reviewText!.isNotEmpty)
              Text(
                review.reviewText!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.85),
                  height: 1.5,
                ),
              )
            else
              Text(
                "No written feedback.",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
