import 'package:flutter/material.dart';
import '../../domain/models/resource.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

import 'package:provider/provider.dart';
import '../providers/resource_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'pdf_viewer_screen.dart';
import 'dart:io';
import '../../data/services/download_service.dart'; // NEW

import '../../data/services/app_config_service.dart';
import '../../data/services/review_service.dart';
import '../../domain/models/review.dart';
import '../widgets/reviews/review_card.dart';
import '../widgets/reviews/review_dialog.dart';
import '../widgets/reviews/rate_stars.dart';
import 'reviews/all_reviews_screen.dart'; // NEW

class ResourceDetailScreen extends StatefulWidget {
  final Resource resource;
  final bool isPurchased;
  final String? heroTag;

  const ResourceDetailScreen({
    required this.resource,
    this.isPurchased = false,
    this.heroTag,
  });

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  // Reviews State
  bool _isLoadingReviews = true;
  bool _configLoaded = false;
  List<Review> _reviews = [];
  Review? _userReview;
  Map<String, dynamic> _ratingStats = {'average': 0.0, 'count': 0};
  bool _isDownloading = false;

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
      final user = Supabase.instance.client.auth.currentUser;
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

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Review submitted successfully!')),
              );
              _loadReviews(); // Refresh list
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
              _loadReviews(); // Refresh
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

  Future<void> _openPdf() async {
    if (widget.resource.fileUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PDF URL is missing")),
      );
      return;
    }

    setState(() => _isDownloading = true);
    try {
      final url = widget.resource.fileUrl!;

      // 1. Define a clean, safe filename (ID based to avoid length issues)
      final filename = 'resource_${widget.resource.id}.pdf';

      // 2. Use DownloadService to handle the download/caching
      final downloadService = DownloadService();
      final path = await downloadService.downloadFile(url, filename);
      final file = File(path);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewerScreen(
              file: file,
              title: widget.resource.title,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error opening PDF: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error opening PDF: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resource = widget.resource;
    // Check purchase status from provider (real-time)
    final isPurchased = context
        .watch<ResourceProvider>()
        .purchasedResourceIds
        .contains(widget.resource.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(resource.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // refresh
            await _loadReviews();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. HEADER IMAGE
                if (widget.resource.thumbnailUrl != null &&
                    widget.resource.thumbnailUrl!.isNotEmpty)
                  Hero(
                    tag: widget.heroTag ??
                        'resource_image_${widget.resource.id}',
                    child: SizedBox(
                      height: 250,
                      width: double.infinity,
                      child: CachedNetworkImage(
                        imageUrl: widget.resource.thumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.neutral200,
                          child:
                              const Center(child: CircularProgressIndicator()),
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
                    child: const Icon(Icons.menu_book,
                        size: 64, color: AppColors.neutral400),
                  ),

                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      // 2. TITLE & TYPE CARD
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusLg),
                        ),
                        child: Column(
                          children: [
                            Text(
                              widget.resource.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              widget.resource.type.name.toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // 3. PRICE / STATUS
                            if (widget.resource.price > 0 && !isPurchased) ...[
                              Text(
                                '₹${widget.resource.price.toStringAsFixed(0)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                              ),
                            ] else if (isPurchased) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.success),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle,
                                        size: 16, color: AppColors.success),
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
                            ] else ...[
                              Text(
                                'Free',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                    ),
                              ),
                            ],

                            const SizedBox(height: AppSpacing.md),
                            // Rating Summary — only visible if reviews are enabled
                            if (_configLoaded &&
                                AppConfigService.areReviewsVisible)
                              Row(
                                mainAxisSize: MainAxisSize.min,
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
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // 4. DESCRIPTION CARD
                      Container(
                        width: double.infinity,
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
                              "About this Resource",
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
                              (widget.resource.description ?? "").isEmpty
                                  ? "No description available."
                                  : widget.resource.description!,
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

                      // 5. ACTION BUTTON (View PDF / Buy)
                      if (isPurchased || widget.resource.price == 0)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _isDownloading
                                ? null
                                : () {
                                    // All resources (E-Books, PYQs, etc.) in this app are PDFs.
                                    _openPdf();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd),
                              ),
                            ),
                            icon: _isDownloading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.visibility),
                            label: Text(_isDownloading
                                ? "Downloading..."
                                : "View Resource"),
                          ),
                        ),

                      const SizedBox(height: AppSpacing.md),

                      // 6. REVIEWS SECTION CARD
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusLg),
                        ),
                        child: _buildReviewsSection(isPurchased),
                      ),

                      const SizedBox(height: 60), // Bottom padding
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

  Widget _buildReviewsSection(bool isPurchased) {
    // Check if current user is logged in
    final user = Supabase.instance.client.auth.currentUser;
    // Show top 3 POSITIVE reviews (4 or 5 stars) first to encourage sales
    final positiveReviews =
        _reviews.where((r) => r.rating >= 4).take(3).toList();
    final displayedReviews = positiveReviews.isNotEmpty
        ? positiveReviews
        : _reviews.take(3).toList();
    final hasMoreReviews = _reviews.length > displayedReviews.length;

    // Wait for config to be loaded before deciding visibility
    if (!_configLoaded) return const SizedBox.shrink();

    // Check if reviews are visible
    if (!AppConfigService.areReviewsVisible) {
      return const SizedBox.shrink(); // Hide reviews if disabled
    }

    // Check if user can review (bought it or it's free)
    // AND hasn't reviewed yet
    // AND writing reviews is allowed by admin
    final canReview = (isPurchased || widget.resource.price == 0) &&
        _userReview == null &&
        user != null &&
        AppConfigService.canWriteReviews;

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
          hasMoreReviews
              ? const SizedBox.shrink()
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
                      itemId: widget.resource.id,
                      itemType: 'resource',
                      itemTitle: widget.resource.title,
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
