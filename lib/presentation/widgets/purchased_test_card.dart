import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/models/mock_test.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class PurchasedTestCard extends StatelessWidget {
  final MockTest test;
  final VoidCallback onTap;
  final VoidCallback onStartTap;
  final String? heroTag;

  const PurchasedTestCard({
    super.key,
    required this.test,
    required this.onTap,
    required this.onStartTap,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    // Determine Image URL
    final imageUrl = test.signedUrl ?? test.coverImagePath;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 125, // Fixed height for consistency
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- LEFT IMAGE SECTION ---
                Hero(
                  tag: heroTag ?? 'purchased_test_${test.id}',
                  child: AspectRatio(
                    aspectRatio: 0.85, // Fixed aspect ratio
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (imageUrl != null)
                          CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.neutral200,
                              child: const Center(
                                child: Icon(Icons.image,
                                    size: 20, color: AppColors.neutral400),
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                Container(color: AppColors.neutral200),
                          )
                        else
                          Container(color: AppColors.neutral200),
                      ],
                    ),
                  ),
                ),

                // --- RIGHT CONTENT SECTION ---
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title
                        Text(
                          test.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                        ),
                        // spacing handled by mainAxisAlignment: spaceBetween
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _buildInfoItem(
                                    context, Icons.access_time, test.time),
                                const SizedBox(width: AppSpacing.md),
                                _buildInfoItem(
                                  context,
                                  Icons.help_outline,
                                  '${test.totalQuestions} Qs',
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            // Bottom Row: Start Button
                            Align(
                              alignment: Alignment.centerRight,
                              child: SizedBox(
                                height: 32,
                                child: ElevatedButton(
                                  onPressed: onStartTap,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg,
                                      vertical:
                                          0, // Height controlled by SizedBox
                                    ),
                                    shape: const StadiumBorder(), // Pill Shape
                                    elevation: 2,
                                    shadowColor: AppColors.primary
                                        .withValues(alpha: 0.3),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Start Test',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_forward_rounded,
                                          size: 14),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.neutral500),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.neutral500,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
