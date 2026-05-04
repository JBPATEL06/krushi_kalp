import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../domain/models/mock_test.dart';
import '../../../../domain/models/offer.dart';
import '../../../../data/services/offer_service.dart';
import '../../../../data/services/review_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../utils/responsive.dart';
import '../../../widgets/common/download_action_button.dart';
import 'store_item_card.dart';
import '../../../providers/auth_notifier.dart';
import '../../../../presentation/utils/exam_helper.dart';

class StoreGrid extends ConsumerStatefulWidget {
  final PagingController<int, MockTest> pagingController;
  final List<Offer>? activeOffers;
  final Set<int>? cartItemIds;
  final Set<int>? purchasedTestIds;
  final Function(MockTest) onBuyTap;
  final Function(MockTest) onCartTap;
  final Function(MockTest) onTap;
  final bool isWide;

  const StoreGrid({
    super.key,
    required this.pagingController,
    this.activeOffers,
    this.cartItemIds,
    this.purchasedTestIds,
    required this.onBuyTap,
    required this.onCartTap,
    required this.onTap,
    this.isWide = false,
  });

  @override
  ConsumerState<StoreGrid> createState() => _StoreGridState();
}

class _StoreGridState extends ConsumerState<StoreGrid> {
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

  Future<void> _fetchAllRatings(List<MockTest> items) async {
    final uncachedIds = items
        .map((t) => t.id)
        .where((id) => !_ratingsCache.containsKey(id))
        .toList();
    if (uncachedIds.isEmpty) return;
    try {
      final bulk = await ReviewService.getBulkRatingStats(uncachedIds, 'test');
      if (mounted) setState(() => _ratingsCache.addAll(bulk));
    } catch (_) {}
  }

  Future<void> _fetchAllPrices(List<MockTest> items) async {
    final uncached = items
        .where((t) => !_pricesCache.containsKey(t.id))
        .toList();
    if (uncached.isEmpty) return;

    const int batchSize = 5;
    for (int i = 0; i < uncached.length; i += batchSize) {
      if (!mounted) break;
      final end = (i + batchSize < uncached.length) ? i + batchSize : uncached.length;
      final batch = uncached.sublist(i, end);
      try {
        final results = await Future.wait(
          batch.map((t) => OfferService.instance.getDisplayPrice(
            itemType: 'mock_test',
            itemId: t.id,
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
        debugPrint('StoreGrid: Batch price fetch failed at index $i - $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: context.w(AppSpacing.lg)),
      sliver: PagedSliverList<int, MockTest>.separated(
        pagingController: widget.pagingController,
        separatorBuilder: (_, __) => SizedBox(height: context.h(AppSpacing.lg)),
        builderDelegate: PagedChildBuilderDelegate<MockTest>(
          itemBuilder: (context, test, index) {
            return _buildCard(context, test)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, end: 0);
          },
          firstPageProgressIndicatorBuilder: (_) =>
              const Center(child: CircularProgressIndicator()),
          newPageProgressIndicatorBuilder: (_) =>
              const Center(child: CircularProgressIndicator()),
          noItemsFoundIndicatorBuilder: (_) => const Center(
            child: Text("No tests found", style: TextStyle(color: Colors.grey)),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, MockTest test) {
    final priceData = _pricesCache[test.id];
    final double displayPrice = (priceData?['final_price'] as double?) ?? test.price;
    final double mrp = (priceData?['mrp_display'] as double?) ?? test.price;
    final String? discountTag = priceData?['discount_label'] as String?;

    final isInCart = widget.cartItemIds?.contains(test.id) ?? false;
    final isPurchased = widget.purchasedTestIds?.contains(test.id) ?? false;

    final cachedRating = _ratingsCache[test.id];
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
      title: test.title,
      subtitle: '${test.totalQuestions} Qs • ${test.totalMarks} Marks',
      time: test.time,
      price: displayPrice,
      originalPrice: mrp,
      discountTag: discountTag,
      coverUrl: test.signedUrl,
      actionLabel: displayPrice == 0 ? 'Free Claim' : 'Buy Now',
      customAction: isPurchased
          ? DownloadActionButton(
              testId: test.id.toString(),
              filename: 'mock_test_${test.id}.json',
              url: test.contentUrl,
              startLabel: "Start",
              isFullWidth: true,
              userId: ref.read(authProvider).user?.id,
              displayName: test.title,
              onAction: () async {
                await ExamHelper.startExam(context, test);
              },
            )
          : null,
      isActionEnabled: true,
      isInCart: isInCart,
      isPurchased: isPurchased,
      rating: rating,
      reviewCount: count,
      onActionTap: () => widget.onBuyTap(test),
      onCartTap: () => widget.onCartTap(test),
      onTap: () => widget.onTap(test),
    );
  }
}
