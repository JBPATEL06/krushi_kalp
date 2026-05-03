import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/auth_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/models/resource.dart';
import '../providers/resource_notifier.dart';
import '../providers/auth_notifier.dart';
import '../providers/resource_state.dart';
import '../widgets/common/download_item_card.dart';
import '../../core/theme/app_spacing.dart';
import '../../utils/resource_helper.dart';
import '../widgets/common/download_action_button.dart';
import 'resource_detail_screen.dart';

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
    final user = ref.read(authProvider).user;
    if (user != null) {
      await ref.read(resourceProvider.notifier).fetchPurchasedResources(user.id);
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<Resource> _getFilteredResources(ResourceState state) {
    List<Resource> allResources;
    if (widget.category == 'E-Books') {
      allResources = state.ebooks;
    } else if (widget.category == 'Study Material') {
      allResources = state.studyMaterials;
    } else if (widget.category == 'PYQs') {
      allResources = state.pyqs;
    } else if (widget.category == 'Daily CA') {
      allResources = state.currentAffairs;
    } else {
      allResources = [];
    }

    var filtered = allResources
        .where((r) => state.purchasedResourceIds.contains(r.id))
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
    final resourceState = ref.watch(resourceProvider);
    final resources = _getFilteredResources(resourceState);

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
                            testId: resource.id.toString(),
                            filename: 'resource_${resource.id}.pdf',
                            url: resource.fileUrl,
                            startLabel: "Open",
                            isFullWidth: false,
                            userId: AuthService.instance.currentUser?.id,
                            displayName: resource.title,
                            onAction: () => _openResource(resource),
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
    final user = ref.read(authProvider).user;
    
    // Use the unified ResourceHelper (strictly in-app)
    await ResourceHelper.openResource(
      context: context,
      resource: resource,
      userId: user?.id,
    );
  }
}
