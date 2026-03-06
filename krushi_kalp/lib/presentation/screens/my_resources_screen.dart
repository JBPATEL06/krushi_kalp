import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../data/services/auth_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/models/resource.dart';
import '../providers/resource_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/common/download_item_card.dart';
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
    final theme = Theme.of(context);
    final provider = context.watch<ResourceProvider>();
    final resources = _getFilteredResources(provider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(context),
            SliverToBoxAdapter(
              child: _buildSearchAndFilterBar(theme),
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
                        child: DownloadItemCard(
                          title: resource.title,
                          subtitle: resource.description,
                          coverUrl: resource.thumbnailUrl,
                          heroTag: 'resource_image_${resource.id}',
                          customAction: DownloadActionButton(
                            filename: 'resource_${resource.id}.pdf',
                            url: resource.fileUrl,
                            startLabel: "Open",
                            isFullWidth: false,
                            onAction: () => _openResource(resource),
                          ),
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
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return SliverAppBar(
      floating: false,
      pinned: true,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.title,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar(ThemeData theme) {
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
              prefixIcon:
                  Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
              filled: true,
              fillColor:
                  theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
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
                _buildFilterChip(theme, 'Newest'),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip(theme, 'Oldest'),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip(theme, 'A-Z'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(ThemeData theme, String label) {
    final isSelected = _sortOption == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _sortOption = label;
        });
      },
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      checkmarkColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _searchQuery.isNotEmpty
                ? 'No matches found.'
                : 'No purchased resources yet.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openResource(Resource resource) async {
    final filename = 'resource_${resource.id}.pdf';
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return;

    // Check if already downloaded
    final isDownloaded =
        await DownloadService().isFileDownloaded(filename, userId: userId);

    if (isDownloaded) {
      // Already downloaded - open file directly
      final path =
          await DownloadService().getLocalPath(filename, userId: userId);
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
      _downloadAndOpen(resource, filename, userId);
    }
  }

  Future<void> _downloadAndOpen(
      Resource resource, String filename, String userId) async {
    if (!mounted) return;

    // Capture outer context for use inside onComplete
    final outerContext = context;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DownloadProgressDialog(
        url: resource.fileUrl!,
        filename: filename,
        displayName: resource.title,
        userId: userId, // ← REQUIRED for ownership manifest
        onComplete: (path) {
          // Open file after download
          if (!outerContext.mounted) return;
          Navigator.push(
            outerContext,
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
            ScaffoldMessenger.of(outerContext).showSnackBar(
              const SnackBar(
                  content: Text('Download failed. Please try again.')),
            );
          }
        },
      ),
    );
  }
}
