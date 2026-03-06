import 'package:flutter/material.dart';
import '../../../../domain/models/resource.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../domain/models/offer.dart';
import '../../../../core/theme/app_spacing.dart';
import 'store_item_card.dart';
import '../../../../utils/price_calculator.dart';
import '../../../../data/services/review_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/common/download_action_button.dart';
import '../../../widgets/common/responsive_wrapper.dart';

class StoreResourceGrid extends StatefulWidget {
  final List<Resource> resources;
  final List<Offer>? activeOffers;
  final Set<int> purchasedIds;
  final Set<int> cartItemIds;
  final Function(Resource) onBuyTap;
  final Function(Resource) onCartTap;
  final Function(Resource) onTap;
  final bool isWide;

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
  State<StoreResourceGrid> createState() => _StoreResourceGridState();
}

class _StoreResourceGridState extends State<StoreResourceGrid> {
  // Cache: resourceId -> {average: double, count: int}
  final Map<int, Map<String, dynamic>> _ratingsCache = {};

  @override
  void initState() {
    super.initState();
    _fetchAllRatings();
  }

  @override
  void didUpdateWidget(StoreResourceGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resources != widget.resources) {
      _fetchAllRatings();
    }
  }

  Future<void> _fetchAllRatings() async {
    // Only fetch IDs not already in cache
    final uncachedIds = widget.resources
        .map((r) => r.id)
        .where((id) => !_ratingsCache.containsKey(id))
        .toList();

    if (uncachedIds.isEmpty) return;

    try {
      final bulk =
          await ReviewService.getBulkRatingStats(uncachedIds, 'resource');
      if (mounted) {
        setState(() => _ratingsCache.addAll(bulk));
      }
    } catch (_) {
      // Silently skip — cards will render without ratings
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.resources.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Center(child: Text("No items found in this category.")),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: context.w(AppSpacing.lg)),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final resource = widget.resources[index];
            return Padding(
              padding: EdgeInsets.only(bottom: context.h(AppSpacing.md)),
              child: _buildCard(context, resource),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
          },
          childCount: widget.resources.length,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, Resource resource) {
    final isInCart = widget.cartItemIds.contains(resource.id);
    final isPurchased = widget.purchasedIds.contains(resource.id);

    final saleOffers = widget.activeOffers?.where((o) => o.isSale).toList();

    double displayPrice = resource.price;
    double? mrp = resource.mrp;
    String? discountTag = resource.discount;

    if (widget.activeOffers != null && widget.activeOffers!.isNotEmpty) {
      final priceData = PriceCalculator.calculateDisplayPrice(
        basePrice: resource.price,
        activeOffers: saleOffers,
        resourceId: resource.id,
      );
      if (priceData['offer'] != null) {
        displayPrice = priceData['finalPrice'];
        mrp = priceData['mrp'];
        final Offer offer = priceData['offer'];
        if (offer.discountType == 'PERCENTAGE') {
          discountTag = '${offer.discountValue.toStringAsFixed(0)}% OFF';
        } else {
          discountTag = '₹${offer.discountValue.toStringAsFixed(0)} OFF';
        }
      }
    } else {
      if (discountTag == null && mrp != null && mrp > displayPrice) {
        final off = ((mrp - displayPrice) / mrp * 100).round();
        if (off > 0) discountTag = '$off% OFF';
      }
    }

    String subtitle = resource.type.toString().split('.').last.toUpperCase();
    if (resource.category != null) {
      subtitle += ' • ${resource.category}';
    }

    // Use cached ratings instead of FutureBuilder
    final cachedRating = _ratingsCache[resource.id];
    double? rating;
    int? count;
    if (cachedRating != null) {
      rating = cachedRating['average'] as double;
      count = cachedRating['count'] as int;
      if (count == 0) {
        rating = null;
        count = null;
      }
    }

    return StoreItemCard(
      title: resource.title,
      subtitle: subtitle,
      price: displayPrice,
      originalPrice: mrp,
      discountTag: discountTag,
      coverUrl: resource.thumbnailUrl,
      actionLabel:
          isPurchased ? 'Download' : (displayPrice == 0 ? 'Claim' : 'Buy Now'),
      customAction: isPurchased
          ? DownloadActionButton(
              filename: 'resource_${resource.id}.pdf',
              url: resource.fileUrl,
              startLabel: "Open",
              isFullWidth: false,
              userId: AuthService.instance.currentUser?.id,
              onAction: () async {
                widget.onBuyTap(resource);
              },
            )
          : null,
      isActionEnabled: true,
      isInCart: isInCart,
      isPurchased: isPurchased,
      hideTags: isPurchased,
      rating: rating,
      reviewCount: count,
      onActionTap: () {
        if (isPurchased) {
          widget.onBuyTap(resource);
        } else if (displayPrice == 0) {
          widget.onBuyTap(resource);
        } else {
          widget.onBuyTap(resource);
        }
      },
      onCartTap: () => widget.onCartTap(resource),
      onTap: () => widget.onTap(resource),
      heroTag: 'store_resource_${resource.id}',
    );
  }
}
