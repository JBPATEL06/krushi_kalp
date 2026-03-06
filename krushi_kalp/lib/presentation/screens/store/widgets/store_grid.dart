import 'package:flutter/material.dart';
import '../../../../domain/models/mock_test.dart';
import '../../../../domain/models/offer.dart';
import 'store_item_card.dart';
import '../../../../utils/price_calculator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/services/review_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/common/download_action_button.dart';
import '../../../widgets/common/responsive_wrapper.dart';
import '../../../utils/exam_helper.dart';

class StoreGrid extends StatefulWidget {
  final List<MockTest> tests;
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
    required this.tests,
    this.activeOffers,
    this.cartItemIds,
    this.purchasedTestIds,
    required this.onBuyTap,
    required this.onCartTap,
    required this.onTap,
    this.isWide = false,
  });

  @override
  State<StoreGrid> createState() => _StoreGridState();
}

class _StoreGridState extends State<StoreGrid> {
  // Cache: testId -> {average: double, count: int}
  final Map<int, Map<String, dynamic>> _ratingsCache = {};

  @override
  void initState() {
    super.initState();
    _fetchAllRatings();
  }

  @override
  void didUpdateWidget(StoreGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-fetch only if the test list changed
    if (oldWidget.tests != widget.tests) {
      _fetchAllRatings();
    }
  }

  Future<void> _fetchAllRatings() async {
    // Only fetch IDs not already in cache
    final uncachedIds = widget.tests
        .map((t) => t.id)
        .where((id) => !_ratingsCache.containsKey(id))
        .toList();

    if (uncachedIds.isEmpty) return;

    try {
      final bulk = await ReviewService.getBulkRatingStats(uncachedIds, 'test');
      if (mounted) {
        setState(() => _ratingsCache.addAll(bulk));
      }
    } catch (_) {
      // Silently skip — cards will render without ratings
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tests.isEmpty) {
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
              child: _buildCard(context, widget.tests[index]),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
          },
          childCount: widget.tests.length,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, MockTest test) {
    final saleOffers = widget.activeOffers?.where((o) => o.isSale).toList();

    final priceData = PriceCalculator.calculateDisplayPrice(
      basePrice: test.price,
      activeOffers: saleOffers,
      testId: test.id,
    );

    final double displayPrice = priceData['finalPrice'];
    final double mrp = priceData['mrp'];
    final Offer? offer = priceData['offer'];

    String? discountTag;
    if (offer != null) {
      if (offer.discountType == 'PERCENTAGE') {
        discountTag = '${offer.discountValue.toStringAsFixed(0)}% OFF';
      } else {
        discountTag = '₹${offer.discountValue.toStringAsFixed(0)} OFF';
      }
    }

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
              filename: 'mock_test_${test.id}.json',
              url: test.contentUrl,
              startLabel: "Start",
              isFullWidth: true, // Needs to be full width in the vertical card
              userId: AuthService.instance.currentUser?.id,
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
