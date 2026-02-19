import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:flutter_animate/flutter_animate.dart'; // NEW
import '../../domain/models/resource.dart';
import '../providers/resource_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/common/universal_item_card.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/services/download_service.dart';
import '../widgets/common/download_progress_dialog.dart';
import '../widgets/common/download_action_button.dart';
import 'pdf_viewer_screen.dart';

class MyResourcesScreen extends StatefulWidget {
  final String title;
  final String category;

  const MyResourcesScreen({
    super.key,
    required this.title,
    required this.category,
  });

  @override
  State<MyResourcesScreen> createState() => _MyResourcesScreenState();
}

class _MyResourcesScreenState extends State<MyResourcesScreen> {
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortOption = 'Newest';

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      await context.read<ResourceProvider>().fetchPurchasedResources(user.id);
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<Resource> _getFilteredResources(ResourceProvider provider) {
    List<Resource> allResources;
    if (widget.category == 'E-Books') {
      allResources = provider.ebooks;
    } else if (widget.category == 'Study Materials') {
      allResources = provider.studyMaterials;
    } else if (widget.category == 'PYQs') {
      allResources = provider.pyqs;
    } else if (widget.category == 'Current Affairs') {
      allResources = provider.currentAffairs;
    } else {
      allResources = [];
    }

    var filtered = allResources
        .where((r) => provider.purchasedResourceIds.contains(r.id))
        .toList();

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((r) => r.title.toLowerCase().contains(_searchQuery))
          .toList();
    }

    if (_sortOption == 'Newest') {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortOption == 'Oldest') {
      filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else if (_sortOption == 'A-Z') {
      filtered.sort((a, b) => a.title.compareTo(b.title));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResourceProvider>();
    final resources = _getFilteredResources(provider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: _buildSearchAndFilterBar(),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (resources.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final resource = resources[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: UniversalItemCard(
                        title: resource.title,
                        subtitle: resource.description,
                        price: resource.price,
                        coverUrl: resource.thumbnailUrl,
                        customAction: DownloadActionButton(
                          filename:
                              'resource_${resource.id}_${resource.title.replaceAll(" ", "_")}',
                          url: resource.fileUrl,
                          startLabel: "Open",
                          onAction: () => _openResource(resource),
                        ),
                        isPurchased: true,
                        onTap: () => _openResource(resource),
                      ),
                    )
                        .animate(delay: (index < 5 ? index * 100 : 0).ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0);
                  },
                  childCount: resources.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      floating: false,
      pinned: true,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.neutral900),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search purchased items...',
              prefixIcon: const Icon(Icons.search, color: AppColors.neutral500),
              filled: true,
              fillColor: AppColors.neutral100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Sort Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Newest'),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Oldest'),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('A-Z'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _sortOption == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _sortOption = label;
        });
      },
      selectedColor: AppColors.primary.withOpacity(0.1),
      checkmarkColor: AppColors.primary,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.neutral200,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppColors.neutral400,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _searchQuery.isNotEmpty
                ? 'No matches found.'
                : 'No purchased resources yet.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _openResource(Resource resource) async {
    final filename =
        'resource_${resource.id}_${resource.title.replaceAll(" ", "_")}';

    // Check if already downloaded
    final isDownloaded = await DownloadService().isFileDownloaded(filename);

    if (isDownloaded) {
      // Already downloaded - open file directly
      final path = await DownloadService().getLocalPath(filename);
      if (await File(path).exists()) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PdfViewerScreen(
                file: File(path),
                title: resource.title,
              ),
            ),
          );
        }
      }
    } else {
      // Not downloaded - directly download (no online view option)
      if (resource.fileUrl == null || resource.fileUrl!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File URL not available')),
          );
        }
        return;
      }

      if (!mounted) return;

      // Directly download and open
      _downloadAndOpen(resource, filename);
    }
  }

  Future<void> _downloadAndOpen(Resource resource, String filename) async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DownloadProgressDialog(
        url: resource.fileUrl!,
        filename: filename,
        displayName: resource.title,
        onComplete: (path) {
          // Open file after download
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PdfViewerScreen(
                file: File(path),
                title: resource.title,
              ),
            ),
          );
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
