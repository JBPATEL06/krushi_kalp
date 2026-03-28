import 'package:flutter/material.dart';
import '../../../../domain/models/mock_test.dart';
import '../../../../domain/models/offer.dart';
import 'store_item_card.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/services/offer_service.dart';
import '../../../../data/services/review_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/common/download_action_button.dart';
import '../../../widgets/common/responsive_wrapper.dart';
import '../../../utils/exam_helper.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_notifier.dart';

class StoreGrid extends ConsumerStatefulWidget {
  final List<MockTest> allTests;
  final List<Offer>? activeOffers;
  final Set<int>? cartItemIds;
  final Set<int>? purchasedTestIds;
  final Function(MockTest) onBuyTap;
  final Function(MockTest) onCartTap;
  final Function(MockTest) onTap;
  final bool isWide;

  static const double kPremiumPriceThreshold = 199.0;

  const StoreGrid({
    super.key,
    required this.allTests,
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
  // Cache: testId -> {average: double, count: int}
  final Map<int, Map<String, dynamic>> _ratingsCache = {};
  // Cache: testId -> {final_price, mrp_display, discount_label, has_discount}
  final Map<int, Map<String, dynamic>> _pricesCache = {};

  @override
  void initState() {
    super.initState();
    _fetchAllRatings();
    _fetchAllPrices();
  }

  @override
  void didUpdateWidget(StoreGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.allTests != widget.allTests) {
      _fetchAllRatings();
      _fetchAllPrices();
    }
  }

  Future<void> _fetchAllRatings() async {
    final uncachedIds = widget.allTests
        .map((t) => t.id)
        .where((id) => !_ratingsCache.containsKey(id))
        .toList();
    if (uncachedIds.isEmpty) return;
    try {
      final bulk = await ReviewService.getBulkRatingStats(uncachedIds, 'test');
      if (mounted) setState(() => _ratingsCache.addAll(bulk));
    } catch (_) {
      // Silently skip — cards will render without ratings
    }
  }

  Future<void> _fetchAllPrices() async {
    final uncached = widget.allTests
        .where((t) => !_pricesCache.containsKey(t.id))
        .toList();
    if (uncached.isEmpty) return;
    // Fire all RPCs concurrently
    final results = await Future.wait(
      uncached.map((t) => OfferService.instance.getDisplayPrice(
        itemType: 'mock_test',
        itemId: t.id,
      )),
    );
    if (mounted) {
      setState(() {
        for (int i = 0; i < uncached.length; i++) {
          _pricesCache[uncached[i].id] = results[i];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.allTests.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Text(
            "No tests found",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: context.w(AppSpacing.lg)),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Padding(
              padding: EdgeInsets.only(bottom: context.h(AppSpacing.lg)),
              child: _buildCard(context, widget.allTests[index]),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
          },
          childCount: widget.allTests.length,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, MockTest test) {
    // Use DB-cached price data; fall back to base price until RPC returns
    final priceData = _pricesCache[test.id];
    final double displayPrice = (priceData?['final_price'] as double?) ?? test.price;
    final double mrp         = (priceData?['mrp_display'] as double?) ?? test.price;
    final String? discountTag = priceData?['discount_label'] as String?;

    final isInCart = widget.cartItemIds?.contains(test.id) ?? false;
    final isPurchased = widget.purchasedTestIds?.contains(test.id) ?? false;

    // Use cached ratings instead of FutureBuilder
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
      actionLabel: displayPrice == 0 ? 'Claim' : 'Buy Now',
      customAction: isPurchased
          ? DownloadActionButton(
              testId: test.id.toString(),
              filename: 'mock_test_${test.id}.json',
              url: test.contentUrl,
              startLabel: "Start",
              isFullWidth: true, // Needs to be full width in the vertical card
              userId: ref.read(authNotifierProvider).user?.id,
              displayName: test.title, // CHANGED
              onAction: () async {
                if (test.contentUrl == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            "Error: Content not found for '${test.title}'")),
                  );
                  return;
                }
                await ExamHelper.startExam(context, test);
              },
            )
          : null,
      isActionEnabled: true,
      isInCart: isInCart,
      isPurchased: isPurchased,
      rating: rating,
      reviewCount: count,
      onActionTap: () {
        if (displayPrice == 0) {
          onBuyTap(test);
        } else {
          onBuyTap(test);
        }
      },
      onCartTap: () => widget.onCartTap(test),
      onTap: () => widget.onTap(test),
    );
  }

  void onBuyTap(MockTest test) => widget.onBuyTap(test);
}
