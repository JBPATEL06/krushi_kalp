import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../domain/models/resource.dart';
import '../../../../domain/models/offer.dart';
import '../../../../data/services/offer_service.dart';
import '../../../../data/services/review_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../utils/responsive.dart';
import '../../resource_files_screen.dart';
import 'store_item_card.dart';

class StoreResourceGrid extends ConsumerStatefulWidget {
  final PagingController<int, Resource> pagingController;
  final List<Offer>? activeOffers;
  final Set<int> purchasedIds;
  final Set<int> cartItemIds;
  final Function(Resource) onBuyTap;
  final Function(Resource) onCartTap;
  final Function(Resource) onTap;
  final bool isWide;

  const StoreResourceGrid({
    super.key,
    required this.pagingController,
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
    widget.pagingController.addStatusListener((status) {
      if (status == PagingStatus.completed || status == PagingStatus.noItemsFound) {
        _fetchMetadataForNewItems();
      }
    });
  }

  void _fetchMetadataForNewItems() {
    final items = widget.pagingController.itemList ?? [];
    if (items.isEmpty) return;
    _fetchAllRatings(items);
    _fetchAllPrices(items);
  }

  Future<void> _fetchAllRatings(List<Resource> items) async {
    final uncachedIds = items
        .map((r) => r.id)
        .where((id) => !_ratingsCache.containsKey(id))
        .toList();
    if (uncachedIds.isEmpty) return;
    try {
      final bulk = await ReviewService.getBulkRatingStats(uncachedIds, 'resource');
      if (mounted) setState(() => _ratingsCache.addAll(bulk));
    } catch (_) {}
  }

  Future<void> _fetchAllPrices(List<Resource> items) async {
    final uncached = items
        .where((r) => !_pricesCache.containsKey(r.id))
        .toList();
    if (uncached.isEmpty) return;

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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: context.w(AppSpacing.lg)),
      sliver: PagedSliverList<int, Resource>.separated(
        pagingController: widget.pagingController,
        separatorBuilder: (_, __) => SizedBox(height: context.h(AppSpacing.md)),
        builderDelegate: PagedChildBuilderDelegate<Resource>(
          itemBuilder: (context, resource, index) {
            return _buildCard(context, resource)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, end: 0);
          },
          firstPageProgressIndicatorBuilder: (_) =>
              const Center(child: CircularProgressIndicator()),
          newPageProgressIndicatorBuilder: (_) =>
              const Center(child: CircularProgressIndicator()),
          noItemsFoundIndicatorBuilder: (_) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("No items found in this category."),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton.icon(
                  onPressed: () => widget.pagingController.refresh(),
                  icon: const Icon(Icons.refresh),
                  label: const Text("Refresh Content"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, Resource resource) {
    final theme = Theme.of(context);
    final isInCart = widget.cartItemIds.contains(resource.id);
    final isPurchased = widget.purchasedIds.contains(resource.id);

    final priceData = _pricesCache[resource.id];
    final displayPrice = (priceData?['final_price'] as double?) ?? resource.price;
    final double? mrp = (priceData?['has_discount'] == true)
        ? (priceData!['mrp_display'] as double?)
        : null;
    final String? discountTag = priceData?['discount_label'] as String?;

    String subtitle = resource.type.toString().split('.').last.toUpperCase();
    if (resource.category != null) {
      subtitle += ' • ${resource.category}';
    }

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
          ? OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResourceFilesScreen(resource: resource),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.colorScheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(
                "Open",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            )
          : null,
      isActionEnabled: true,
      isInCart: isInCart,
      isPurchased: isPurchased,
      hideTags: isPurchased,
      rating: rating,
      reviewCount: count,
      onActionTap: () => widget.onBuyTap(resource),
      onCartTap: () => widget.onCartTap(resource),
      onTap: () => widget.onTap(resource),
      heroTag: 'store_resource_${resource.id}',
    );
  }
}
