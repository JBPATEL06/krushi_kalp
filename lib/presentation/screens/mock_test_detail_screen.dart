import 'package:flutter/material.dart';
import '../../domain/models/mock_test.dart';
import '../../domain/models/offer.dart';
import '../../utils/price_calculator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

import 'package:provider/provider.dart';
import '../providers/test_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart'; // NEW

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
  List<Review> _reviews = [];
  Review? _userReview;
  Map<String, dynamic> _ratingStats = {'average': 0.0, 'count': 0};

  @override
  void initState() {
    super.initState();
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
    final provider = context.watch<TestProvider>();
    final isActuallyPurchased = widget.isPurchased ||
        provider.purchasedTests.any((t) => t.id == widget.test.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.test.title,
            style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: RefreshIndicator(
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
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusLg),
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
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
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
                                          borderRadius:
                                              BorderRadius.circular(4),
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.success.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: AppColors.success),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_circle,
                                              size: 16,
                                              color: AppColors.success),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Purchased",
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.success,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSecondary,
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
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusLg),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _DetailItem(
                              icon: Icons.access_time,
                              label: 'Duration',
                              value: widget.test.time,
                            ),
                            _ContainerDivider(),
                            _DetailItem(
                              icon: Icons.help_outline,
                              label: 'Questions',
                              value: '${widget.test.totalQuestions}',
                            ),
                            _ContainerDivider(),
                            _DetailItem(
                              icon: Icons.star_border,
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
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusLg),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Description",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              widget.test.description.isEmpty
                                  ? "This mock test covers all important topics. Practice to improve your speed and accuracy."
                                  : widget.test.description,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
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
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusLg),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Test Information",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _InfoRow(
                              icon: Icons.category_outlined,
                              label: "Category",
                              value: widget.test.category,
                            ),
                            if (widget.test.negativeMarking)
                              _InfoRow(
                                icon: Icons.warning_amber_rounded,
                                label: "Negative Marking",
                                value:
                                    "Yes (-${widget.test.negativeMarksPerQ} per wrong)",
                                valueColor: AppColors.error,
                              )
                            else
                              const _InfoRow(
                                icon: Icons.check_circle_outline,
                                label: "Negative Marking",
                                value: "None",
                                valueColor: AppColors.success,
                              ),
                            if (widget.test.discount != null &&
                                widget.test.discount!.isNotEmpty)
                              _InfoRow(
                                icon: Icons.local_offer_outlined,
                                label: "Discount",
                                value: widget.test.discount!,
                                valueColor: Colors.orange[700],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusLg),
                        ),
                        child: _buildReviewsSection(isActuallyPurchased),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ]
                  .animate(interval: 50.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1, end: 0),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsSection(bool isPurchased) {
    // Check if current user is logged in
    final user = Supabase.instance.client.auth.currentUser;
    final canReview = user != null && isPurchased;

    // Filter for positive reviews (4 or 5 stars)
    final positiveReviews = _reviews.where((r) => r.rating >= 4).toList();
    final displayedReviews = positiveReviews.take(3).toList();
    // Show "View All" if there are ANY reviews not currently displayed
    // (e.g. negative reviews, or more positive reviews than the limit)
    final hasMoreReviews = _reviews.length > displayedReviews.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Reviews",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
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

        // Reviews List
        if (_isLoadingReviews)
          const Center(child: CircularProgressIndicator())
        else if (_reviews.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                "No reviews yet. Be the first to review!",
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else if (displayedReviews.isEmpty)
          // If we have reviews but NONE are positive, effectively show nothing
          // but the 'View All' button should appear if strictly following logic.
          // However, UX-wise, it might be better to show "No positive reviews yet"
          // or just show the "View All Reviews" button immediately.
          // Let's just show the View All button if hasMoreReviews is true.
          hasMoreReviews
              ? const SizedBox
                  .shrink() // Don't show any cards, just the button below
              : const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      "No positive reviews to display.",
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
        else
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

        if (!(_isLoadingReviews) &&
            (_reviews.isNotEmpty) &&
            (hasMoreReviews || displayedReviews.isEmpty))
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
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text("View All Reviews"),
            ),
          ),
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
      color: AppColors.neutral200,
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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
        ),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.neutral500),
          const SizedBox(width: 12),
          Text(
            "$label:",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.neutral600,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(width: 8),
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
