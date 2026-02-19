import 'package:flutter/material.dart';
import '../../domain/models/mock_test.dart';
import '../../domain/models/offer.dart';
import '../../utils/price_calculator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

import 'package:provider/provider.dart';
import '../providers/test_provider.dart';

import 'package:cached_network_image/cached_network_image.dart';

class MockTestDetailScreen extends StatelessWidget {
  final MockTest test;
  final bool isPurchased;
  final List<Offer>? activeOffers;
  final String? heroTag;

  const MockTestDetailScreen({
    super.key,
    required this.test,
    this.isPurchased = false,
    this.activeOffers,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    // AUTO-DETECT PURCHASE STATUS
    final provider = context.watch<TestProvider>();
    final isActuallyPurchased =
        isPurchased || provider.purchasedTests.any((t) => t.id == test.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(test.title, style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false, // Hide default back arrow
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary, size: 24),
          onPressed: () => Navigator.of(context).pop(), // Dispose/close page
        ),
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Trigger provider refresh to check purchase status
            await context.read<TestProvider>().fetchPurchasedStatus();
            // Small delay for UI feedback
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // COVER IMAGE
                if (test.signedUrl != null && test.signedUrl!.isNotEmpty)
                  Hero(
                    tag: heroTag ??
                        'test_image_${test.id}', // Default to store tag if not provided
                    child: SizedBox(
                      height: 250,
                      width: double.infinity,
                      child: CachedNetworkImage(
                        imageUrl: test.signedUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.neutral200,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.neutral200,
                          child: const Icon(Icons.broken_image,
                              size: 40, color: AppColors.neutral400),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: AppColors.neutral200,
                    child: const Icon(Icons.image,
                        size: 64, color: AppColors.neutral400),
                  ),

                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TITLE & PRICE
                      Builder(builder: (context) {
                        final displayOffers =
                            activeOffers?.where((o) => o.isSale).toList();
                        final priceData = PriceCalculator.calculateDisplayPrice(
                          basePrice: test.price,
                          activeOffers: displayOffers,
                          testId: test.id,
                        );
                        final displayPrice = priceData['finalPrice'] as double;
                        final displayMrp = priceData['mrp'] as double;
                        final hasOffer = priceData['offer'] != null;
                        final discPercent = (displayMrp > displayPrice &&
                                displayMrp > 0)
                            ? ((displayMrp - displayPrice) / displayMrp * 100)
                                .round()
                            : 0;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              test.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Only show price if NOT purchased
                                if (!isActuallyPurchased) ...[
                                  if (hasOffer &&
                                      displayMrp > displayPrice) ...[
                                    Text(
                                      '₹${displayMrp.toStringAsFixed(0)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: AppColors.neutral500,
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                  ],
                                  Text(
                                    displayPrice == 0
                                        ? 'Free'
                                        : '₹${displayPrice.toStringAsFixed(0)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                  ),
                                  if (hasOffer && discPercent > 0) ...[
                                    const SizedBox(width: AppSpacing.md),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                          vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.error
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                            color: AppColors.error
                                                .withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        '$discPercent% OFF',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: AppColors.error,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ],
                                ] else ...[
                                  Text(
                                    "Purchased",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.success,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: AppSpacing.lg),

                      // KEY DETAILS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _DetailItem(
                            icon: Icons.access_time,
                            label: 'Duration',
                            value: test.time,
                          ),
                          _DetailItem(
                            icon: Icons.help_outline,
                            label: 'Questions',
                            value: '${test.totalQuestions}',
                          ),
                          _DetailItem(
                            icon: Icons.star_border,
                            label: 'Marks',
                            value: '${test.totalMarks}',
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const Divider(color: AppColors.neutral200),
                      const SizedBox(height: AppSpacing.lg),

                      // DESCRIPTION / SYLLABUS
                      Text(
                        "Description",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        test.description.isEmpty
                            ? "This mock test covers all important topics. Practice to improve your speed and accuracy."
                            : test.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                      ),

                      const SizedBox(height: AppSpacing.xl),
                      const Divider(color: AppColors.neutral200),
                      const SizedBox(height: AppSpacing.lg),

                      // ADDITIONAL INFO
                      Text(
                        "Test Information",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _InfoRow(
                        icon: Icons.category,
                        label: "Category",
                        value: test.category,
                      ),
                      if (test.negativeMarking)
                        _InfoRow(
                          icon: Icons.warning_amber_rounded,
                          label: "Negative Marking",
                          value:
                              "Yes (-${test.negativeMarksPerQ} per wrong answer)",
                          valueColor: AppColors.error,
                        )
                      else
                        const _InfoRow(
                          icon: Icons.check_circle_outline,
                          label: "Negative Marking",
                          value: "None",
                          valueColor: AppColors.success,
                        ),

                      if (test.discount != null && test.discount!.isNotEmpty)
                        _InfoRow(
                          icon: Icons.local_offer,
                          label: "Discount",
                          value: test.discount!,
                          valueColor: Colors.orange[700],
                        ),

                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                )),
      ],
    );
  }
}

// Added missing class
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.neutral600),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.neutral800,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
