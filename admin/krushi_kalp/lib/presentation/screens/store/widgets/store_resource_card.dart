import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/models/resource.dart';

class StoreResourceCard extends StatelessWidget {
  final Resource resource;
  final bool isPurchased;
  final bool isInCart;
  final VoidCallback onBuyTap;
  final VoidCallback onCartTap;
  final VoidCallback onTap;

  const StoreResourceCard({
    super.key,
    required this.resource,
    this.isPurchased = false,
    this.isInCart = false,
    required this.onBuyTap,
    required this.onCartTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Cover Image (Top)
              Expanded(
                flex: 4,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.radiusXl)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImage(),
                      if (resource.price == 0)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('FREE',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 2. Content (Bottom)
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title
                      Text(
                        resource.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              height: 1.2,
                            ),
                      ),

                      // Price and Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Price
                          Text(
                            resource.price == 0
                                ? 'Free'
                                : '₹${resource.price.toStringAsFixed(0)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                          ),

                          // Actions
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (resource.price > 0 &&
                                  !isPurchased &&
                                  !isInCart) ...[
                                Material(
                                  color: AppColors.neutral50,
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: onCartTap,
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: const Icon(
                                        Icons.add_shopping_cart,
                                        size: 16,
                                        color: AppColors.neutral700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              SizedBox(
                                height: 28,
                                child: ElevatedButton(
                                  onPressed: isPurchased
                                      ? onTap
                                      : (isInCart ? null : onBuyTap),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isPurchased
                                        ? AppColors.success
                                        : (isInCart
                                            ? AppColors.neutral400
                                            : AppColors.primary),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    isPurchased
                                        ? 'Read'
                                        : (isInCart
                                            ? 'In Cart'
                                            : (resource.price == 0
                                                ? 'Claim'
                                                : 'Buy')),
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (resource.thumbnailUrl != null) {
      return CachedNetworkImage(
        imageUrl: resource.thumbnailUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppColors.neutral50,
          child: const Center(
              child: Icon(Icons.image, color: AppColors.neutral400)),
        ),
        errorWidget: (context, url, error) => Container(
          color: AppColors.neutral100,
          child: const Icon(Icons.broken_image, color: AppColors.neutral400),
        ),
      );
    } else {
      return Container(
        color: AppColors.primary.withValues(alpha: 0.1),
        child: Center(
          child: Icon(
            _getIconForType(resource.type),
            size: 32,
            color: AppColors.primary.withValues(alpha: 0.4),
          ),
        ),
      );
    }
  }

  IconData _getIconForType(ResourceType type) {
    switch (type) {
      case ResourceType.eBook:
        return Icons.book;
      case ResourceType.pyq:
        return Icons.history_edu;
      case ResourceType.studyMaterial:
        return Icons.description;
      default:
        return Icons.article;
    }
  }
}
