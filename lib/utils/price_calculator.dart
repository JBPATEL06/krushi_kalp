import 'package:flutter/foundation.dart';
import '../domain/models/offer.dart';

class PriceCalculator {
  /// Calculates the display MRP (High Price) and Final Selling Price.
  /// Handles both "Real" (Price discount) and "Fake" (MRP hike) offers simultaneously.
  static Map<String, dynamic> calculateDisplayPrice({
    required double basePrice,
    List<Offer>? activeOffers,
    int? testId,
    int? resourceId, // Added resourceId
    String? userId, // Added userId
  }) {
    debugPrint(
        'PriceCalculator: Calculating for basePrice: $basePrice, testId: $testId, resourceId: $resourceId, userId: $userId');

    if (activeOffers == null || activeOffers.isEmpty) {
      debugPrint('PriceCalculator: No activeOffers provided.');
    }

    Offer? bestOffer;
    double finalPrice = basePrice;
    double mrp = basePrice;

    if (activeOffers != null) {
      debugPrint(
          'PriceCalculator: Evaluating ${activeOffers.length} offers...');
      for (var offer in activeOffers) {
        final applicable = _isApplicable(offer, testId, resourceId, userId);
        debugPrint(
            'PriceCalculator: Checking Offer [${offer.id}] ${offer.title}. Applicable: $applicable');

        if (!applicable) continue;

        double currentPrice = basePrice;
        double currentMrp = basePrice;

        if (offer.isReal) {
          // Real Offer: Discount off Base
          if (offer.discountType == 'PERCENTAGE') {
            currentPrice = basePrice * (1 - (offer.discountValue / 100));
          } else {
            currentPrice = basePrice - offer.discountValue;
          }
          if (offer.maxDiscount != null) {
            final discount = basePrice - currentPrice;
            if (discount > offer.maxDiscount!) {
              currentPrice = basePrice - offer.maxDiscount!;
            }
          }
          currentMrp = basePrice;
        } else {
          // Fake Offer: Price is Base, MRP is Inflated
          currentPrice = basePrice;
          if (offer.discountType == 'PERCENTAGE') {
            double rate = offer.discountValue / 100;
            if (rate >= 1) rate = 0.99;
            currentMrp = basePrice / (1 - rate);
          } else {
            currentMrp = basePrice + offer.discountValue;
          }
        }
        if (currentPrice < 0) currentPrice = 0;

        // Selection Logic: Pick the single best offer
        bool isBetter = false;
        if (bestOffer == null) {
          if (currentPrice < basePrice || currentMrp > basePrice) {
            isBetter = true;
          }
        } else {
          // Favor lowest final price
          if (currentPrice < finalPrice) {
            isBetter = true;
          }
          // If prices are same, favor highest MRP (better perceived discount)
          else if (currentPrice == finalPrice && currentMrp > mrp) {
            isBetter = true;
          }
        }

        if (isBetter) {
          debugPrint(
              'PriceCalculator: New Best Offer Found! [${offer.id}] Price: $currentPrice, MRP: $currentMrp');
          bestOffer = offer;
          finalPrice = currentPrice;
          mrp = currentMrp;
        }
      }
    }

    debugPrint(
        'PriceCalculator: Result -> Final: $finalPrice, MRP: $mrp, BestOffer: ${bestOffer?.title ?? "None"}');

    // Ensure price never goes negative
    if (finalPrice < 0) {
      debugPrint(
          'PriceCalculator: Clamping negative finalPrice ($finalPrice) to 0');
      finalPrice = 0;
    }

    return {
      'finalPrice': finalPrice,
      'mrp': mrp,
      'offer': bestOffer,
    };
  }

  static bool _isApplicable(
      Offer offer, int? testId, int? resourceId, String? userId) {
    if (offer.targetType == 'ALL') return true;
    if (offer.targetType == 'USER') {
      if (userId == null) return false;
      return offer.targetIds.contains(userId);
    }
    if (offer.targetType == 'TEST') {
      if (testId == null) return false;
      return offer.targetIds.contains(testId) ||
          offer.targetIds.contains(testId.toString());
    }
    if (offer.targetType == 'RESOURCE' ||
        offer.targetType == 'EBOOK' ||
        offer.targetType == 'MATERIAL') {
      if (resourceId == null) return false;
      return offer.targetIds.contains(resourceId) ||
          offer.targetIds.contains(resourceId.toString());
    }
    return false;
  }
}
