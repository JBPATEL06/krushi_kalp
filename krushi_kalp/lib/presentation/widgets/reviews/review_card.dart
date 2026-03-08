import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/review.dart';
import 'rate_stars.dart';

class ReviewCard extends StatelessWidget {
  final Review review;
  final bool isOwnReview;
  final VoidCallback? onEdit;
  final bool isFlat; // New flag for the elegant flat layout

  const ReviewCard({
    super.key,
    required this.review,
    this.isOwnReview = false,
    this.onEdit,
    this.isFlat = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: isFlat ? AppSpacing.lg : AppSpacing.md),
      padding: isFlat ? EdgeInsets.zero : const EdgeInsets.all(AppSpacing.md),
      decoration: isFlat
          ? null
          : BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: theme.colorScheme.outlineVariant),
              boxShadow: [
                if (theme.brightness == Brightness.light)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                backgroundImage: review.userAvatarUrl != null
                    ? NetworkImage(review.userAvatarUrl!)
                    : null,
                child: Text(
                  review.userName[0].toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Name & Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      _formatDate(review.updatedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Edit Action (if own review)
              if (isOwnReview)
                IconButton(
                  icon: Icon(Icons.edit,
                      size: 18, color: theme.colorScheme.primary),
                  onPressed: onEdit,
                  tooltip: 'Edit Review',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Rating
          RateStars(
            rating: review.rating,
            size: 16,
            color: theme.colorScheme.secondary,
          ),

          const SizedBox(height: AppSpacing.xs),

          // Review Text
          if (review.reviewText != null && review.reviewText!.isNotEmpty)
            Text(
              review.reviewText!,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
                fontSize: 14,
              ),
            )
          else
            Text(
              "No written feedback.",
              style: TextStyle(
                color: theme.colorScheme.outlineVariant,
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
