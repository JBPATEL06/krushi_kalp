import 'package:flutter/material.dart';
import '../../../../domain/models/offer.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../widgets/common/responsive_wrapper.dart';
import '../../../widgets/common/modern_card.dart';

class CartItemWidget extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onRemove;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final title = item['title'] ?? 'Mock Test';
    final category = item['subtitle'] ?? 'General';
    final imageUrl = item['image_url'];
    final double currentPrice = (item['price'] as num).toDouble();
    final double? mrp = (item['mrp'] as num?)?.toDouble();

    // Check for applied offer (passed from CartScreen -> TestService stream)
    Offer? appliedOffer;
    final offersData = item['offers'];
    if (offersData != null && offersData is Map && offersData.isNotEmpty) {
      try {
        appliedOffer = Offer.fromJson(Map<String, dynamic>.from(offersData));
      } catch (_) {}
    }

    // Calculate final price for this item
    double finalItemPrice = currentPrice;

    if (appliedOffer != null) {
      final discount = appliedOffer.calculateDiscountAmount(
        totalAmount: currentPrice,
        cartItems: [
          {'test_id': item['test_id'], 'price': currentPrice}
        ],
      );
      finalItemPrice = (currentPrice - discount).clamp(0.0, double.infinity);
    }

    // Determine Strikethrough Price (MRP takes precedence, else Base Price if Coupon applied)
    final double strikethroughPrice = mrp ?? currentPrice;
    final bool isDiscounted = strikethroughPrice > finalItemPrice;

    final theme = Theme.of(context);
    return ModernCard(
      margin: EdgeInsets.only(bottom: context.h(AppSpacing.md)),
      padding: EdgeInsets.all(context.w(AppSpacing.md)),
      child: Row(
        children: [
          // Square Thumbnail
          Container(
            width: context.w(80),
            height: context.w(80),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius:
                  BorderRadius.circular(context.w(AppSpacing.radiusMd)),
              image: imageUrl != null && imageUrl.startsWith('http')
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: (imageUrl == null || !imageUrl.startsWith('http'))
                ? Icon(Icons.school_outlined,
                    size: context.w(30),
                    color: theme.colorScheme.onSurfaceVariant)
                : null,
          ),
          SizedBox(width: context.w(AppSpacing.lg)),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    fontSize: context.sp(16),
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: context.h(4)),
                Text(
                  category,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: context.sp(13),
                  ),
                ),
                SizedBox(height: context.h(8)),

                // Price Row
                Row(
                  children: [
                    if (isDiscounted) ...[
                      Text("₹${strikethroughPrice.toStringAsFixed(0)}",
                          style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                              fontSize: context.sp(12))),
                      SizedBox(width: context.w(6)),
                    ],
                    Text(
                      '₹${finalItemPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: context.sp(16),
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Delete Button (Subtle)
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                color: theme.colorScheme.error.withValues(alpha: 0.7),
                size: context.sp(22)),
            onPressed: onRemove,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
