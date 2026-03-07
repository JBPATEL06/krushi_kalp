import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import 'modern_card.dart';

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
  final bool enableAnimation;

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
    this.enableAnimation = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isPurchased && !hideTags) {
      return _buildPurchasedCard(context);
    }
    return _buildStandardCard(context);
  }

  Widget _buildPurchasedCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                    borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(AppRadius.lg)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildImage(context),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
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
                  padding: EdgeInsets.only(right: AppSpacing.sm),
                  child: trailing!,
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
            child: SizedBox(
              height: 54, // Increased from 48
              child: customAction ??
                  ElevatedButton.icon(
                    onPressed: isActionEnabled ? onActionTap : null,
                    icon: Icon(Icons.visibility_rounded,
                        size: 24,
                        color: colorScheme.onPrimary), // Increased from 20
                    label: Text(
                      actionLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        // Increased from labelLarge
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: actionColor ?? colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ModernCard(
      animate: enableAnimation,
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLarge = constraints.maxWidth > 400;
          return Container(
            constraints: BoxConstraints(
              minHeight: isLarge ? 160 : 180,
              maxHeight: isLarge ? 180 : 200,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Hero(
                  tag: heroTag ?? 'item_${title}_$price',
                  child: AspectRatio(
                    aspectRatio: 0.75,
                    child: ClipRRect(
                      borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(AppRadius.lg)),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildImage(context),
                          if (discountTag != null &&
                              discountTag!.isNotEmpty &&
                              !isPurchased)
                            Positioned(
                              top: AppSpacing.sm,
                              left: AppSpacing.sm,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.xs),
                                decoration: BoxDecoration(
                                  color: colorScheme.tertiary.withOpacity(0.95),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(
                                  discountTag!,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          if (isPurchased && !hideTags)
                            Positioned(
                              top: AppSpacing.sm,
                              left: AppSpacing.sm,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.xs),
                                decoration: BoxDecoration(
                                  color:
                                      colorScheme.secondary.withOpacity(0.95),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(
                                  'Purchased',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
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
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (subtitle != null || time != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (subtitle != null)
                                Text(
                                  subtitle!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (time != null) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Row(
                                  children: [
                                    Icon(Icons.access_time_rounded,
                                        size: 16, // Increased from 12
                                        color: colorScheme.onSurfaceVariant),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      time!,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        const SizedBox(height: 4),
                        if (rating != null && rating! > 0)
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.xs),
                            child: Row(
                              children: [
                                Text(
                                  rating!.toStringAsFixed(1),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    // Increased from TextStyle
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.star_rounded,
                                    size: 18,
                                    color:
                                        Color(0xFFFFC107)), // Increased from 14
                                if (reviewCount != null) ...[
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    '($reviewCount)',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      // Increased from bodySmall
                                      color: colorScheme.onSurfaceVariant,
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
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        decoration: TextDecoration.lineThrough,
                                        color: colorScheme.onSurfaceVariant
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                  Text(
                                    price == 0
                                        ? 'Free'
                                        : '₹${price.toStringAsFixed(0)}',
                                    style:
                                        theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              )
                            else
                              const Spacer(),
                            Row(
                              children: [
                                if (onCartTap != null &&
                                    price > 0 &&
                                    !isPurchased)
                                  Padding(
                                    padding:
                                        EdgeInsets.only(right: AppSpacing.sm),
                                    child: InkWell(
                                      onTap: onCartTap,
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.full),
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: isInCart
                                              ? colorScheme.primary
                                              : colorScheme.primary
                                                  .withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isInCart
                                              ? Icons.shopping_cart_rounded
                                              : Icons.shopping_cart_outlined,
                                          size: 16,
                                          color: isInCart
                                              ? colorScheme.onPrimary
                                              : colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                SizedBox(
                                  height: 38, // Increased from 32
                                  child: ElevatedButton(
                                    onPressed: isPurchased
                                        ? onTap
                                        : (isActionEnabled
                                            ? onActionTap
                                            : null),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isPurchased
                                          ? colorScheme.surfaceVariant
                                          : (actionColor ??
                                              (price == 0
                                                  ? colorScheme.tertiary
                                                  : colorScheme.primary)),
                                      foregroundColor: isPurchased
                                          ? colorScheme.onSurface
                                          : colorScheme.onPrimary,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.lg),
                                      shape: const StadiumBorder(),
                                      elevation: 0,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    child: Text(
                                      isPurchased ? 'View' : actionLabel,
                                      style:
                                          theme.textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
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
          );
        },
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (coverUrl != null && coverUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: coverUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          child: Center(
              child: Icon(Icons.image_rounded,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.5))),
        ),
        errorWidget: (context, url, error) => Container(
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          child: Icon(Icons.broken_image_rounded,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
        ),
      );
    } else {
      return Container(
        color: colorScheme.primary.withOpacity(0.05),
        child: Center(
          child: Icon(
            Icons.school_rounded,
            size: 32,
            color: colorScheme.primary.withOpacity(0.3),
          ),
        ),
      );
    }
  }
}
