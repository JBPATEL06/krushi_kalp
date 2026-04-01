import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';
import '../../data/services/app_config_service.dart';
import '../../data/services/offer_service.dart';
import '../../data/services/review_service.dart';
import '../../domain/models/mock_test.dart';
import '../../domain/models/offer.dart';
import '../../domain/models/review.dart';
import '../../utils/crashlytics_service.dart';
import '../../utils/responsive.dart';
import '../providers/test_notifier.dart';
import '../providers/auth_notifier.dart';
import '../widgets/reviews/review_card.dart';
import '../widgets/reviews/review_dialog.dart';
import '../widgets/reviews/rate_stars.dart';
import 'reviews/all_reviews_screen.dart';

class MockTestDetailScreen extends ConsumerStatefulWidget {
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
  ConsumerState<MockTestDetailScreen> createState() => _MockTestDetailScreenState();
}

class _MockTestDetailScreenState extends ConsumerState<MockTestDetailScreen> {
  bool _isLoadingReviews = true;
  bool _configLoaded = false;
  List<Review> _reviews = [];
  Review? _userReview;
  Map<String, dynamic> _ratingStats = {'average': 0.0, 'count': 0};
  Map<String, dynamic>? _priceData;

  @override
  void initState() {
    super.initState();
    _loadData();
    _fetchDisplayPrice();
  }

  Future<void> _fetchDisplayPrice() async {
    try {
      final data = await OfferService.instance.getDisplayPrice(
        itemType: 'mock_test',
        itemId: widget.test.id,
      );
      if (mounted) setState(() => _priceData = data);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'mock_test_detail_price');
    }
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
      final user = ref.read(authNotifierProvider).user;
      final futures = <Future>[
        ReviewService.getReviewsForItem(widget.test.id, 'test'),
        ReviewService.getRatingStats(widget.test.id, 'test'),
      ];

      if (user != null) {
        futures.add(ReviewService.getUserReview(user.id, widget.test.id, 'test'));
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
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'mock_test_detail_reviews');
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  void _showReviewDialog() {
    showDialog(
      context: context,
      builder: (_) => ReviewDialog(
        title: widget.test.title,
        initialRating: _userReview?.rating,
        initialReview: _userReview?.reviewText,
        isEdit: _userReview != null,
        onSubmit: (rating, review) async {
          final user = ref.read(authNotifierProvider).user;
          if (user == null) return;
          
          await ReviewService.submitReview(
            userId: user.id,
            itemId: widget.test.id,
            itemType: 'test',
            rating: rating,
            reviewText: review,
          );
          _loadReviews();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActuallyPurchased = ref.watch(testNotifierProvider).purchasedTestIds.contains(widget.test.id);

    // Pricing from DB RPC
    final hasOffer = _priceData?['has_discount'] ?? false;
    final displayMrp = (_priceData?['mrp_display'] as num?)?.toDouble() ?? widget.test.price;
    final displayPrice = (_priceData?['final_price'] as num?)?.toDouble() ?? widget.test.price;
    final discountLabel = _priceData?['discount_label'] as String?;

    final imageUrl = widget.test.signedUrl ?? widget.test.coverImagePath ?? '';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: context.h(300),
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: widget.heroTag != null
                  ? Hero(
                      tag: widget.heroTag!,
                      child: imageUrl.isNotEmpty 
                        ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
                        : Container(color: theme.colorScheme.surfaceContainerHighest),
                    )
                  : imageUrl.isNotEmpty
                    ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
                    : Container(color: theme.colorScheme.surfaceContainerHighest),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isActuallyPurchased, hasOffer, displayMrp, displayPrice, discountLabel),
                  const SizedBox(height: AppSpacing.lg),
                  _buildStatsRow(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildDescription(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildTestInfo(theme),
                  const SizedBox(height: AppSpacing.lg),
                  _buildReviewsSection(isActuallyPurchased),
                  SizedBox(height: context.h(100)),
                ],
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomBar(isActuallyPurchased, displayPrice),
    );
  }

  Widget _buildHeader(bool isPurchased, bool hasOffer, double mrp, double price, String? discountLabel) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.test.title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: context.sp(24),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            if (!isPurchased) ...[
              if (hasOffer && mrp > price) ...[
                Text(
                  '₹${mrp.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                price == 0 ? 'Free' : '₹${price.toStringAsFixed(0)}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              if (hasOffer && discountLabel != null) ...[
                const SizedBox(width: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    discountLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ] else ...[
              _buildPurchasedBadge(theme),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _buildRatingSummary(),
      ],
    );
  }

  Widget _buildPurchasedBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: theme.colorScheme.secondary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 16, color: theme.colorScheme.secondary),
          const SizedBox(width: 4),
          Text(
            "Purchased",
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    if (!_configLoaded || !AppConfigService.areReviewsVisible) return const SizedBox.shrink();
    return Row(
      children: [
        RateStars(
          rating: (_ratingStats['average'] as num).toDouble(),
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          '${_ratingStats['average']} (${_ratingStats['count']} reviews)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(icon: Icons.access_time, label: 'Duration', value: widget.test.time),
          _divider(),
          _StatItem(icon: Icons.help_outline, label: 'Questions', value: '${widget.test.totalQuestions}'),
          _divider(),
          _StatItem(icon: Icons.star_border, label: 'Marks', value: '${widget.test.totalMarks}'),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 40, color: Theme.of(context).dividerColor.withValues(alpha: 0.1));

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Description", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.sm),
        Text(
          widget.test.description.isEmpty 
              ? "Practice this mock test to improve your performance." 
              : widget.test.description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
      ],
    );
  }

  Widget _buildTestInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Test Information", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(icon: Icons.category_outlined, label: "Category", value: widget.test.category),
          _InfoRow(
            icon: Icons.warning_amber_rounded,
            label: "Negative Marking",
            value: widget.test.negativeMarking ? "Yes (-${widget.test.negativeMarksPerQ})" : "None",
            valueColor: widget.test.negativeMarking ? theme.colorScheme.error : theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(bool isPurchased) {
    if (!_configLoaded || !AppConfigService.areReviewsVisible) return const SizedBox.shrink();
    final user = ref.read(authNotifierProvider).user;
    final canReview = (isPurchased || widget.test.price == 0) && _userReview == null && user != null && AppConfigService.canWriteReviews;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Reviews", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            if (canReview) TextButton(onPressed: _showReviewDialog, child: const Text("Write Review")),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (_isLoadingReviews)
          const Center(child: CircularProgressIndicator())
        else if (_reviews.isEmpty)
          const Text("No reviews yet.")
        else
          ..._reviews.take(3).map((r) => ReviewCard(review: r, isOwnReview: user?.id == r.userId)),
        if (_reviews.length > 3)
          Center(
            child: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AllReviewsScreen(itemId: widget.test.id, itemType: 'test', itemTitle: widget.test.title),
                ),
              ),
              child: const Text("View All Reviews"),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar(bool isPurchased, double price) {
    final theme = Theme.of(context);
    if (isPurchased) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ElevatedButton(
          onPressed: () { /* Start Exam Logic */ },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 54),
            backgroundColor: theme.colorScheme.primary,
          ),
          child: const Text("Start Mock Test"),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text("$label:"),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor))),
        ],
      ),
    );
  }
}
