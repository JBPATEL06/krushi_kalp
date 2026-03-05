import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'rate_stars.dart';

class ReviewDialog extends StatefulWidget {
  final String title;
  final double? initialRating;
  final String? initialReview;
  final bool isEdit;
  final DateTime? lastEditedAt;
  final Function(double rating, String review) onSubmit;
  final VoidCallback? onDelete; // NEW

  const ReviewDialog({
    super.key,
    required this.title,
    this.initialRating,
    this.initialReview,
    this.isEdit = false,
    this.lastEditedAt,
    required this.onSubmit,
    this.onDelete, // NEW
  });

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  late double _rating;
  late TextEditingController _reviewController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating ?? 0;
    _reviewController = TextEditingController(text: widget.initialReview);
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Simulate slight delay or just call callback
    // The parent is responsible for the actual async call usually,
    // but here we just pass data back.

    await widget.onSubmit(_rating, _reviewController.text.trim());

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.of(context).pop(); // Close dialog on success
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isEdit ? 'Edit Review' : 'Rate & Review',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (widget.isEdit && widget.onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.error),
                        onPressed: () {
                          // Confirm delete?
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Delete Review?"),
                              content: const Text(
                                  "Are you sure you want to delete your review?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx); // Close confirm
                                    widget.onDelete!();
                                    Navigator.pop(
                                        context); // Close review dialog
                                  },
                                  child: const Text("Delete",
                                      style: TextStyle(color: AppColors.error)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    IconButton(
                      icon:
                          const Icon(Icons.close, color: AppColors.neutral500),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),

            if (widget.isEdit && widget.lastEditedAt != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Last edited on: ${_formatDate(widget.lastEditedAt!)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral400,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Star Rating
            Center(
              child: RateStars(
                rating: _rating,
                size: 40,
                isInteractive: true,
                onRatingChanged: (val) => setState(() => _rating = val),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Text(
                _getRatingLabel(_rating),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Review Text Field
            TextField(
              controller: _reviewController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share your experience (optional)...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.neutral300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.neutral300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.all(AppSpacing.md),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Submit Feedback',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingLabel(double rating) {
    if (rating == 0) return 'Tap stars to rate';
    if (rating <= 1) return 'Poor';
    if (rating <= 2) return 'Fair';
    if (rating <= 3) return 'Good';
    if (rating <= 4) return 'Very Good';
    return 'Excellent';
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
