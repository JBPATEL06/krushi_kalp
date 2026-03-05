import 'package:flutter_test/flutter_test.dart';
import 'package:krushi_kalp/utils/price_calculator.dart';
import 'package:krushi_kalp/domain/models/offer.dart';

// Helper to create test offers quickly
Offer _makeOffer({
  int id = 1,
  String discountType = 'PERCENTAGE',
  double discountValue = 10,
  String targetType = 'ALL',
  List<dynamic> targetIds = const [],
  double? maxDiscount,
  bool isReal = true,
}) {
  return Offer(
    id: id,
    title: 'Test Offer $id',
    description: 'Test',
    discountType: discountType,
    discountValue: discountValue,
    isActive: true,
    targetType: targetType,
    targetIds: targetIds,
    maxDiscount: maxDiscount,
    isReal: isReal,
  );
}

void main() {
  group('PriceCalculator', () {
    group('No offers', () {
      test('returns base price when no offers provided', () {
        final result = PriceCalculator.calculateDisplayPrice(basePrice: 100.0);
        expect(result['finalPrice'], 100.0);
        expect(result['mrp'], 100.0);
        expect(result['offer'], isNull);
      });

      test('returns base price when offers list is empty', () {
        final result = PriceCalculator.calculateDisplayPrice(
          basePrice: 500.0,
          activeOffers: [],
        );
        expect(result['finalPrice'], 500.0);
        expect(result['offer'], isNull);
      });
    });

    group('Real percentage discounts', () {
      test('applies 10% discount correctly', () {
        final offer = _makeOffer(discountValue: 10);
        final result = PriceCalculator.calculateDisplayPrice(
          basePrice: 200.0,
          activeOffers: [offer],
        );
        expect(result['finalPrice'], 180.0); // 200 - 10% = 180
        expect(result['mrp'], 200.0);
        expect(result['offer'], offer);
      });

      test('applies 50% discount correctly', () {
        final offer = _makeOffer(discountValue: 50);
        final result = PriceCalculator.calculateDisplayPrice(
          basePrice: 400.0,
          activeOffers: [offer],
        );
        expect(result['finalPrice'], 200.0);
      });

      test('applies 100% discount → price becomes 0', () {
        final offer = _makeOffer(discountValue: 100);
        final result = PriceCalculator.calculateDisplayPrice(
          basePrice: 300.0,
          activeOffers: [offer],
        );
        expect(result['finalPrice'], 0.0);
      });
    });

    group('Real flat discounts', () {
      test('applies flat ₹50 discount', () {
        final offer = _makeOffer(discountType: 'FLAT', discountValue: 50);
        final result = PriceCalculator.calculateDisplayPrice(
          basePrice: 200.0,
          activeOffers: [offer],
        );
        expect(result['finalPrice'], 150.0);
        expect(result['mrp'], 200.0);
      });

      test('flat discount exceeding price → clamps to 0', () {
        final offer = _makeOffer(discountType: 'FLAT', discountValue: 500);
        final result = PriceCalculator.calculateDisplayPrice(
          basePrice: 200.0,
          activeOffers: [offer],
        );
        expect(result['finalPrice'], 0.0); // Clamped, not negative
      });
    });

    group('Max discount cap', () {
      test('caps percentage discount at maxDiscount', () {
        // 50% of 1000 = 500, but max discount is 100
        final offer = _makeOffer(discountValue: 50, maxDiscount: 100);
        final result = PriceCalculator.calculateDisplayPrice(
          basePrice: 1000.0,
          activeOffers: [offer],
        );
        expect(result['finalPrice'], 900.0); // 1000 - 100 cap = 900
      });

      test('does not cap when discount is below maxDiscount', () {
        // 10% of 200 = 20, max is 100 → no cap
        final offer = _makeOffer(discountValue: 10, maxDiscount: 100);
        final result = PriceCalculator.calculateDisplayPrice(
          basePrice: 200.0,
          activeOffers: [offer],
        );
        expect(result['finalPrice'], 180.0); // Normal 10% off
      });
    });

    group('Fake offers (MRP inflation)', () {
      test('fake percentage offer inflates MRP, keeps price same', () {
        final offer = _makeOffer(discountValue: 20, isReal: false);
        final result = PriceCalculator.calculateDisplayPrice(
          basePrice: 100.0,
          activeOffers: [offer],
        );
        expect(result['finalPrice'], 100.0); // Price stays same
        expect(result['mrp'], 125.0); // 100 / (1 - 0.20) = 125
      });

      test('fake flat offer inflates MRP by fixed amount', () {
        final offer =
            _makeOffer(discountType: 'FLAT', discountValue: 50, isReal: false);
        final result = PriceCalculator.calculateDisplayPrice(
          basePrice: 200.0,
          activeOffers: [offer],
        );
        expect(result['finalPrice'], 200.0);
        expect(result['mrp'], 250.0); // 200 + 50
      });
    });

    group('Target filtering', () {
      test('ALL target applies to any item', () {
        final offer = _makeOffer(targetType: 'ALL', discountValue: 10);
        final result = PriceCalculator.calculateDisplayPrice(
          basePrice: 100.0,
          activeOffers: [offer],
          testId: 999,
        );
        expect(result['finalPrice'], 90.0);
      });

      test('TEST target applies only to matching testId', () {
        final offer =
            _makeOffer(targetType: 'TEST', targetIds: [5], discountValue: 10);
        final result = PriceCalculator.calculateDisplayPrice(
          basePrice: 100.0,
          activeOffers: [offer],
          testId: 5,
        );
        expect(result['finalPrice'], 90.0);
      });

      test('TEST target does NOT apply to non-matching testId', () {
        final offer =
            _makeOffer(targetType: 'TEST', targetIds: [5], discountValue: 10);
        final result = PriceCalculator.calculateDisplayPrice(
          basePrice: 100.0,
          activeOffers: [offer],
          testId: 99,
        );
        expect(result['finalPrice'], 100.0); // No discount
        expect(result['offer'], isNull);
      });

      test('USER target applies only to matching userId', () {
        final offer = _makeOffer(
            targetType: 'USER', targetIds: ['user-abc'], discountValue: 20);
        final result = PriceCalculator.calculateDisplayPrice(
          basePrice: 100.0,
          activeOffers: [offer],
          userId: 'user-abc',
        );
        expect(result['finalPrice'], 80.0);
      });

      test('USER target does NOT apply to non-matching userId', () {
        final offer = _makeOffer(
            targetType: 'USER', targetIds: ['user-abc'], discountValue: 20);
        final result = PriceCalculator.calculateDisplayPrice(
          basePrice: 100.0,
          activeOffers: [offer],
          userId: 'user-xyz',
        );
        expect(result['finalPrice'], 100.0);
      });
    });

    group('Best offer selection', () {
      test('selects the offer with lowest final price', () {
        final offer10 = _makeOffer(id: 1, discountValue: 10);
        final offer30 = _makeOffer(id: 2, discountValue: 30);
        final result = PriceCalculator.calculateDisplayPrice(
          basePrice: 100.0,
          activeOffers: [offer10, offer30],
        );
        expect(result['finalPrice'], 70.0);
        expect((result['offer'] as Offer).id, 2);
      });
    });
  });

  group('Offer.isValid', () {
    test('inactive offer is invalid', () {
      final offer = Offer(
        id: 1,
        title: 'Test',
        description: '',
        discountType: 'FLAT',
        discountValue: 10,
        isActive: false,
        targetType: 'ALL',
        targetIds: [],
      );
      expect(
          offer.isValid(userId: 'u1', cartTotal: 100, cartTestIds: []), false);
    });

    test('expired offer is invalid', () {
      final offer = Offer(
        id: 1,
        title: 'Test',
        description: '',
        discountType: 'FLAT',
        discountValue: 10,
        isActive: true,
        targetType: 'ALL',
        targetIds: [],
        endDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(
          offer.isValid(userId: 'u1', cartTotal: 100, cartTestIds: []), false);
    });

    test('valid ALL offer passes', () {
      final offer = Offer(
        id: 1,
        title: 'Test',
        description: '',
        discountType: 'FLAT',
        discountValue: 10,
        isActive: true,
        targetType: 'ALL',
        targetIds: [],
      );
      expect(
          offer.isValid(userId: 'u1', cartTotal: 100, cartTestIds: []), true);
    });

    test('minOrderValue blocks low cart totals', () {
      final offer = Offer(
        id: 1,
        title: 'Test',
        description: '',
        discountType: 'FLAT',
        discountValue: 10,
        isActive: true,
        targetType: 'ALL',
        targetIds: [],
        minOrderValue: 500,
      );
      expect(
          offer.isValid(userId: 'u1', cartTotal: 100, cartTestIds: []), false);
      expect(
          offer.isValid(userId: 'u1', cartTotal: 600, cartTestIds: []), true);
    });
  });

  group('Offer.calculateDiscountAmount', () {
    test('percentage discount on full cart', () {
      final offer = Offer(
        id: 1,
        title: 'Test',
        description: '',
        discountType: 'PERCENTAGE',
        discountValue: 20,
        isActive: true,
        targetType: 'ALL',
        targetIds: [],
      );
      final discount =
          offer.calculateDiscountAmount(totalAmount: 500, cartItems: []);
      expect(discount, 100.0); // 20% of 500
    });

    test('percentage discount capped by maxDiscount', () {
      final offer = Offer(
        id: 1,
        title: 'Test',
        description: '',
        discountType: 'PERCENTAGE',
        discountValue: 50,
        isActive: true,
        targetType: 'ALL',
        targetIds: [],
        maxDiscount: 100,
      );
      final discount =
          offer.calculateDiscountAmount(totalAmount: 500, cartItems: []);
      expect(discount, 100.0); // 50% of 500 = 250, capped at 100
    });

    test('fake offer returns 0 discount', () {
      final offer = Offer(
        id: 1,
        title: 'Fake',
        description: '',
        discountType: 'PERCENTAGE',
        discountValue: 30,
        isActive: true,
        targetType: 'ALL',
        targetIds: [],
        isReal: false,
      );
      final discount =
          offer.calculateDiscountAmount(totalAmount: 500, cartItems: []);
      expect(discount, 0.0);
    });
  });
}
