import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/models/mock_test.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final imageUrl = test.signedUrl ?? test.coverImagePath;

    return Card(
      elevation: 0,
      margin:
          const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: 2),
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          height: 125,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- LEFT IMAGE SECTION ---
              Hero(
                tag: heroTag ?? 'purchased_test_${test.id}',
                child: AspectRatio(
                  aspectRatio: 0.85,
                  child: ClipRRect(
                    borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(AppRadius.lg)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (imageUrl != null)
                          CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color:
                                  colorScheme.surfaceVariant.withOpacity(0.3),
                              child: const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                                color: colorScheme.surfaceVariant
                                    .withOpacity(0.3)),
                          )
                        else
                          Container(
                              color:
                                  colorScheme.surfaceVariant.withOpacity(0.3)),
                      ],
                    ),
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
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                          color: colorScheme.onSurface,
                        ),
                      ),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildInfoItem(context, Icons.access_time_rounded,
                                  test.time),
                              const SizedBox(width: AppSpacing.md),
                              _buildInfoItem(
                                context,
                                Icons.help_outline_rounded,
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
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg,
                                  ),
                                  shape: StadiumBorder(),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Start Test',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onPrimary,
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
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
