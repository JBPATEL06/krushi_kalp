import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class StoreHeader extends StatelessWidget {
  final String selectedCategory;
  final String sortOption;
  final ValueChanged<String> onSortChanged;

  const StoreHeader({
    super.key,
    required this.selectedCategory,
    required this.sortOption,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedCategory == 'All' ? 'Mock Tests' : selectedCategory,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            // Sort Button
            PopupMenuButton<String>(
              offset: const Offset(0, 40),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
              color: AppColors.surface,
              onSelected: onSortChanged,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'Latest',
                  child: Row(
                    children: [
                      const Icon(Icons.new_releases_outlined, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Latest',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'Price: Low to High',
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_upward, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Price: Low to High',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'Price: High to Low',
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_downward, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Price: High to Low',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary, // Black/Dark
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sort, size: 16, color: Colors.white),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      sortOption,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(Icons.keyboard_arrow_down,
                        size: 16, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
