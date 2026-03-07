import 'package:flutter/material.dart';
import '../../domain/models/mock_test.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/test_service.dart';
import 'purchased_tests_screen.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

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

    final user = AuthService().currentUser;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to purchase.')),
      );
      setState(() => _isProcessing = false);
      return;
    }

    try {
      await TestService.purchaseMockTest(
        testId: widget.test.id,
        amount: _total,
        authUserId: user.id,
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: colorScheme.surface,
            surfaceTintColor: colorScheme.surfaceTint,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg)),
            title: const Text('Success'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded,
                    color: colorScheme.tertiary, size: 48),
                const SizedBox(height: AppSpacing.md),
                const Text('Purchase successful!'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PurchasedTestsScreen()),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            // Item Summary
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border:
                    Border.all(color: colorScheme.outline.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(Icons.description_rounded,
                        color: colorScheme.primary, size: 30),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.test.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.test.category,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${widget.test.finalPrice}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),

            // Price Breakdown
            _buildRow(context, 'Subtotal', _subtotal),
            const SizedBox(height: AppSpacing.sm),
            _buildRow(context, 'Tax (5%)', _taxes),
            Divider(
                height: AppSpacing.xxl,
                color: colorScheme.outline.withOpacity(0.1)),
            _buildRow(context, 'Total', _total, isTotal: true),

            const SizedBox(height: AppSpacing.xxl),

            // Pay Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handlePurchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg)),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Confirm & Pay',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, double amount,
      {bool isTotal = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)
              : theme.textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: isTotal
              ? theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold, color: colorScheme.primary)
              : theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold, color: colorScheme.onSurface),
        ),
      ],
    );
  }
}
