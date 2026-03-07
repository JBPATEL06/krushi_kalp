import 'package:flutter/material.dart';
import '../../../../data/services/review_service.dart';
import '../../../../domain/models/review.dart';
import 'package:krushi_kalp/core/theme/app_spacing.dart';
import 'package:krushi_kalp/core/theme/app_radius.dart';
import 'package:intl/intl.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  bool _isLoading = true;
  List<Review> _reviews = [];
  String _filter = 'all'; // 'all', 'test', 'resource'

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    try {
      final itemType = _filter == 'all' ? null : _filter;
      final reviews =
          await ReviewService.getAllReviews(limit: 50, itemType: itemType);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading reviews: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteReview(int reviewId) async {
    try {
      await ReviewService.deleteReview(reviewId);
      setState(() {
        _reviews.removeWhere((r) => r.id == reviewId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  void _confirmDelete(Review review) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Review"),
        content: const Text(
            "Are you sure you want to delete this review? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteReview(review.id);
            },
            style:
                TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text("Manage Reviews"),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              // Filter Row
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                      bottom: BorderSide(
                          color: colorScheme.outlineVariant.withOpacity(0.5))),
                ),
                child: Row(
                  children: [
                    Text(
                      "FILTER",
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All', 'all'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Mock Tests', 'test'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Resources', 'resource'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _reviews.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: EdgeInsets.only(
                              top: 8,
                              bottom: 8 + MediaQuery.of(context).padding.bottom,
                            ),
                            itemCount: _reviews.length,
                            itemBuilder: (context, index) {
                              return _buildReviewRow(context, _reviews[index]);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewRow(BuildContext context, Review review) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border(
            bottom:
                BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: review.userAvatarUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(review.userAvatarUrl!,
                            fit: BoxFit.cover),
                      )
                    : Center(
                        child: Text(
                          review.userName.isNotEmpty
                              ? review.userName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          review.userName.isEmpty
                              ? 'Unknown User'
                              : review.userName,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded,
                              color: colorScheme.error.withOpacity(0.5),
                              size: 18),
                          onPressed: () => _confirmDelete(review),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Rating
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < review.rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 18,
                            color: const Color(0xFFF59E0B),
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat.yMMMd().format(review.createdAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant
                                  .withOpacity(0.7)),
                        ),
                      ],
                    ),
                    if (review.reviewText != null &&
                        review.reviewText!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        review.reviewText!,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.8),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined,
              size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.3)),
          const SizedBox(height: AppSpacing.md),
          Text("No reviews found",
              style: TextStyle(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _filter == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (isSelected) return;
        setState(() => _filter = value);
        _loadReviews();
      },
      selectedColor: colorScheme.primary.withOpacity(0.1),
      checkmarkColor: colorScheme.primary,
      backgroundColor: colorScheme.surface,
      side: BorderSide(
        color: isSelected
            ? colorScheme.primary
            : colorScheme.outline.withOpacity(0.2),
        width: isSelected ? 1.5 : 1,
      ),
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md)),
    );
  }
}
