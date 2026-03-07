import 'package:flutter/material.dart';
import '../../data/services/app_config_service.dart';
import '../../domain/models/mock_test.dart';
import '../../domain/models/offer.dart';
import '../../utils/price_calculator.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

import 'package:provider/provider.dart';
import '../providers/test_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/services/review_service.dart';
import '../../domain/models/review.dart';
import '../widgets/reviews/review_card.dart';
import '../widgets/reviews/review_dialog.dart';
import '../widgets/reviews/rate_stars.dart';
import 'reviews/all_reviews_screen.dart';

class MockTestDetailScreen extends StatefulWidget {
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
  State<MockTestDetailScreen> createState() => _MockTestDetailScreenState();
}

class _MockTestDetailScreenState extends State<MockTestDetailScreen> {
  bool _isLoadingReviews = true;
  bool _configLoaded = false;
  List<Review> _reviews = [];
  Review? _userReview;
  Map<String, dynamic> _ratingStats = {'average': 0.0, 'count': 0};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await AppConfigService.fetchConfigs();
    if (mounted) setState(() => _configLoaded = true);
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    if (!mounted) return;
    setState(() => _isLoadingReviews = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final futures = <Future>[
        ReviewService.getReviewsForItem(widget.test.id, 'test'),
        ReviewService.getRatingStats(widget.test.id, 'test'),
      ];

      if (user != null) {
        futures
            .add(ReviewService.getUserReview(user.id, widget.test.id, 'test'));
      }

      final results = await Future.wait(futures);

      if (mounted) {
        setState(() {
          _reviews = results[0] as List<Review>;
          _ratingStats = results[1] as Map<String, dynamic>;
          if (results.length > 2) {
            _userReview = results[2] as Review?;
          } else {
            _userReview = null;
          }
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading reviews: $e");
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  void _showReviewDialog() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to review')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => ReviewDialog(
        title: widget.test.title,
        initialRating: _userReview?.rating,
        initialReview: _userReview?.reviewText,
        isEdit: _userReview != null,
        lastEditedAt: _userReview?.updatedAt,
        onSubmit: (rating, text) async {
          try {
            await ReviewService.submitReview(
              userId: user.id,
              itemId: widget.test.id,
              itemType: 'test',
              rating: rating,
              reviewText: text,
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Review submitted successfully!')),
              );
              _loadReviews();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to submit: $e')),
              );
            }
          }
        },
        onDelete: () async {
          if (_userReview == null) return;
          try {
            await ReviewService.deleteReview(_userReview!.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Review deleted successfully')),
              );
              _loadReviews();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to delete: $e')),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<TestProvider>();
    final isActuallyPurchased = widget.isPurchased ||
        provider.purchasedTests.any((t) => t.id == widget.test.id);

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(widget.test.title),
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon:
              Icon(Icons.close_rounded, color: colorScheme.onSurface, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: colorScheme.primary,
          onRefresh: () async {
            await context.read<TestProvider>().fetchPurchasedStatus();
            await _loadReviews();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.test.signedUrl != null &&
                    widget.test.signedUrl!.isNotEmpty)
                  Hero(
                    tag: widget.heroTag ?? 'test_image_${widget.test.id}',
                    child: SizedBox(
                      height: 250,
                      width: double.infinity,
                      child: CachedNetworkImage(
                        imageUrl: widget.test.signedUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: colorScheme.surfaceVariant,
                          child:
                              const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: colorScheme.surfaceVariant,
                          child: Icon(Icons.broken_image_rounded,
                              size: 40,
                              color: colorScheme.onSurfaceVariant
                                  .withOpacity(0.3)),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: colorScheme.surfaceVariant,
                    child: Icon(Icons.image_rounded,
                        size: 64,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.3)),
                  ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                              color: colorScheme.outline.withOpacity(0.05)),
                        ),
                        child: Builder(builder: (context) {
                          final displayOffers = widget.activeOffers
                              ?.where((o) => o.isSale)
                              .toList();
                          final priceData =
                              PriceCalculator.calculateDisplayPrice(
                            basePrice: widget.test.price,
                            activeOffers: displayOffers,
                            testId: widget.test.id,
                          );
                          final displayPrice =
                              priceData['finalPrice'] as double;
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
                                widget.test.title,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (!isActuallyPurchased) ...[
                                    if (hasOffer &&
                                        displayMrp > displayPrice) ...[
                                      Text(
                                        '₹${displayMrp.toStringAsFixed(0)}',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          color: colorScheme.onSurfaceVariant
                                              .withOpacity(0.5),
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
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    if (hasOffer && discPercent > 0) ...[
                                      const SizedBox(width: AppSpacing.md),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.sm,
                                            vertical: 4),
                                        decoration: BoxDecoration(
                                          color: colorScheme.errorContainer
                                              .withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(
                                              AppSpacing.xs),
                                          border: Border.all(
                                              color: colorScheme.error
                                                  .withOpacity(0.1)),
                                        ),
                                        child: Text(
                                          '$discPercent% OFF',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: colorScheme.error,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ] else ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: colorScheme.tertiaryContainer
                                            .withOpacity(0.3),
                                        borderRadius:
                                            BorderRadius.circular(AppRadius.xl),
                                        border: Border.all(
                                            color: colorScheme.tertiary
                                                .withOpacity(0.2)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check_circle_rounded,
                                              size: 16,
                                              color: colorScheme.tertiary),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Purchased",
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.tertiary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              if (_configLoaded &&
                                  AppConfigService.areReviewsVisible)
                                Row(
                                  children: [
                                    RateStars(
                                      rating: (_ratingStats['average'] as num)
                                          .toDouble(),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_ratingStats['average']} (${_ratingStats['count']} reviews)',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          );
                        }),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                              color: colorScheme.outline.withOpacity(0.05)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _DetailItem(
                              icon: Icons.access_time_rounded,
                              label: 'Duration',
                              value: widget.test.time,
                            ),
                            _ContainerDivider(),
                            _DetailItem(
                              icon: Icons.help_outline_rounded,
                              label: 'Questions',
                              value: '${widget.test.totalQuestions}',
                            ),
                            _ContainerDivider(),
                            _DetailItem(
                              icon: Icons.star_outline_rounded,
                              label: 'Marks',
                              value: '${widget.test.totalMarks}',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                              color: colorScheme.outline.withOpacity(0.05)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Description",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              widget.test.description.isEmpty
                                  ? "This mock test covers all important topics. Practice to improve your speed and accuracy."
                                  : widget.test.description,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                              color: colorScheme.outline.withOpacity(0.05)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Test Information",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _InfoRow(
                              icon: Icons.category_rounded,
                              label: "Category",
                              value: widget.test.category,
                            ),
                            if (widget.test.negativeMarking)
                              _InfoRow(
                                icon: Icons.warning_rounded,
                                label: "Negative Marking",
                                value:
                                    "Yes (-${widget.test.negativeMarksPerQ} per wrong)",
                                valueColor: colorScheme.error,
                              )
                            else
                              _InfoRow(
                                icon: Icons.check_circle_outline_rounded,
                                label: "Negative Marking",
                                value: "None",
                                valueColor: colorScheme.tertiary,
                              ),
                            if (widget.test.discount != null &&
                                widget.test.discount!.isNotEmpty)
                              _InfoRow(
                                icon: Icons.local_offer_rounded,
                                label: "Discount",
                                value: widget.test.discount!,
                                valueColor: colorScheme.primary,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                              color: colorScheme.outline.withOpacity(0.05)),
                        ),
                        child: _buildReviewsSection(isActuallyPurchased),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ]
                  .animate(interval: 50.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.05, end: 0),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsSection(bool isPurchased) {
    if (!_configLoaded || !AppConfigService.areReviewsVisible)
      return const SizedBox.shrink();

    final theme = Theme.of(context);
    final user = Supabase.instance.client.auth.currentUser;
    final canReview = (isPurchased || widget.test.price == 0) &&
        _userReview == null &&
        user != null &&
        AppConfigService.canWriteReviews;

    final positiveReviews = _reviews.where((r) => r.rating >= 4).toList();
    final displayedReviews = positiveReviews.take(3).toList();
    final hasMoreReviews = _reviews.length > displayedReviews.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Reviews",
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (canReview)
              TextButton(
                onPressed: _showReviewDialog,
                style: TextButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                    _userReview != null ? "Edit Review" : "Write a Review"),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (_isLoadingReviews)
          const Center(child: CircularProgressIndicator())
        else if (_reviews.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text("No reviews yet. Be the first to review!"),
            ),
          )
        else ...[
          ...displayedReviews.map((review) {
            final isOwnReview = user != null && review.userId == user.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: ReviewCard(
                review: review,
                isOwnReview: isOwnReview,
                onEdit: isOwnReview ? _showReviewDialog : null,
              ),
            );
          }),
          if (hasMoreReviews || displayedReviews.isEmpty)
            Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AllReviewsScreen(
                        itemId: widget.test.id,
                        itemType: 'test',
                        itemTitle: widget.test.title,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text("View All Reviews"),
              ),
            ),
        ],
      ],
    );
  }
}

class _ContainerDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: colorScheme.primary, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon,
              size: 20, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
          const SizedBox(width: 12),
          Text(
            "$label:",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor ?? colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
