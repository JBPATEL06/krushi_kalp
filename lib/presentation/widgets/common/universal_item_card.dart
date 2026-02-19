import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'modern_card.dart'; // Import ModernCard

class UniversalItemCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? time;
  final double price;
  final double? originalPrice;
  final String? discountTag;
  final String? coverUrl;
  final String actionLabel;
  final VoidCallback? onActionTap;
  final VoidCallback onTap;

  final bool isActionEnabled;
  final Color? actionColor;
  final VoidCallback? onCartTap;
  final bool isInCart;
  final bool isPurchased;
  final bool hideTags;
  final Widget? trailing;

  final double? rating;
  final int? reviewCount;

  final String? heroTag;
  final Widget? customAction;
  final bool enableAnimation; // New property

  const UniversalItemCard({
    super.key,
    required this.title,
    this.subtitle,
    this.time,
    required this.price,
    this.originalPrice,
    this.discountTag,
    this.coverUrl,
    this.actionLabel = 'View',
    this.onActionTap,
    required this.onTap,
    this.isActionEnabled = true,
    this.actionColor,
    this.onCartTap,
    this.isInCart = false,
    this.isPurchased = false,
    this.hideTags = false,
    this.trailing,
    this.rating,
    this.reviewCount,
    this.heroTag,
    this.customAction,
    this.enableAnimation =
        false, // Default false to avoid double animation in grids
  });

  @override
  Widget build(BuildContext context) {
    if (isPurchased && !hideTags) {
      return _buildPurchasedCard(context);
    }
    return _buildStandardCard(context);
  }

  Widget _buildPurchasedCard(BuildContext context) {
    return ModernCard(
      animate: enableAnimation,
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Hero(
                tag: heroTag ?? 'item_${title}_$price',
                child: SizedBox(
                  width: 100,
                  height: 140,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16)), // Match ModernCard radius
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildImage(),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                      const SizedBox(height: AppSpacing.xs),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
              if (trailing != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: trailing!,
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
            child: SizedBox(
              height: 48,
              child: customAction ??
                  ElevatedButton.icon(
                    onPressed: isActionEnabled ? onActionTap : null,
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                    label: Text(
                      actionLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: actionColor ?? AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      elevation: 0,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardCard(BuildContext context) {
    return ModernCard(
      animate: enableAnimation,
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 155,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hero(
              tag: heroTag ?? 'item_${title}_$price',
              child: AspectRatio(
                aspectRatio: 0.75,
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(16)), // Match ModernCard radius
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImage(),
                      if (discountTag != null &&
                          discountTag!.isNotEmpty &&
                          !isPurchased)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              discountTag!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      if (isPurchased && !hideTags)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Purchased',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            height: 1.2,
                          ),
                    ),
                    if (subtitle != null || time != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (time != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.access_time,
                                    size: 12, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  time!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    const SizedBox(height: 8),
                    if (rating != null && rating! > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text(
                              rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.neutral700,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.star_rounded,
                                size: 14, color: Color(0xFFFFC107)),
                            if (reviewCount != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                '($reviewCount)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.neutral500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isPurchased && price >= 0)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (originalPrice != null &&
                                  originalPrice! > price)
                                Text(
                                  '₹${originalPrice!.toStringAsFixed(0)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        decoration: TextDecoration.lineThrough,
                                        color: AppColors.textSecondary,
                                        fontSize: 10,
                                      ),
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
                                      color: AppColors.primary,
                                      fontSize: 18,
                                    ),
                              ),
                            ],
                          )
                        else if (isPurchased)
                          const SizedBox()
                        else
                          const SizedBox(),
                        Row(
                          children: [
                            if (onCartTap != null && price > 0 && !isPurchased)
                              Padding(
                                padding:
                                    const EdgeInsets.only(right: AppSpacing.sm),
                                child: InkWell(
                                  onTap: onCartTap,
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isInCart
                                          ? AppColors.primary
                                          : AppColors.primary
                                              .withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isInCart
                                          ? Icons.shopping_cart
                                          : Icons.shopping_cart_outlined,
                                      size: 18,
                                      color: isInCart
                                          ? Colors.white
                                          : AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            SizedBox(
                              height: 36,
                              child: ElevatedButton(
                                onPressed: isPurchased
                                    ? onTap
                                    : (isActionEnabled ? onActionTap : null),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isPurchased
                                      ? Colors.grey[300]
                                      : (actionColor ??
                                          (price == 0
                                              ? AppColors.success
                                              : AppColors.primary)),
                                  foregroundColor: isPurchased
                                      ? AppColors.textPrimary
                                      : Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg),
                                  shape: const StadiumBorder(),
                                  elevation: 0,
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: Text(
                                  isPurchased ? 'View' : actionLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
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
              ),
            ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: trailing!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (coverUrl != null && coverUrl!.isNotEmpty) {
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
        color: AppColors.primary.withValues(alpha: 0.05),
        child: Center(
          child: Icon(
            Icons.school_outlined,
            size: 32,
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
      );
    }
  }
}
