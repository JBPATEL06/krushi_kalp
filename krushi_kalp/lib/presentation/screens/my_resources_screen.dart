import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/models/resource.dart';
import '../../data/services/resource_service.dart';
import '../providers/auth_notifier.dart';
import '../../core/theme/app_spacing.dart';
import '../widgets/common/download_item_card.dart';
import 'resource_detail_screen.dart';
import 'resource_files_screen.dart';
import '../widgets/common/network_error_state.dart';

class MyResourcesScreen extends ConsumerStatefulWidget {
  final String title;
  final String category;

  const MyResourcesScreen({
    super.key,
    required this.title,
    required this.category,
  });

  @override
  ConsumerState<MyResourcesScreen> createState() => _MyResourcesScreenState();
}

class _MyResourcesScreenState extends ConsumerState<MyResourcesScreen> {
  static const _pageSize = 20;
  final PagingController<int, Resource> _pagingController =
      PagingController(firstPageKey: 0);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortOption = 'Newest';

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase();
      if (_searchQuery != query) {
        _searchQuery = query;
        _pagingController.refresh();
      }
    });
  }

  @override
  void dispose() {
    _pagingController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final user = ref.read(authProvider).user;
      if (user == null) {
        _pagingController.appendLastPage([]);
        return;
      }

      final newItems = await ResourceService.instance.fetchPaginatedPurchasedResources(
        userId: user.id,
        offset: pageKey,
        limit: _pageSize,
      );

      // Filter by current category and search query
      ResourceType? targetType;
      switch (widget.category) {
        case 'E-Books': targetType = ResourceType.eBook; break;
        case 'Study Material': targetType = ResourceType.studyMaterial; break;
        case 'PYQs': targetType = ResourceType.pyq; break;
        case 'Daily CA': targetType = ResourceType.currentAffair; break;
      }

      var filtered = newItems.where((r) {
        final matchesCategory = targetType == null || r.type == targetType;
        final matchesSearch = _searchQuery.isEmpty || r.title.toLowerCase().contains(_searchQuery);
        return matchesCategory && matchesSearch;
      }).toList();

      if (_sortOption == 'Newest') {
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else if (_sortOption == 'Oldest') {
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      } else if (_sortOption == 'A-Z') {
        filtered.sort((a, b) => a.title.compareTo(b.title));
      }

      final isLastPage = newItems.length < _pageSize;
      if (!mounted) return;

      if (isLastPage) {
        _pagingController.appendLastPage(filtered);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _pagingController.appendPage(filtered, nextPageKey);
      }
    } catch (error) {
      if (!mounted) return;
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async => _pagingController.refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(context),
            SliverToBoxAdapter(
              child: _buildSearchAndFilterBar(theme),
            ),
            PagedSliverList<int, Resource>(
              pagingController: _pagingController,
              builderDelegate: PagedChildBuilderDelegate<Resource>(
                itemBuilder: (context, resource, index) {
                  final bottomPadding = index == _pagingController.itemList!.length - 1
                      ? AppSpacing.md + MediaQuery.of(context).padding.bottom
                      : AppSpacing.md;
                  return Padding(
                    padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, bottomPadding),
                    child: DownloadItemCard(
                      title: resource.title,
                      subtitle: resource.description,
                      coverUrl: resource.thumbnailUrl,
                      heroTag: 'resource_image_${resource.id}',
                      customAction: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ResourceFilesScreen(resource: resource),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.colorScheme.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                        ),
                        child: Text(
                          "Open",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ResourceDetailScreen(
                              resource: resource,
                              isPurchased: true,
                              heroTag: 'resource_image_${resource.id}',
                            ),
                          ),
                        );
                      },
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
                },
                firstPageProgressIndicatorBuilder: (_) => const Center(child: CircularProgressIndicator()),
                newPageProgressIndicatorBuilder: (_) => const Center(child: CircularProgressIndicator()),
                noItemsFoundIndicatorBuilder: (_) => _buildEmptyState(),
                firstPageErrorIndicatorBuilder: (_) => NetworkErrorState(
                  error: _pagingController.error,
                  onRetry: () => _pagingController.refresh(),
                ),
                newPageErrorIndicatorBuilder: (_) => NetworkErrorState(
                  error: _pagingController.error,
                  onRetry: () => _pagingController.retryLastFailedRequest(),
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
        style: const TextStyle(
          color: Colors.black, // Explicitly black as per user's previous preference in other screens if theme is light
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search purchased items...',
              prefixIcon:
                  Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
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
          _pagingController.refresh();
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


}
