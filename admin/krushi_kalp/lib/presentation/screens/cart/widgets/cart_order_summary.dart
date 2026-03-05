import 'package:flutter/material.dart';

class CartOrderSummary extends StatelessWidget {
  final double subtotal;
  final double discountAmount;
  final String? couponCode;

  const CartOrderSummary({
    super.key,
    required this.subtotal,
    required this.discountAmount,
    this.couponCode,
  });

  @override
  Widget build(BuildContext context) {
    final total = subtotal - discountAmount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', subtotal),
          if (discountAmount > 0) ...[
            const SizedBox(height: 12),
            _buildSummaryRow(
              'Discount (${couponCode ?? 'Coupon'})',
              -discountAmount,
              isDiscount: true,
            ),
          ],
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                '₹${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDiscount ? Colors.green : Colors.grey[700],
            fontWeight: isDiscount ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          '₹${amount.abs().toStringAsFixed(2)}',
          style: TextStyle(
            color: isDiscount ? Colors.green : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
