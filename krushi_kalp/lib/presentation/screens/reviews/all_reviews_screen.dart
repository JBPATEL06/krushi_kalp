import 'package:flutter/material.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/services/review_service.dart';
import '../../../../domain/models/review.dart';
import '../../widgets/reviews/review_card.dart';
import '../../widgets/reviews/review_dialog.dart';

class AllReviewsScreen extends StatefulWidget {
  final int itemId;
  final String itemType;
  final String itemTitle;

  const AllReviewsScreen({
    super.key,
    required this.itemId,
    required this.itemType,
    required this.itemTitle,
  });

  @override
  State<AllReviewsScreen> createState() => _AllReviewsScreenState();
}

class _AllReviewsScreenState extends State<AllReviewsScreen> {
  bool _isLoading = true;
  List<Review> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadAllReviews();
  }

  Future<void> _loadAllReviews() async {
    setState(() => _isLoading = true);
    try {
      final reviews =
          await ReviewService.getReviewsForItem(widget.itemId, widget.itemType);

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading all reviews: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showReviewDialog(Review? existingReview) {
    if (existingReview == null) return;

    showDialog(
      context: context,
      builder: (context) => ReviewDialog(
        title: widget.itemTitle,
        initialRating: existingReview.rating,
        initialReview: existingReview.reviewText,
        isEdit: true,
        lastEditedAt: existingReview.updatedAt,
        onSubmit: (rating, text) async {
          try {
            final userId = AuthService.instance.currentUser?.id;
            if (userId == null) return;

            await ReviewService.submitReview(
              userId: userId,
              itemId: widget.itemId,
              itemType: widget.itemType,
              rating: rating,
              reviewText: text,
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Review updated successfully!')),
              );
              _loadAllReviews();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update: $e')),
              );
            }
          }
        },
        onDelete: () async {
          try {
            await ReviewService.deleteReview(existingReview.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Review deleted successfully')),
              );
              _loadAllReviews();
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
    final user = AuthService.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Reviews'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      backgroundColor: theme.colorScheme.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reviews.isEmpty
              ? const Center(child: Text("No reviews found."))
              : ListView.builder(
                  padding: EdgeInsets.only(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    top: AppSpacing.md,
                    bottom:
                        AppSpacing.md + MediaQuery.of(context).padding.bottom,
                  ),
                  itemCount: _reviews.length,
                  itemBuilder: (context, index) {
                    final review = _reviews[index];
                    final isOwnReview =
                        user != null && review.userId == user.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: ReviewCard(
                        review: review,
                        isOwnReview: isOwnReview,
                        onEdit: isOwnReview
                            ? () => _showReviewDialog(review)
                            : null,
                      ),
                    );
                  },
                ),
    );
  }
}
