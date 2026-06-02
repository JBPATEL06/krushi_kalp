import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '../../core/theme/app_spacing.dart';
import '../providers/test_notifier.dart';
import '../providers/resource_notifier.dart';
import '../providers/auth_notifier.dart';
import '../widgets/free_content/free_item_card.dart';
import '../../domain/models/mock_test.dart';
import '../../domain/models/resource.dart';
import '../screens/mock_test_detail_screen.dart';
import '../screens/resource_detail_screen.dart';
import '../../data/services/test_service.dart';
import '../../data/services/resource_service.dart';
import '../../utils/error_utils.dart';
import '../../core/theme/app_radius.dart';
import '../../utils/crashlytics_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/common/network_error_state.dart';

class FreeContentScreen extends ConsumerStatefulWidget {
  const FreeContentScreen({super.key});

  @override
  ConsumerState<FreeContentScreen> createState() => _FreeContentScreenState();
}

class _FreeContentScreenState extends ConsumerState<FreeContentScreen> {
  static const _pageSize = 20;
  final PagingController<int, dynamic> _pagingController =
      PagingController(firstPageKey: 0);

  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
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
      List<dynamic> newItems = [];
      bool isLastPage = false;

      if (_selectedFilter == 'All') {
        // Fetch both tests and resources, then combine
        // For "All", we divide the page size between the two to keep it balanced
        final halfSize = _pageSize ~/ 2;
        final results = await Future.wait([
          TestService.instance.fetchPaginatedMockTests(
            offset: pageKey ~/ 2,
            limit: halfSize,
            isFree: true,
            searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
          ),
          ResourceService.instance.fetchPaginatedFreeResources(
            offset: pageKey ~/ 2,
            limit: halfSize,
            searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
          ),
        ]);
        
        final tests = results[0] as List<MockTest>;
        final resources = results[1] as List<Resource>;
        newItems = [...tests, ...resources];
        isLastPage = tests.length < halfSize && resources.length < halfSize;
      } else if (_selectedFilter == 'Tests') {
        final tests = await TestService.instance.fetchPaginatedMockTests(
          offset: pageKey,
          limit: _pageSize,
          isFree: true,
          searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        );
        newItems = tests;
        isLastPage = tests.length < _pageSize;
      } else {
        final resources = await ResourceService.instance.fetchPaginatedFreeResources(
          offset: pageKey,
          limit: _pageSize,
          searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        );
        newItems = resources;
        isLastPage = resources.length < _pageSize;
      }

      if (!mounted) return;

      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error, stack) {
      if (!mounted) return;
      CrashlyticsService.instance.recordError(error, stack, reason: 'free_content_fetch');
      _pagingController.error = error;
    }
  }

  void _updateFilter(String filter) {
    if (_selectedFilter == filter) return;
    setState(() {
      _selectedFilter = filter;
      _pagingController.refresh();
    });
  }

  Future<void> _claimItem({
    MockTest? test,
    Resource? resource,
  }) async {
    final String itemName = test?.title ?? resource?.title ?? 'Item';
    if (_isProcessing) return;

    try {
      final user = ref.read(authProvider).user;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login to claim')),
          );
        }
        return;
      }

      setState(() => _isProcessing = true);

      if (test != null) {
        await TestService.instance.claimFreeTest(
          testId: test.id,
          authUserId: user.id,
        );
        // Refresh states to reflect purchase
        await ref.read(testProvider.notifier).fetchUserTests(user.id);
      } else if (resource != null) {
        await ref
            .read(resourceProvider.notifier)
            .claimResource(resource.id, user.id);
        await ref.read(resourceProvider.notifier).fetchPurchasedResources(user.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Free Claimed $itemName successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        _pagingController.refresh();
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'free_content_claim');
      if (mounted) {
        ErrorUtils.showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Free Material"),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (val) {
                      _searchQuery = val.trim();
                      _pagingController.refresh();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search free content...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send_rounded),
                        onPressed: () {
                          _searchQuery = _searchController.text.trim();
                          _pagingController.refresh();
                        },
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.md, bottom: AppSpacing.md),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Tests', 'Resources'].map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: FilterChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (val) => _updateFilter(filter),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _pagingController.refresh(),
                child: PagedListView<int, dynamic>.separated(
                pagingController: _pagingController,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md + MediaQuery.of(context).padding.bottom,
                ),
                separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                builderDelegate: PagedChildBuilderDelegate<dynamic>(
                  itemBuilder: (context, item, index) {
                    if (item is MockTest) {
                      return _buildTestCard(item, index);
                    } else if (item is Resource) {
                      return _buildResourceCard(item, index);
                    }
                    return const SizedBox.shrink();
                  },
                  firstPageProgressIndicatorBuilder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                  newPageProgressIndicatorBuilder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                  noItemsFoundIndicatorBuilder: (_) => const Center(child: Text("No items found.")),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(MockTest test, int index) {
    final testState = ref.watch(testProvider);
    final uniqueTag = 'free_test_${test.id}_$index';
    final isPurchased = testState.purchasedTestIds.contains(test.id);
    
    return FreeItemCard(
      title: test.title,
      subtitle: '${test.totalQuestions} Questions',
      typeLabel: 'Mock Test',
      coverUrl: test.signedUrl,
      actionLabel: 'Free Claim',
      isPurchased: isPurchased,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MockTestDetailScreen(
              test: test,
              isPurchased: isPurchased,
              heroTag: uniqueTag,
            ),
          ),
        );
      },
      onActionTap: () => _claimItem(test: test),
      heroTag: uniqueTag,
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildResourceCard(Resource resource, int index) {
    final resourceState = ref.watch(resourceProvider);
    final uniqueTag = 'free_res_${resource.id}_$index';
    final isPurchased = resourceState.purchasedResourceIds.contains(resource.id);
    
    return FreeItemCard(
      title: resource.title,
      subtitle: resource.category ?? 'Free Material',
      typeLabel: 'Resource',
      coverUrl: resource.thumbnailUrl,
      actionLabel: 'Free Claim',
      isPurchased: isPurchased,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResourceDetailScreen(
              resource: resource,
              heroTag: uniqueTag,
            ),
          ),
        );
      },
      onActionTap: () => _claimItem(resource: resource),
      heroTag: uniqueTag,
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}
