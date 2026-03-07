import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';

class StoreTestCard extends StatelessWidget {
  final String title;
  final String time;
  final String questions;
  final String marks;
  final double price;
  final double? originalPrice;
  final String? discountTag;
  final String? coverUrl;
  final bool hasNegativeMarking;
  final bool isInCart;
  final VoidCallback onBuyTap;
  final VoidCallback onCartTap;
  final VoidCallback? onTap;

  const StoreTestCard({
    super.key,
    required this.title,
    required this.time,
    required this.questions,
    required this.marks,
    required this.price,
    this.originalPrice,
    this.discountTag,
    this.coverUrl,
    required this.hasNegativeMarking,
    this.isInCart = false,
    required this.onBuyTap,
    required this.onCartTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
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
              // 1. Cover Image (Left)
              Hero(
                tag: 'store_test_${title}_$price',
                child: AspectRatio(
                  aspectRatio: 0.85,
                  child: ClipRRect(
                    borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(AppRadius.lg)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildImage(context),
                        if (hasNegativeMarking)
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.error.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '-1/4',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Content (Right)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title (Top)
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          height: 1.2,
                        ),
                      ),

                      // Bottom Section: Metadata + Price/Actions
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Metadata Row
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildInfoItem(
                                    context, Icons.access_time_rounded, time),
                                SizedBox(width: AppSpacing.md),
                                _buildInfoItem(
                                    context,
                                    Icons.format_list_numbered_rounded,
                                    questions),
                              ],
                            ),
                          ),
                          SizedBox(height: AppSpacing.sm),

                          // Price and Actions Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Price
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (originalPrice != null &&
                                          originalPrice! > price)
                                        Row(
                                          children: [
                                            Text(
                                              '₹${originalPrice!.toStringAsFixed(0)}',
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                color: colorScheme
                                                    .onSurfaceVariant
                                                    .withOpacity(0.6),
                                              ),
                                            ),
                                            SizedBox(width: AppSpacing.xs),
                                            Text(
                                              discountTag ?? '',
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                color: colorScheme.tertiary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      Text(
                                        price == 0
                                            ? 'Free'
                                            : '₹${price.toStringAsFixed(0)}',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: AppSpacing.sm),

                              // Cart + Buy Button
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (price > 0 && !isInCart) ...[
                                    Material(
                                      color: colorScheme.surfaceVariant
                                          .withOpacity(0.5),
                                      shape: const CircleBorder(),
                                      child: InkWell(
                                        customBorder: const CircleBorder(),
                                        onTap: onCartTap,
                                        child: Padding(
                                          padding: const EdgeInsets.all(6),
                                          child: Icon(
                                            Icons.add_shopping_cart_rounded,
                                            size: 16,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: AppSpacing.sm),
                                  ],
                                  SizedBox(
                                    height: 32,
                                    child: ElevatedButton(
                                      onPressed: isInCart ? null : onBuyTap,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: price == 0
                                            ? colorScheme.tertiary
                                            : colorScheme.primary,
                                        foregroundColor: colorScheme.onPrimary,
                                        disabledBackgroundColor: colorScheme
                                            .outline
                                            .withOpacity(0.2),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: AppSpacing.md),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.md),
                                        ),
                                        elevation: 0,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      child: Text(
                                        price == 0
                                            ? 'Claim'
                                            : (isInCart ? 'In Cart' : 'Buy'),
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isInCart
                                              ? colorScheme.onSurfaceVariant
                                              : colorScheme.onPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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

  Widget _buildImage(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (coverUrl != null) {
      return CachedNetworkImage(
        imageUrl: coverUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => Container(
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          child: Icon(Icons.broken_image_rounded,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
        ),
      );
    } else {
      return Container(
        color: colorScheme.primary.withOpacity(0.1),
        child: Center(
          child: Icon(
            Icons.school_rounded,
            size: 32,
            color: colorScheme.primary.withOpacity(0.4),
          ),
        ),
      );
    }
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
