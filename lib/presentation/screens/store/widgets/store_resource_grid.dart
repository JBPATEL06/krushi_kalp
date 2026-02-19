import 'package:flutter/material.dart';
import '../../../../domain/models/resource.dart';
import '../../../../domain/models/offer.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../widgets/common/universal_item_card.dart';
import '../../../../utils/price_calculator.dart';

class StoreResourceGrid extends StatelessWidget {
  final List<Resource> resources;
  final List<Offer>? activeOffers;
  final Set<int> purchasedIds;
  final Set<int>
      cartItemIds; // Assuming we map resource IDs to int if possible, or string. Resource IDs are int.
  final Function(Resource) onBuyTap;
  final Function(Resource) onCartTap;
  final Function(Resource) onTap;
  final bool isWide; // For responsive layout

  const StoreResourceGrid({
    super.key,
    required this.resources,
    this.activeOffers,
    required this.purchasedIds,
    required this.cartItemIds,
    required this.onBuyTap,
    required this.onCartTap,
    required this.onTap,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    if (resources.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Center(child: Text("No items found in this category.")),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final resource = resources[index];
            final isInCart = cartItemIds.contains(resource.id);
            final isPurchased = purchasedIds.contains(resource.id); // NEW

            // Filter offers to only include 'Sale' offers (Auto-apply)
            final saleOffers = activeOffers?.where((o) => o.isSale).toList();

            // 1. Check for Direct Resource Discount (Supabase fields)
            double displayPrice = resource.price;
            double? mrp = resource.mrp;
            String? discountTag = resource.discount;

            // 2. If no direct discount, check for Coupons/Offers (PriceCalculator)
            // Only apply offer if there's no direct "fake price" set on the resource,
            // OR if valid offer provides BETTER price?
            // For now, let's assume resource.mrp/discount takes precedence for "visuals",
            // but PriceCalculator handles the actual "Sale" logic if we want to support coupons on resources too.
            // A simple approach:
            // If resource has MRP, show it.
            // If activeOffers exist, they might override price.

            if (activeOffers != null && activeOffers!.isNotEmpty) {
              final priceData = PriceCalculator.calculateDisplayPrice(
                basePrice: resource.price,
                activeOffers: saleOffers,
                resourceId: resource.id,
              );
              // If PriceCalculator found a deal, use it.
              if (priceData['offer'] != null) {
                displayPrice = priceData['finalPrice'];
                mrp = priceData[
                    'mrp']; // Calculator might set MRP same as basePrice if not specified
                final Offer offer = priceData['offer'];
                if (offer.discountType == 'PERCENTAGE') {
                  discountTag =
                      '${offer.discountValue.toStringAsFixed(0)}% OFF';
                } else {
                  discountTag =
                      '₹${offer.discountValue.toStringAsFixed(0)} OFF';
                }
              }
            } else {
              // No offers, just use Resource fields.
              // If MRP is missing but we have price, MRP = null (no strikethrough).
              // Calculate tag if missing
              if (discountTag == null && mrp != null && mrp > displayPrice) {
                final off = ((mrp - displayPrice) / mrp * 100).round();
                if (off > 0) discountTag = '$off% OFF';
              }
            }

            // Determine subtitle based on type
            String subtitle =
                resource.type.toString().split('.').last.toUpperCase();
            if (resource.category != null) {
              subtitle += ' • ${resource.category}';
            }

            return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: UniversalItemCard(
                  title: resource.title,
                  subtitle: subtitle,
                  price: displayPrice,
                  originalPrice: mrp,
                  discountTag: discountTag,
                  coverUrl: resource.thumbnailUrl,
                  actionLabel: isPurchased
                      ? 'Download'
                      : (displayPrice == 0 ? 'Claim' : 'Buy Now'),
                  isActionEnabled: true,
                  isInCart: isInCart,
                  isPurchased: isPurchased, // NEW
                  hideTags: isPurchased, // Hide purchased tag for cleaner look
                  onActionTap: () {
                    if (isPurchased) {
                      // Trigger Open/Download
                      onBuyTap(resource);
                    } else if (displayPrice == 0) {
                      onBuyTap(resource); // Claim
                    } else {
                      onBuyTap(resource); // Buy Now
                    }
                  },
                  onCartTap: () => onCartTap(resource), // Add to Cart
                  onTap: () => onTap(resource), // Open Detail
                  heroTag: 'store_resource_${resource.id}', // Unique Tag
                ));
          },
          childCount: resources.length,
        ),
      ),
    );
  }
}
