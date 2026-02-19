import 'package:flutter/material.dart';
import '../../../../domain/models/mock_test.dart';
import '../../../../domain/models/offer.dart';
import '../../../widgets/common/universal_item_card.dart';
import '../../../../utils/price_calculator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/services/review_service.dart';
import 'package:flutter_animate/flutter_animate.dart'; // NEW

class StoreGrid extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (tests.isEmpty) {
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: _buildCard(tests[index]),
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, end: 0); // Animate
          },
          childCount: tests.length,
        ),
      ),
    );
  }

  Widget _buildCard(MockTest test) {
    // Filter offers to only include 'Sale' offers (Auto-apply)
    final saleOffers = activeOffers?.where((o) => o.isSale).toList();

    // Calculate Price using PriceCalculator
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

    final isInCart = cartItemIds?.contains(test.id) ?? false;
    final isPurchased = purchasedTestIds?.contains(test.id) ?? false;

    return FutureBuilder<Map<String, dynamic>>(
      future: ReviewService.getRatingStats(test.id, 'test'),
      builder: (context, snapshot) {
        double? rating;
        int? count;
        if (snapshot.hasData) {
          rating = snapshot.data!['average'] as double;
          count = snapshot.data!['count'] as int;
          if (count == 0) {
            rating = null;
            count = null;
          }
        }

        return UniversalItemCard(
          title: test.title,
          subtitle: '${test.totalQuestions} Qs • ${test.totalMarks} Marks',
          time: test.time,
          price: displayPrice,
          originalPrice: mrp,
          discountTag: discountTag,
          coverUrl: test.signedUrl,
          actionLabel: displayPrice == 0 ? 'Claim' : 'Buy Now',
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
          onCartTap: () => onCartTap(test),
          onTap: () => onTap(test),
        );
      },
    );
  }
}
