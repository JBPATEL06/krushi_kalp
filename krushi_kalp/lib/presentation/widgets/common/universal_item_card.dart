import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import 'responsive_wrapper.dart';

/// Universal horizontal card used across the entire app.
///
/// Layout:
///   ┌──────────────────────────────────────────────┐
///   │ [IMAGE]  │  Title                             │
///   │  fills   │  Subtitle / metadata               │
///   │ container│  Rating   │  Price  │  Action btn  │
///   └──────────────────────────────────────────────┘
///
/// The image pane uses [BoxFit.cover] inside a [ClipRRect] so the image
/// always fills its container – no empty space, no overflow.
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

  // ─── Image pane width as fraction of card height ──────────────────────────
  // The card height is fixed.  Image pane = 38% of card width.
  // Using AspectRatio(0.72) on the image pane gives a roughly portrait thumbnail.
  static const double _imagePaneAspect = 0.72; // width / height

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Widget card = Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: AppSpacing.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color:
              theme.colorScheme.outline.withValues(alpha: isDark ? 0.18 : 0.35),
        ),
      ),
      color: theme.colorScheme.surface,
      // clipBehavior ensures the image respects the card's rounded corners
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── LEFT: IMAGE PANE ──────────────────────────────────────────
              AspectRatio(
                aspectRatio: _imagePaneAspect,
                child: Hero(
                  // FIX #2: Use hashCode of title+coverUrl+price to ensure uniqueness.
                  // Previously 'uic_${title}_$price' caused crashes when two list
                  // items shared the same title AND price (e.g., two free tests).
                  tag: heroTag ?? 'uic_${Object.hash(title, coverUrl, price)}',
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image fills the pane completely – no letterboxing
                      _buildImage(context, theme),

                      // Discount badge
                      if (discountTag != null &&
                          discountTag!.isNotEmpty &&
                          !isPurchased)
                        Positioned(
                          top: AppSpacing.xs,
                          left: AppSpacing.xs,
                          child: _badge(
                            discountTag!,
                            background: theme.colorScheme.tertiary,
                            foreground: theme.colorScheme.onTertiary,
                            context: context,
                          ),
                        ),

                      // Purchased badge
                      if (isPurchased && !hideTags)
                        Positioned(
                          top: AppSpacing.xs,
                          left: AppSpacing.xs,
                          child: _badge(
                            'Purchased',
                            background: theme.colorScheme.primary,
                            foreground: theme.colorScheme.onPrimary,
                            context: context,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── RIGHT: CONTENT PANE ───────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title + subtitle block (top)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                              height: 1.25,
                              fontSize: context.sp(14),
                            ),
                          ),
                          if (subtitle != null) ...[
                            SizedBox(height: AppSpacing.xs),
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: context.sp(11),
                              ),
                            ),
                          ],
                          if (time != null) ...[
                            SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: context.sp(11),
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                SizedBox(width: AppSpacing.xs),
                                Text(
                                  time!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: context.sp(11),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),

                      // Rating row (middle-bottom)
                      if (rating != null && rating! > 0)
                        Row(
                          children: [
                            Icon(Icons.star_rounded,
                                size: context.sp(13),
                                color: theme.colorScheme.tertiary),
                            SizedBox(width: AppSpacing.xs),
                            Text(
                              rating!.toStringAsFixed(1),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.tertiary,
                                fontSize: context.sp(11),
                              ),
                            ),
                            if (reviewCount != null) ...[
                              SizedBox(width: AppSpacing.xs),
                              Text(
                                '($reviewCount)',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: context.sp(10),
                                ),
                              ),
                            ],
                          ],
                        ),

                      // Price + action row (bottom)
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          // Price block
                          if (!isPurchased && price >= 0)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (originalPrice != null &&
                                    originalPrice! > price)
                                  Text(
                                    '₹${originalPrice!.toStringAsFixed(0)}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: context.sp(10),
                                    ),
                                  ),
                                Text(
                                  price == 0
                                      ? 'Free'
                                      : '₹${price.toStringAsFixed(0)}',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: theme.colorScheme.primary,
                                    fontSize: context.sp(15),
                                  ),
                                ),
                              ],
                            )
                          else
                            const SizedBox.shrink(),

                          // Cart icon + action button row
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Cart icon – only for purchasable, non-owned items
                              if (onCartTap != null &&
                                  price > 0 &&
                                  !isPurchased)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      right: AppSpacing.xs),
                                  child: InkWell(
                                    onTap: onCartTap,
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusFull),
                                    child: Container(
                                      width: context.w(32),
                                      height: context.w(32),
                                      decoration: BoxDecoration(
                                        color: isInCart
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.primary
                                                .withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isInCart
                                            ? Icons.shopping_cart
                                            : Icons.shopping_cart_outlined,
                                        size: context.sp(16),
                                        color: isInCart
                                            ? theme.colorScheme.onPrimary
                                            : theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),

                              // Action button / custom action
                              SizedBox(
                                height: context.h(32),
                                child: customAction ??
                                    ElevatedButton(
                                      onPressed: isPurchased
                                          ? onTap
                                          : (isActionEnabled
                                              ? onActionTap
                                              : null),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isPurchased
                                            ? theme.colorScheme
                                                .surfaceContainerHighest
                                            : (actionColor ??
                                                (price == 0
                                                    ? theme.colorScheme.tertiary
                                                    : theme
                                                        .colorScheme.primary)),
                                        foregroundColor: isPurchased
                                            ? theme.colorScheme.onSurfaceVariant
                                            : theme.colorScheme.onPrimary,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: AppSpacing.md),
                                        shape: const StadiumBorder(),
                                        elevation: 0,
                                        visualDensity: VisualDensity.compact,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        isPurchased ? 'View' : actionLabel,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: context.sp(11),
                                        ),
                                      ),
                                    ),
                              ),
                            ],
                          ),

                          // Optional trailing widget
                          if (trailing != null) trailing!,
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

    if (!enableAnimation) return RepaintBoundary(child: card);

    // Light entrance animation when enabled
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
      child: card,
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  Widget _buildImage(BuildContext context, ThemeData theme) {
    if (coverUrl != null && coverUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: coverUrl!,
        // BoxFit.cover fills the container completely; no gaps, no overflow
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          child: Center(
            child: SizedBox(
              width: context.w(20),
              height: context.w(20),
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => _buildPlaceholder(context, theme),
      );
    }
    return _buildPlaceholder(context, theme);
  }

  Widget _buildPlaceholder(BuildContext context, ThemeData theme) {
    return Container(
      color: theme.colorScheme.primary.withValues(alpha: 0.06),
      child: Center(
        child: Icon(
          Icons.school_outlined,
          size: context.sp(32),
          color: theme.colorScheme.primary.withValues(alpha: 0.28),
        ),
      ),
    );
  }

  Widget _badge(
    String label, {
    required Color background,
    required Color foreground,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: context.sp(9),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
