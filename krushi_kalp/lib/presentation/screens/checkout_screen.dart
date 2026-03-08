import 'package:flutter/material.dart';
import '../../domain/models/mock_test.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/test_service.dart';
import '../../utils/error_utils.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';
import '../widgets/common/responsive_wrapper.dart';
import 'purchased_tests_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final MockTest test;

  const CheckoutScreen({super.key, required this.test});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isProcessing = false;

  double get _subtotal => widget.test.finalPrice;
  double get _taxes => _subtotal * 0.05; // 5% tax example
  double get _total => _subtotal + _taxes;

  Future<void> _handlePurchase() async {
    setState(() => _isProcessing = true);

    final user = AuthService.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to purchase.')),
      );
      setState(() => _isProcessing = false);
      return;
    }

    try {
      await TestService.instance.createDirectOrder(
        testId: widget.test.id,
        price: _total,
        authUserId: user.id,
      );

      if (mounted) {
        // Show success, then navigate
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppRadius.lg)), // FIXED: AppRadius.lg
            title: const Text('Success'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle,
                    color: Colors.green, size: 48), // FIXED: large icon
                const SizedBox(
                    height: AppSpacing.lg), // FIXED: AppSpacing.lg (16)
                const Text('Purchase successful!'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  // Navigate to Purchased Tests
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PurchasedTestsScreen(),
                    ),
                  );
                },
                child: const Text('View My Tests'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorUtils.showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Checkout', style: theme.textTheme.titleLarge),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(
            AppSpacing.xxl), // FIXED: AppSpacing.xxl (24.0)
        child: Column(
          children: [
            // Item Summary
            Container(
              padding: const EdgeInsets.all(
                  AppSpacing.lg), // FIXED: AppSpacing.lg (16)
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(
                    AppRadius.lg), // FIXED: AppRadius.lg (16)
              ),
              child: Row(
                children: [
                  Container(
                    width: context.w(60), // FIXED: context.w(60)
                    height: context.h(60), // FIXED: context.h(60)
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                          AppRadius.md), // FIXED: AppRadius.md (12)
                    ),
                    child: Icon(
                      Icons.description,
                      color: theme.colorScheme.primary,
                      size: context.sp(30),
                    ),
                  ),
                  const SizedBox(
                      width: AppSpacing.lg), // FIXED: AppSpacing.lg (16)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.test.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: context.sp(16),
                          ),
                        ),
                        Text(
                          widget.test.category,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: context.sp(14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${widget.test.finalPrice}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: context.sp(16),
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),

            // Price Breakdown
            _buildRow(theme, 'Subtotal', _subtotal),
            const SizedBox(height: AppSpacing.md), // FIXED: AppSpacing.md (12)
            _buildRow(theme, 'Tax (5%)', _taxes),
            const Divider(
                height: AppSpacing.xxxl), // FIXED: AppSpacing.xxxl (32)
            _buildRow(theme, 'Total', _total, isTotal: true),

            const SizedBox(
                height: AppSpacing.xxxl), // FIXED: AppSpacing.xxxl (32)

            // Pay Button
            SizedBox(
              width: double.infinity,
              height: context.h(56), // FIXED: context.h(56)
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handlePurchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        AppRadius.lg), // FIXED: AppRadius.lg (16)
                  ),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? CircularProgressIndicator(
                        color: theme.colorScheme.onPrimary)
                    : Text(
                        'Confirm & Pay',
                        style: TextStyle(
                          fontSize: context.sp(16), // FIXED: context.sp(16)
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(ThemeData theme, String label, double amount,
      {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: context.sp(isTotal ? 18 : 14), // FIXED: context.sp
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: context.sp(isTotal ? 20 : 14), // FIXED: context.sp
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
