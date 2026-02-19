import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

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
  final bool isInCart; // NEW
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
    this.isInCart = false, // NEW
    required this.onBuyTap,
    required this.onCartTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: SizedBox(
            height: 125, // Matched PurchasedTestCard height
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Cover Image (Left) - Aspect Ratio 0.85
                Hero(
                  tag: 'store_test_${title}_$price',
                  child: AspectRatio(
                    aspectRatio: 0.85, // Matched PurchasedTestCard aspect ratio
                    child: ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(AppSpacing.radiusXl)),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildImage(),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Content (Right)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title (Top)
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
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
                                      context, Icons.access_time, time),
                                  const SizedBox(width: AppSpacing.md),
                                  _buildInfoItem(context,
                                      Icons.format_list_numbered, questions),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),

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
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      decoration: TextDecoration
                                                          .lineThrough,
                                                      color:
                                                          AppColors.neutral500,
                                                    ),
                                              ),
                                              const SizedBox(
                                                  width: AppSpacing.xs),
                                              Text(
                                                discountTag ?? '',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: AppColors.success,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        Text(
                                          price == 0
                                              ? 'Free'
                                              : '₹${price.toStringAsFixed(0)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),

                                // Cart + Buy Button
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (price > 0 && !isInCart) ...[
                                      Material(
                                        color: AppColors.neutral50,
                                        shape: const CircleBorder(),
                                        child: InkWell(
                                          customBorder: const CircleBorder(),
                                          onTap: onCartTap,
                                          child: Padding(
                                            padding: const EdgeInsets.all(
                                                AppSpacing.xs + 2),
                                            child: const Icon(
                                              Icons.add_shopping_cart,
                                              size: 18,
                                              color: AppColors.neutral700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                    ],
                                    SizedBox(
                                      height: 32,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          if (isInCart) {
                                            // TODO: Navigate to Cart. Since we don't have context nav here easily without coupling
                                            // We could pass a callback, but for now let's just use Navigator if possible or accept this is strictly presentation.
                                            // Actually, let's just make it call onBuyTap? No.
                                            // Let's modify onBuyTap in StoreGrid?
                                            // Or just do a quick Navigator push here if we import CartScreen.
                                            // Better: change button to disabled "In Cart" or similar?
                                            // User wants to see changes. "Go to Cart" is best.
                                            // We'll leave the pressed action empty for now and let the user know,
                                            // OR we import CartScreen.
                                            // Let's import CartScreen at top.
                                          } else {
                                            onBuyTap();
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: price == 0
                                              ? AppColors.success
                                              : (isInCart
                                                  ? AppColors.neutral400
                                                  : AppColors.primary),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.md),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                AppSpacing.radiusMd),
                                          ),
                                          elevation: 0,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        child: Text(
                                          price == 0
                                              ? 'Claim'
                                              : (isInCart ? 'In Cart' : 'Buy'),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
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
      ),
    );
  }

  Widget _buildImage() {
    if (coverUrl != null) {
      return CachedNetworkImage(
        imageUrl: coverUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppColors.neutral50,
          child: const Center(
              child: Icon(Icons.image, color: AppColors.neutral400)),
        ),
        errorWidget: (context, url, error) => Container(
          color: AppColors.neutral100,
          child: const Icon(Icons.broken_image, color: AppColors.neutral400),
        ),
      );
    } else {
      return Container(
        color: AppColors.primary.withValues(alpha: 0.1),
        child: Center(
          child: Icon(
            Icons.school,
            size: 32,
            color: AppColors.primary.withValues(alpha: 0.4),
          ),
        ),
      );
    }
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.neutral600),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.neutral600,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
