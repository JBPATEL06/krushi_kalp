import 'package:flutter/material.dart';
import '../../../../domain/models/offer.dart';
import '../../../../core/theme/app_colors.dart';

class CartItemWidget extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onRemove;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final title = item['title'] ?? 'Mock Test';
    final category = item['subtitle'] ?? 'General';
    final imageUrl = item['image_url'];
    final double currentPrice = (item['price'] as num).toDouble();
    final double? mrp = (item['mrp'] as num?)?.toDouble();

    // Check for applied offer (passed from CartScreen -> TestService stream)
    Offer? appliedOffer;
    final offersData = item['offers'];
    if (offersData != null && offersData is Map && offersData.isNotEmpty) {
      try {
        appliedOffer = Offer.fromJson(Map<String, dynamic>.from(offersData));
      } catch (_) {}
    }

    // Calculate final price for this item
    double finalItemPrice = currentPrice;

    if (appliedOffer != null) {
      final discount = appliedOffer.calculateDiscountAmount(
        totalAmount: currentPrice,
        cartItems: [
          {'test_id': item['test_id'], 'price': currentPrice}
        ],
      );
      finalItemPrice = (currentPrice - discount).clamp(0.0, double.infinity);
    }

    // Determine Strikethrough Price (MRP takes precedence, else Base Price if Coupon applied)
    final double strikethroughPrice = mrp ?? currentPrice;
    final bool isDiscounted = strikethroughPrice > finalItemPrice;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null
                  ? const Icon(Icons.book, size: 30, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Price Row
                  Row(
                    children: [
                      if (isDiscounted) ...[
                        Text("₹${strikethroughPrice.toStringAsFixed(0)}",
                            style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                                fontSize: 12)),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        '₹${finalItemPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              isDiscounted ? AppColors.success : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
