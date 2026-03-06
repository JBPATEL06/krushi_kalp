import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../widgets/common/responsive_wrapper.dart';

/// Store-screen item card.
///
/// Layout (horizontal):
///   ┌──────────────────────────────────────────────────────┐
///   │        │  [subtitle / category label]    [🛒 top-rt] │
///   │ IMAGE  │  Title sp(18)                               │
///   │ covers │  ★ rating                                   │
///   │ pane   │  ₹399  ₹799                                 │
///   │        │  [       BUY NOW — full width        ]      │
///   └──────────────────────────────────────────────────────┘
class StoreItemCard extends StatelessWidget {
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

  const StoreItemCard({
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Badges definitions
    final bool hasBadge =
        (discountTag != null && discountTag!.isNotEmpty && !isPurchased) ||
            (isPurchased && !hideTags);
    final String badgeLabel = isPurchased ? 'Purchased' : (discountTag ?? '');
    final Color badgeBg =
        isPurchased ? theme.colorScheme.primary : theme.colorScheme.tertiary;
    final Color badgeFg = isPurchased
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onTertiary;

    final bool showCart = onCartTap != null && price > 0 && !isPurchased;

    // ── Internal Card (Layout MATCHING the provided reference image) ─────
    Widget card = Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(isDark ? 0.18 : 0.35),
        ),
      ),
      color: theme.colorScheme.surface,
      surfaceTintColor: theme.colorScheme.surfaceTint,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(context.w(AppSpacing.md)),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Wrap content vertically
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── TOP SECTION: IMAGE & TEXT ROW ──────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  Container(
                    width: context.w(110),
                    height:
                        context.h(135), // Approximately cover book aspect ratio
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: heroTag ?? 'sic_${title}_$price',
                          child: _buildImage(context, theme),
                        ),
                        if (hasBadge)
                          Positioned(
                            top: context.h(6),
                            left: context.w(6),
                            child: _badge(
                              badgeLabel,
                              bg: badgeBg, // Using standard badgeBg
                              fg: badgeFg, // Using badgeFg to clear the lint
                              context: context,
                            ),
                          ),
                      ],
                    ),
                  ),

                  SizedBox(width: context.w(AppSpacing.md)),

                  // Text details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: context.h(AppSpacing.xs)),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color:
                                theme.colorScheme.onSurface, // dark blue/black
                            fontSize: context.sp(18), // +2
                            height: 1.2,
                          ),
                        ),
                        if (subtitle != null) ...[
                          SizedBox(height: context.h(4)),
                          Text(
                            subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                              fontSize: context.sp(14), // +2
                            ),
                          ),
                        ],
                        SizedBox(height: context.h(AppSpacing.md)),

                        // Pricing block
                        if (!isPurchased)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (originalPrice != null &&
                                  originalPrice! > price)
                                Text(
                                  '₹${originalPrice!.toStringAsFixed(0)}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: theme.colorScheme.outline,
                                    fontWeight: FontWeight.w600,
                                    fontSize: context.sp(14), // +2
                                  ),
                                ),
                              Text(
                                price == 0
                                    ? 'Free'
                                    : '₹${price.toStringAsFixed(0)}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme
                                      .primary, // typical vibrant blue
                                  fontSize: context.sp(24), // +2
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            'Owned',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w800,
                              fontSize: context.sp(16), // +2
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: context.h(AppSpacing.lg)),

              // ── BOTTOM SECTION: ACTION BUTTONS ROW ─────────────────────
              Row(
                children: [
                  // Cart Button
                  if (showCart) ...[
                    Material(
                      color: theme.colorScheme.primary
                          .withOpacity(0.08), // Light faded primary background
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: InkWell(
                        onTap: onCartTap,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Container(
                          width: context.h(44), // Square cart button
                          height: context.h(44),
                          alignment: Alignment.center,
                          child: Icon(
                            isInCart
                                ? Icons.shopping_cart
                                : Icons.add_shopping_cart,
                            size: context.sp(22), // +2
                            color:
                                theme.colorScheme.primary, // Primary icon color
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: context.w(AppSpacing.md)),
                  ],

                  // Buy / Primary Action Button
                  Expanded(
                    child: SizedBox(
                      height: context.h(44),
                      child: customAction ??
                          ElevatedButton(
                            onPressed: isPurchased
                                ? onTap
                                : (isActionEnabled ? onActionTap : null),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isPurchased
                                  ? theme.colorScheme.surfaceVariant
                                  : (actionColor ??
                                      (price == 0
                                          ? theme.colorScheme.tertiary
                                          : theme.colorScheme
                                              .primary)), // Typical bright primary
                              foregroundColor: isPurchased
                                  ? theme.colorScheme.onSurfaceVariant
                                  : theme.colorScheme.onPrimary, // White text
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              isPurchased ? 'View' : actionLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isPurchased
                                    ? theme.colorScheme.onSurfaceVariant
                                    : theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: context.sp(16), // +2
                                letterSpacing: 0.5,
                              ),
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
    );

    if (!enableAnimation) return card;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child:
            Transform.translate(offset: Offset(0, 10 * (1 - v)), child: child),
      ),
      child: card,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildImage(BuildContext context, ThemeData theme) {
    if (coverUrl != null && coverUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: coverUrl!,
        fit: BoxFit.contain, // Fit fully within the container dimensions
        placeholder: (_, __) => _placeholder(context, theme, loading: true),
        errorWidget: (_, __, ___) => _placeholder(context, theme),
      );
    }
    return _placeholder(context, theme);
  }

  Widget _placeholder(BuildContext context, ThemeData theme,
      {bool loading = false}) {
    return Container(
      color: theme.colorScheme.primary.withOpacity(0.06),
      child: Center(
        child: loading
            ? SizedBox(
                width: context.w(20),
                height: context.w(20),
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: theme.colorScheme.primary.withOpacity(0.35),
                ),
              )
            : Icon(
                Icons.school_outlined,
                size: context.sp(30),
                color: theme.colorScheme.primary.withOpacity(0.25),
              ),
      ),
    );
  }

  Widget _badge(
    String label, {
    required Color bg,
    required Color fg,
    required BuildContext context,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(10),
        vertical: context.h(4),
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: bg.withOpacity(0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: context.sp(13), // +2
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
