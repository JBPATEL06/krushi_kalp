import 'package:flutter/material.dart';
import '../../data/services/app_config_service.dart';
import '../../domain/models/mock_test.dart';
import '../../domain/models/offer.dart';
import '../../utils/price_calculator.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart'; // FIXED: Added import for radius tokens

import 'package:provider/provider.dart';
import '../providers/test_provider.dart';
import '../../data/services/auth_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart'; // NEW

import '../../data/services/review_service.dart';
import '../../domain/models/review.dart';
import '../widgets/reviews/review_card.dart';
import '../widgets/reviews/review_dialog.dart';
import '../widgets/reviews/rate_stars.dart';
import 'reviews/all_reviews_screen.dart';
import '../widgets/common/responsive_wrapper.dart';

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
    // Fetch fresh configs every time this screen is opened
    await AppConfigService.fetchConfigs();
    if (mounted) setState(() => _configLoaded = true);
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    if (!mounted) return;
    setState(() => _isLoadingReviews = true);

    try {
      final user = AuthService.instance.currentUser;
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
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  void _showReviewDialog() {
    final user = AuthService.instance.currentUser;
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

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Review submitted successfully!')),
            );
            _loadReviews();
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to submit: $e')),
            );
          }
        },
        onDelete: () async {
          if (_userReview == null) return;
          try {
            await ReviewService.deleteReview(_userReview!.id);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Review deleted successfully')),
            );
            _loadReviews();
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete: $e')),
            );
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

    final theme = Theme.of(context);
    final surfaceColor = theme.colorScheme.surface;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurfaceVariant;
    final neutral200 = theme.colorScheme.surfaceContainerHighest;
    final neutral400 = theme.colorScheme.outline;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.test.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: context.sp(18), // FIXED: context.sp(18)
                )),
        backgroundColor: surfaceColor,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.close,
              color: textPrimary,
              size: context.sp(24)), // FIXED: context.sp(24)
          onPressed: () => Navigator.of(context).pop(),
        ),
        foregroundColor: textPrimary,
      ),
      body: RefreshIndicator(
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
                    height: context.h(250), // FIXED: context.h(250)
                    width: double.infinity,
                    child: CachedNetworkImage(
                      imageUrl: widget.test.signedUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: neutral200,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: neutral200,
                        child: Icon(Icons.broken_image,
                            size: context.sp(40),
                            color: neutral400), // FIXED: context.sp(40)
                      ),
                    ),
                  ),
                )
              else
                Container(
                  height: context.h(200), // FIXED: context.h(200)
                  width: double.infinity,
                  color: neutral200,
                  child: Icon(Icons.image,
                      size: context.sp(64),
                      color: neutral400), // FIXED: context.sp(64)
                ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(
                            AppRadius.lg), // FIXED: AppRadius.lg
                      ),
                      child: Builder(builder: (context) {
                        final displayOffers = widget.activeOffers
                            ?.where((o) => o.isSale)
                            .toList();
                        final priceData = PriceCalculator.calculateDisplayPrice(
                          basePrice: widget.test.price,
                          activeOffers: displayOffers,
                          testId: widget.test.id,
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
                              widget.test.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                        context.sp(22), // FIXED: context.sp(22)
                                  ),
                            ),
                            SizedBox(
                                height: context.h(AppSpacing
                                    .md)), // FIXED: context.h(AppSpacing.md)
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
                                            color: textSecondary,
                                            decoration:
                                                TextDecoration.lineThrough,
                                            fontSize: context.sp(
                                                14), // FIXED: context.sp(14)
                                          ),
                                    ),
                                    SizedBox(
                                        width: context.w(AppSpacing
                                            .sm)), // FIXED: context.w(AppSpacing.sm)
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
                                          color: textPrimary,
                                          fontSize: context
                                              .sp(20), // FIXED: context.sp(20)
                                        ),
                                  ),
                                  if (hasOffer && discPercent > 0) ...[
                                    SizedBox(
                                        width: context.w(AppSpacing
                                            .md)), // FIXED: context.w(AppSpacing.md)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: context.w(AppSpacing
                                              .sm), // FIXED: context.w(AppSpacing.sm)
                                          vertical: context
                                              .h(4)), // FIXED: context.h(4)
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme.primaryContainer
                                            .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(
                                            AppRadius
                                                .sm), // FIXED: AppRadius.sm
                                        border: Border.all(
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        '$discPercent% OFF',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: context.sp(
                                                  10), // FIXED: context.sp(10)
                                            ),
                                      ),
                                    ),
                                  ],
                                ] else ...[
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: context.w(12),
                                        vertical: context.h(
                                            6)), // FIXED: context.w(12), context.h(6)
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme.secondaryContainer
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(
                                          AppRadius
                                              .xxl), // FIXED: AppRadius.xxl
                                      border: Border.all(
                                          color: theme.colorScheme.secondary),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle,
                                            size: context.sp(
                                                16), // FIXED: context.sp(16)
                                            color: theme.colorScheme.secondary),
                                        SizedBox(
                                            width: context
                                                .w(4)), // FIXED: context.w(4)
                                        Text(
                                          "Purchased",
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    theme.colorScheme.secondary,
                                                fontSize: context.sp(
                                                    14), // FIXED: context.sp(14)
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(
                                height: context.h(AppSpacing
                                    .md)), // FIXED: context.h(AppSpacing.md)
                            // Rating Summary — only visible if reviews are enabled
                            if (_configLoaded &&
                                AppConfigService.areReviewsVisible)
                              Row(
                                children: [
                                  RateStars(
                                    rating: (_ratingStats['average'] as num)
                                        .toDouble(),
                                    size:
                                        context.sp(18), // FIXED: context.sp(18)
                                  ),
                                  SizedBox(
                                      width:
                                          context.w(8)), // FIXED: context.w(8)
                                  Text(
                                    '${_ratingStats['average']} (${_ratingStats['count']} reviews)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: textSecondary,
                                      fontSize: context
                                          .sp(14), // FIXED: context.sp(14)
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        );
                      }),
                    ),
                    SizedBox(
                        height: context.h(
                            AppSpacing.md)), // FIXED: context.h(AppSpacing.md)
                    Container(
                      padding: EdgeInsets.symmetric(
                          vertical: context.h(AppSpacing
                              .lg)), // FIXED: context.h(AppSpacing.lg)
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(
                            AppRadius.lg), // FIXED: AppRadius.lg
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
                    SizedBox(
                        height: context.h(
                            AppSpacing.md)), // FIXED: context.h(AppSpacing.md)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(
                            AppRadius.lg), // FIXED: AppRadius.lg
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
                                  fontSize:
                                      context.sp(18), // FIXED: context.sp(18)
                                ),
                          ),
                          SizedBox(
                              height: context.h(AppSpacing
                                  .sm)), // FIXED: context.h(AppSpacing.sm)
                          Text(
                            widget.test.description.isEmpty
                                ? "This mock test covers all important topics. Practice to improve your speed and accuracy."
                                : widget.test.description,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: textSecondary,
                                  height: 1.5,
                                  fontSize:
                                      context.sp(14), // FIXED: context.sp(14)
                                ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                        height: context.h(
                            AppSpacing.md)), // FIXED: context.h(AppSpacing.md)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(
                            AppRadius.lg), // FIXED: AppRadius.lg
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
                                  fontSize:
                                      context.sp(18), // FIXED: context.sp(18)
                                ),
                          ),
                          SizedBox(
                              height: context.h(AppSpacing
                                  .md)), // FIXED: context.h(AppSpacing.md)
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
                              valueColor: theme.colorScheme.error,
                            )
                          else
                            _InfoRow(
                              icon: Icons.check_circle_outline,
                              label: "Negative Marking",
                              value: "None",
                              valueColor: theme.colorScheme.primary,
                            ),
                          if (widget.test.discount != null &&
                              widget.test.discount!.isNotEmpty)
                            _InfoRow(
                              icon: Icons.local_offer_outlined,
                              label: "Discount",
                              value: widget.test.discount!,
                              valueColor: theme.colorScheme.tertiary,
                            ),
                        ],
                      ),
                    ),
                    SizedBox(
                        height: context.h(
                            AppSpacing.md)), // FIXED: context.h(AppSpacing.md)
                    _buildReviewsSection(isActuallyPurchased),
                    SizedBox(height: context.h(60)), // FIXED: context.h(60)
                    SizedBox(
                        height: AppSpacing.md +
                            MediaQuery.of(context)
                                .padding
                                .bottom), // FIXED: Standard bottom padding
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
    );
  }

  Widget _buildReviewsSection(bool isPurchased) {
    final theme = Theme.of(context);
    // Wait for config to be loaded before deciding visibility
    if (!_configLoaded) return const SizedBox.shrink();

    // Check if reviews are visible
    if (!AppConfigService.areReviewsVisible) {
      return const SizedBox.shrink();
    }

    // Check if current user is logged in
    final user = AuthService.instance.currentUser;
    final canReview = (isPurchased || widget.test.price == 0) &&
        _userReview == null &&
        user != null &&
        AppConfigService.canWriteReviews;

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
                    fontSize: context.sp(18), // FIXED: context.sp(18)
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
                    _userReview != null ? "Edit Review" : "Write a Review",
                    style: TextStyle(
                        fontSize: context.sp(14))), // FIXED: context.sp(14)
              ),
          ],
        ),

        SizedBox(
            height:
                context.h(AppSpacing.md)), // FIXED: context.h(AppSpacing.md)

        // Reviews List
        if (_isLoadingReviews)
          const Center(child: CircularProgressIndicator())
        else if (_reviews.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  vertical: context.h(20)), // FIXED: context.h(20)
              child: Text(
                "No reviews yet. Be the first to review!",
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: context.sp(14), // FIXED: context.sp(14)
                ),
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
              : Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: context.h(20)), // FIXED: context.h(20)
                    child: Text(
                      "No positive reviews to display.",
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: context.sp(14), // FIXED: context.sp(14)
                      ),
                    ),
                  ),
                )
        else
          ...displayedReviews.map((review) {
            final isOwnReview = user != null && review.userId == user.id;
            return Padding(
              padding: EdgeInsets.only(
                  bottom: context
                      .h(AppSpacing.md)), // FIXED: context.h(AppSpacing.md)
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
              icon: Icon(Icons.arrow_forward,
                  size: context.sp(16)), // FIXED: context.sp(16)
              label: Text("View All Reviews",
                  style: TextStyle(
                      fontSize: context.sp(14))), // FIXED: context.sp(14)
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
      height: context.h(40), // FIXED: context.h(40)
      width: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
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
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(context.w(8)), // FIXED: context.w(8)
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              color: theme.colorScheme.primary,
              size: context.sp(24)), // FIXED: context.sp(24)
        ),
        SizedBox(height: context.h(8)), // FIXED: context.h(8)
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: context.sp(16), // FIXED: context.sp(16)
              ),
        ),
        Text(label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              fontSize: context.sp(12), // FIXED: context.sp(12)
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
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
          bottom: context.h(AppSpacing.sm)), // FIXED: context.h(AppSpacing.sm)
      child: Row(
        children: [
          Icon(icon,
              size: context.sp(20),
              color:
                  theme.colorScheme.onSurfaceVariant), // FIXED: context.sp(20)
          SizedBox(width: context.w(12)), // FIXED: context.w(12)
          Text(
            "$label:",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              fontSize: context.sp(14), // FIXED: context.sp(14)
            ),
          ),
          SizedBox(width: context.w(8)), // FIXED: context.w(8)
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor ?? theme.colorScheme.onSurface,
                fontSize: context.sp(14), // FIXED: context.sp(14)
              ),
            ),
          ),
        ],
      ),
    );
  }
}
