import 'mock_test.dart';
import 'resource.dart';

class OrderItem {
  final int itemId;
  final String orderId;
  final int? testId; // Nullable now
  final int? resourceId; // New field replacing materialId
  final double priceAtPurchase;
  final int? appliedOfferId;
  final DateTime createdAt;
  final MockTest? mockTest; // Optional relation
  final Resource? resource; // New optional relation replacing studyMaterial
  final Map<String, dynamic>? offers;

  OrderItem({
    required this.itemId,
    required this.orderId,
    this.testId,
    this.resourceId,
    required this.priceAtPurchase,
    this.appliedOfferId,
    required this.createdAt,
    this.mockTest,
    this.resource,
    this.offers,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      itemId: json['item_id'] is int
          ? json['item_id']
          : int.tryParse(json['item_id'].toString()) ?? 0,
      orderId: json['order_id']?.toString() ?? '',
      testId: json['test_id'] != null
          ? int.tryParse(json['test_id'].toString())
          : null,
      resourceId: json['resource_id'] != null
          ? int.tryParse(json['resource_id'].toString())
          : null,
      priceAtPurchase: (json['price_at_purchase'] as num?)?.toDouble() ?? 0.0,
      appliedOfferId: json['applied_offer_id'] != null
          ? int.tryParse(json['applied_offer_id'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      mockTest: json['mock_tests'] != null
          ? MockTest.fromJson(json['mock_tests'])
          : null,
      resource: json['resources'] != null
          ? Resource.fromJson(json['resources'])
          : null,
      offers: json['offers'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'order_id': orderId,
      'test_id': testId,
      'resource_id': resourceId,
      'price_at_purchase': priceAtPurchase,
      'applied_offer_id': appliedOfferId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
