import 'package:flutter/material.dart';
import '../../../../domain/models/resource.dart';
import '../../../../domain/models/offer.dart';
import '../../../../core/theme/app_spacing.dart';
import 'store_item_card.dart';
import '../../../../data/services/offer_service.dart';
import '../../../../data/services/review_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/common/download_action_button.dart';
import '../../../widgets/common/responsive_wrapper.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_notifier.dart';
import '../../../providers/resource_notifier.dart';
import '../../../providers/test_notifier.dart';

class StoreResourceGrid extends ConsumerStatefulWidget {
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
  ConsumerState<StoreResourceGrid> createState() => _StoreResourceGridState();
}

class _StoreResourceGridState extends ConsumerState<StoreResourceGrid> {
  final Map<int, Map<String, dynamic>> _ratingsCache = {};
  final Map<int, Map<String, dynamic>> _pricesCache = {};

  @override
  void initState() {
    super.initState();
    _fetchAllRatings();
    _fetchAllPrices();
  }

  @override
  void didUpdateWidget(StoreResourceGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resources != widget.resources) {
      _fetchAllRatings();
      _fetchAllPrices();
    }
  }

  Future<void> _fetchAllRatings() async {
    final uncachedIds = widget.resources
        .map((r) => r.id)
        .where((id) => !_ratingsCache.containsKey(id))
        .toList();
    if (uncachedIds.isEmpty) return;
    try {
      final bulk =
          await ReviewService.getBulkRatingStats(uncachedIds, 'resource');
      if (mounted) setState(() => _ratingsCache.addAll(bulk));
    } catch (_) {
      // Silently skip â€” cards will render without ratings
    }
  }

  Future<void> _fetchAllPrices() async {
    final uncached = widget.resources
        .where((r) => !_pricesCache.containsKey(r.id))
        .toList();
    if (uncached.isEmpty) return;

    // Process in batches of 5 to avoid overwhelming the network and Supabase
    const int batchSize = 5;
    for (int i = 0; i < uncached.length; i += batchSize) {
      if (!mounted) break;

      final end = (i + batchSize < uncached.length) ? i + batchSize : uncached.length;
      final batch = uncached.sublist(i, end);

      try {
        final results = await Future.wait(
          batch.map((r) => OfferService.instance.getDisplayPrice(
            itemType: 'resource',
            itemId: r.id,
          )),
        );

        if (mounted) {
          setState(() {
            for (int j = 0; j < batch.length; j++) {
              _pricesCache[batch[j].id] = results[j];
            }
          });
        }
      } catch (e) {
        debugPrint('StoreResourceGrid: Batch price fetch failed at index $i - $e');
        // Continue to next batch
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.resources.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("No items found in this category."),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(resourceProvider.notifier).fetchAll(forceRefresh: true);
                  ref.read(testProvider.notifier).fetchTests(forceRefresh: true);
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Refresh Content"),
              ),
            ],
          ),
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
    final isInCart    = widget.cartItemIds.contains(resource.id);
    final isPurchased = widget.purchasedIds.contains(resource.id);

    // Use DB-cached price data; fall back to base price until RPC returns
    final priceData    = _pricesCache[resource.id];
    final displayPrice = (priceData?['final_price'] as double?) ?? resource.price;
    final double? mrp  = (priceData?['has_discount'] == true)
        ? (priceData!['mrp_display'] as double?)
        : null;
    final String? discountTag = priceData?['discount_label'] as String?;

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
          isPurchased ? 'Download' : (displayPrice == 0 ? 'Free Claim' : 'Buy Now'),
      customAction: isPurchased
          ? DownloadActionButton(
              testId: resource.id.toString(),
              filename: 'resource_${resource.id}.pdf',
              url: resource.fileUrl,
              startLabel: "Open",
              isFullWidth: false,
              userId: ref.read(authProvider).user?.id,
              displayName: resource.title, // CHANGED
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
