import 'package:flutter/material.dart';
import '../../domain/models/resource.dart';
import '../../core/theme/app_spacing.dart';

import '../providers/resource_notifier.dart';
import '../providers/offer_notifier.dart';
import '../providers/auth_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/offer_service.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/services/app_config_service.dart';
import '../../data/services/review_service.dart';
import '../../domain/models/review.dart';
import '../widgets/reviews/review_card.dart';
import '../widgets/reviews/review_dialog.dart';
import '../widgets/reviews/rate_stars.dart';
import 'reviews/all_reviews_screen.dart';
import 'resource_files_screen.dart';
import '../../utils/crashlytics_service.dart';

class ResourceDetailScreen extends ConsumerStatefulWidget {
  final Resource resource;
  final bool isPurchased;
  final String? heroTag;

  const ResourceDetailScreen({
    super.key,
    required this.resource,
    this.isPurchased = false,
    this.heroTag,
  });

  @override
  ConsumerState<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends ConsumerState<ResourceDetailScreen> {
  bool _isLoadingReviews = true;
  bool _configLoaded = false;
  List<Review> _reviews = [];
  Review? _userReview;
  Map<String, dynamic> _ratingStats = {'average': 0.0, 'count': 0};
  // DB-driven display price
  Map<String, dynamic>? _priceData;

  @override
  void initState() {
    super.initState();
    _loadData();
    _fetchDisplayPrice();
    _refreshOwnershipIfNeeded();
  }

  /// If this resource isn't in the cached purchased set, do a fresh DB check.
  /// This handles cases where admin granted access after the user logged in.
  Future<void> _refreshOwnershipIfNeeded() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    final alreadyKnown = ref.read(resourceProvider)
        .purchasedResourceIds
        .contains(widget.resource.id);
    if (!alreadyKnown) {
      // Silently refresh purchased resources from DB
      await ref
          .read(resourceProvider.notifier)
          .fetchPurchasedResources(user.id);
    }
  }

  Future<void> _fetchDisplayPrice() async {
    final data = await OfferService.instance.getDisplayPrice(
      itemType: 'resource',
      itemId: widget.resource.id,
    );
    if (mounted) setState(() => _priceData = data);
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
      final user = ref.read(authProvider).user;
      final futures = <Future>[
        ReviewService.getReviewsForItem(widget.resource.id, 'resource'),
        ReviewService.getRatingStats(widget.resource.id, 'resource'),
      ];
      if (user != null) {
        futures.add(ReviewService.getUserReview(
            user.id, widget.resource.id, 'resource'));
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
          // _isLoadingReviews = false; // Moved to finally block
        });
      }
    } catch (e, stack) {
      CrashlyticsService.instance
          .recordError(e, stack, reason: 'resource_detail_screen');
      // if (mounted) setState(() => _isLoadingReviews = false); // Moved to finally block
    } finally {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  void _showReviewDialog() {
    final user = ref.read(authProvider).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to review')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => ReviewDialog(
        title: widget.resource.title,
        initialRating: _userReview?.rating,
        initialReview: _userReview?.reviewText,
        isEdit: _userReview != null,
        lastEditedAt: _userReview?.updatedAt,
        onSubmit: (rating, text) async {
          try {
            await ReviewService.submitReview(
              userId: user.id,
              itemId: widget.resource.id,
              itemType: 'resource',
              rating: rating,
              reviewText: text,
            );
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Review submitted successfully!')),
            );
            _loadReviews();
          } catch (e, stack) {
            CrashlyticsService.instance
                .recordError(e, stack, reason: 'resource_detail_screen');
            if (context.mounted) {
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
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Review deleted successfully')),
            );
            _loadReviews();
          } catch (e, stack) {
            CrashlyticsService.instance
                .recordError(e, stack, reason: 'resource_detail_screen');
            if (!context.mounted) return;
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resource = widget.resource;
    final isPurchased = ref.watch(resourceProvider)
        .purchasedResourceIds
        .contains(resource.id);

    // Watch for offer changes (for reactivity if offers update)
    ref.watch(offerProvider);

    // DB-driven display pricing from _priceData
    final double finalPrice =
        (_priceData?['final_price'] as double?) ?? resource.price;
    final double originalPrice =
        (_priceData?['mrp_display'] as double?) ?? resource.price;
    final bool hasDiscount = _priceData?['has_discount'] == true;

    final double percentOffComputed = originalPrice > 0
        ? (((originalPrice - finalPrice) / originalPrice) * 100).roundToDouble()
        : 0;
    final String? discountLabel = _priceData?['discount_label'] as String?;
    final String discountDisplay = discountLabel ?? '${percentOffComputed.toInt()}% OFF';

    // Base layout colors from theme
    final bgColor = theme.scaffoldBackgroundColor;
    final surfaceColor = theme.colorScheme.surface;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Resource Detail'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        foregroundColor: textPrimary,
        actions: [],
      ),
      body: RefreshIndicator(
        onRefresh: () async => await _loadReviews(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImageHeader(isDark),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- CARD 1: Title, Tags, Price, Rating ---
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            resource.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          // Price Row & Rating Section
                          if (!isPurchased && originalPrice > 0) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (hasDiscount) ...[
                                  Text(
                                    '₹${originalPrice.toStringAsFixed(0)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: textSecondary,
                                          fontWeight: FontWeight.w600,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                ],
                                Text(
                                  '₹${finalPrice.toStringAsFixed(0)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: textPrimary,
                                      ),
                                ),
                                if (hasDiscount && percentOffComputed > 0) ...[
                                  const SizedBox(width: AppSpacing.md),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color: theme.colorScheme.primary
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      discountDisplay,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ] else if (isPurchased) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: theme.colorScheme.secondary),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle,
                                      size: 16,
                                      color: theme.colorScheme.secondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Purchased',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.secondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (isPurchased) ...[
                            const SizedBox(height: AppSpacing.lg),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ResourceFilesScreen(resource: resource),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.folder_open_rounded),
                                label: Text(
                                  'OPEN FILES',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    letterSpacing: 1.1,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: AppSpacing.sm),

                          // Rating Summary
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
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // --- CARD 2: Description ---
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description',
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
                            (resource.description ?? '').isEmpty
                                ? 'No description available for this resource.'
                                : resource.description!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: textSecondary,
                                  height: 1.5,
                                ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Student Reviews Section
                    _buildReviewsSection(isPurchased, isDark, textPrimary),

                    const SizedBox(height: 60),
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
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

  Widget _buildImageHeader(bool isDark) {
    final theme = Theme.of(context);
    if (widget.resource.thumbnailUrl == null ||
        widget.resource.thumbnailUrl!.isEmpty) {
      return Hero(
        tag: widget.heroTag ?? 'resource_image_${widget.resource.id}',
        child: Container(
          height: 240,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
              ],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                widget.resource.type == ResourceType.eBook
                    ? Icons.menu_book
                    : Icons.picture_as_pdf,
                size: 100,
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
              ),
              Icon(
                widget.resource.type == ResourceType.eBook
                    ? Icons.menu_book
                    : Icons.picture_as_pdf,
                size: 60,
                color: theme.colorScheme.onPrimary,
              ),
            ],
          ),
        ),
      );
    }
    return Hero(
      tag: widget.heroTag ?? 'resource_image_${widget.resource.id}',
      child: Container(
        height: 260,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: CachedNetworkImage(
          imageUrl: widget.resource.thumbnailUrl!,
          fit: BoxFit.cover, // Immersive header
        ),
      ),
    );
  }

  Widget _buildReviewsSection(
      bool isPurchased, bool isDark, Color textPrimary) {
    final theme = Theme.of(context);
    if (!_configLoaded || !AppConfigService.areReviewsVisible) {
      return const SizedBox.shrink();
    }

    final user = ref.read(authProvider).user;
    final positiveReviews = _reviews.where((r) => r.rating >= 4).toList();
    final displayedReviews = positiveReviews.take(3).toList();
    final hasMoreReviews = _reviews.length > displayedReviews.length;
    final canReview = (isPurchased || widget.resource.price == 0) &&
        user != null &&
        AppConfigService.canWriteReviews;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reviews',
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
                    _userReview != null ? 'Edit Review' : 'Write a Review'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (_isLoadingReviews)
          const Center(child: CircularProgressIndicator())
        else if (_reviews.isEmpty)
          Center(
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text('No reviews yet. Be the first to review!',
                      style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant))))
        else if (displayedReviews.isEmpty)
          hasMoreReviews
              ? const SizedBox.shrink()
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text('No positive reviews to display.',
                        style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant)),
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
                  isFlat: false),
            );
          }),
        ],
        if (!_isLoadingReviews &&
            _reviews.isNotEmpty &&
            (hasMoreReviews || displayedReviews.isEmpty))
          Center(
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AllReviewsScreen(
                            itemId: widget.resource.id,
                            itemType: 'resource',
                            itemTitle: widget.resource.title)));
              },
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('View All Reviews'),
            ),
          ),
      ],
    );
  }
}
