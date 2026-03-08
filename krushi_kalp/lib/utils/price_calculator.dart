import 'package:flutter/foundation.dart';
import '../domain/models/offer.dart';

class PriceCalculator {
  /// Calculates the display MRP (High Price) and Final Selling Price.
  /// Handles both "Real" (Price discount) and "Fake" (MRP hike) offers simultaneously.
  static Map<String, dynamic> calculateDisplayPrice({
    required double basePrice,
    double? baseMrp, // NEW
    List<Offer>? activeOffers,
    int? testId,
    int? resourceId,
    String? userId,
  }) {
    

    if (activeOffers == null || activeOffers.isEmpty) {
      
    }

    Offer? bestOffer;
    double finalPrice = basePrice;
    double mrp = baseMrp ?? basePrice;

    if (activeOffers != null) {
      
      for (var offer in activeOffers) {
        final applicable = _isApplicable(offer, testId, resourceId, userId);
        

        if (!applicable) continue;

        double currentPrice = basePrice;
        double currentMrp = baseMrp ?? basePrice;

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
          currentMrp = baseMrp ?? basePrice; // Preserves original MRP
        } else {
          // Fake Offer: Price is Base, MRP is Inflated
          currentPrice = basePrice;
          if (offer.discountType == 'PERCENTAGE') {
            double rate = offer.discountValue / 100;
            if (rate >= 1) rate = 0.99;
            currentMrp = basePrice / (1 - rate); // Inflate from base
          } else {
            currentMrp = basePrice + offer.discountValue; // Inflate from base
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
          
          bestOffer = offer;
          finalPrice = currentPrice;
          mrp = currentMrp;
        }
      }
    }

    

    // Ensure price never goes negative
    if (finalPrice < 0) {
      
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
