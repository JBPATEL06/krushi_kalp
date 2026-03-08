import 'order_item.dart';

class Order {
  final String orderId;
  final String userId;
  final double totalAmount;
  final double discountAmount;
  final int? offerId;
  final String status;
  final String? paymentGatewayId;
  final DateTime createdAt;

  final List<OrderItem>? items;

  Order({
    required this.orderId,
    required this.userId,
    required this.totalAmount,
    this.discountAmount = 0.0,
    this.offerId,
    this.status = 'PENDING',
    this.paymentGatewayId,
    required this.createdAt,
    this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var itemsList = <OrderItem>[];
    if (json['order_items'] != null && json['order_items'] is List) {
      itemsList = (json['order_items'] as List)
          .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    return Order(
      orderId: (json['order_id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      offerId: (json['offer_id'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'PENDING',
      paymentGatewayId: json['payment_gateway_id'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
      items: itemsList,
    );
  }
}
