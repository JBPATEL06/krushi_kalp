import 'package:flutter/material.dart';
import '../../domain/models/resource.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/resource_provider.dart';
import '../providers/offer_provider.dart'; // NEW
import '../../utils/price_calculator.dart'; // NEW
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import '../../data/services/download_service.dart';
import '../widgets/common/download_progress_dialog.dart';
import 'pdf_viewer_screen.dart';

class ResourceDetailScreen extends StatefulWidget {
  final Resource resource;
  final String? heroTag; // NEW

  const ResourceDetailScreen({
    super.key,
    required this.resource,
    this.heroTag,
  });

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final resource = widget.resource;
    final isPurchased = context
        .watch<ResourceProvider>()
        .purchasedResourceIds
        .contains(resource.id);
    final isInCart = context.watch<CartProvider>().isItemInCart(resource.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(resource.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Image
            Hero(
              tag: widget.heroTag ?? 'resource_image_${resource.id}',
              child: Container(
                height: 200,
                width: double.infinity,
                child: resource.thumbnailUrl != null &&
                        resource.thumbnailUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: resource.thumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.neutral50,
                          child: const Center(
                            child:
                                Icon(Icons.image, color: AppColors.neutral400),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.neutral100,
                          child: const Icon(Icons.broken_image,
                              color: AppColors.neutral400),
                        ),
                        imageBuilder: (context, imageProvider) => Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusXl),
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusXl),
                        ),
                        child: const Center(
                          child: Icon(Icons.description,
                              size: 64, color: AppColors.neutral300),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // 2. Title & Price
            Text(
              resource.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              resource.category ?? resource.type.name.toUpperCase(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 3. Price
            if (!isPurchased)
              Row(
                children: [
                  Text(
                    resource.price == 0
                        ? 'Free'
                        : '₹${resource.price.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.xl),

            // 4. Description
            if (resource.description != null) ...[
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                resource.description!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed:
                isPurchased ? _downloadOrOpen : (isInCart ? null : _addToCart),
            style: ElevatedButton.styleFrom(
              backgroundColor: isPurchased
                  ? AppColors.secondary
                  : (resource.price == 0
                      ? AppColors.success
                      : AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    isPurchased
                        ? 'Download'
                        : (resource.price == 0
                            ? 'Claim Now'
                            : (isInCart ? 'In Cart' : 'Add to Cart')),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadOrOpen() async {
    final filename =
        'resource_${widget.resource.id}_${widget.resource.title.replaceAll(" ", "_")}';

    // Check if already downloaded
    final isDownloaded = await DownloadService().isFileDownloaded(filename);

    if (isDownloaded) {
      // Open file directly
      final path = await DownloadService().getLocalPath(filename);
      if (await File(path).exists()) {
        _openFile(File(path));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('File not found. Please download again.')),
          );
        }
      }
    } else {
      // Check file URL
      if (widget.resource.fileUrl == null || widget.resource.fileUrl!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File URL not available')),
          );
        }
        return;
      }

      // Show download progress dialog
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => DownloadProgressDialog(
          url: widget.resource.fileUrl!,
          filename: filename,
          displayName: widget.resource.title,
          onComplete: (path) {
            // Open file after download
            _openFile(File(path));
          },
          onError: () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Download failed. Please try again.')),
              );
            }
          },
        ),
      );
    }
  }

  void _openFile(File file) {
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

  Future<void> _addToCart() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please login to purchase.')));
        }
        return;
      }

      if (widget.resource.price == 0) {
        // Claim Logic
        await context
            .read<ResourceProvider>()
            .claimResource(widget.resource.id, user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Claimed ${widget.resource.title} successfully!'),
            backgroundColor: AppColors.success,
          ));
        }
      } else {
        double finalPrice = widget.resource.price;
        try {
          final activeOffers = context.read<OfferProvider>().activeOffers;
          if (activeOffers.isNotEmpty) {
            final priceData = PriceCalculator.calculateDisplayPrice(
              basePrice: widget.resource.price,
              activeOffers: activeOffers,
              resourceId: widget.resource.id,
            );
            finalPrice = priceData['finalPrice'];
          }
        } catch (_) {}

        await context.read<CartProvider>().addToCart(
            resourceId: widget.resource.id,
            price: finalPrice,
            authUserId: user.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Added ${widget.resource.title} to Cart')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
