import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../widgets/common/responsive_wrapper.dart';

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
    final theme = Theme.of(context);
    final total = subtotal - discountAmount;

    return Container(
      padding: EdgeInsets.all(context.w(AppSpacing.lg)),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(context.w(AppSpacing.radiusXl)),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
              fontSize: context.sp(18),
            ),
          ),
          SizedBox(height: context.h(AppSpacing.lg)),
          _buildSummaryRow(context, 'Subtotal', subtotal),
          if (discountAmount > 0) ...[
            SizedBox(height: context.h(AppSpacing.md)),
            _buildSummaryRow(
              context,
              'Student Discount (${couponCode ?? '10%'})',
              -discountAmount,
              isDiscount: true,
            ),
          ],
          SizedBox(height: context.h(AppSpacing.md)),
          _buildSummaryRow(context, 'Academic Tax', 0.0), // Placeholder for UI
          SizedBox(height: context.h(AppSpacing.lg)),
          Divider(color: theme.colorScheme.outlineVariant, thickness: 1),
          SizedBox(height: context.h(AppSpacing.lg)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  fontSize: context.sp(20),
                ),
              ),
              Text(
                '₹${total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: context.sp(22),
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          if (discountAmount > 0) ...[
            SizedBox(height: context.h(AppSpacing.lg)),
            Container(
              padding: EdgeInsets.symmetric(
                vertical: context.h(AppSpacing.sm),
                horizontal: context.w(AppSpacing.md),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(context.w(AppSpacing.radiusMd)),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.stars_rounded,
                    size: context.sp(16),
                    color: const Color(0xFF10B981),
                  ),
                  SizedBox(width: context.w(AppSpacing.sm)),
                  Text(
                    'You Saved ₹${discountAmount.toStringAsFixed(0)} on this order!',
                    style: TextStyle(
                      color: const Color(0xFF10B981),
                      fontSize: context.sp(13),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    double amount, {
    bool isDiscount = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDiscount
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isDiscount ? FontWeight.w600 : FontWeight.normal,
            fontSize: context.sp(14),
          ),
        ),
        Text(
          amount == 0 && !isDiscount
              ? '₹0.00'
              : '${isDiscount ? "-" : ""}₹${amount.abs().toStringAsFixed(2)}',
          style: TextStyle(
            color: isDiscount
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: context.sp(15),
          ),
        ),
      ],
    );
  }
}
