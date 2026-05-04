import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../domain/models/mock_test.dart';
import '../../data/services/test_service.dart';
import '../utils/exam_helper.dart';
import '../../utils/responsive.dart';
import '../../core/theme/app_spacing.dart';
import '../providers/auth_notifier.dart';
import '../providers/navigation_notifier.dart';
import '../widgets/common/download_item_card.dart';
import '../widgets/common/download_action_button.dart';
import 'mock_test_detail_screen.dart';
import '../widgets/common/network_error_state.dart';

class PurchasedTestsScreen extends ConsumerStatefulWidget {
  const PurchasedTestsScreen({super.key});

  @override
  ConsumerState<PurchasedTestsScreen> createState() => _PurchasedTestsScreenState();
}

class _PurchasedTestsScreenState extends ConsumerState<PurchasedTestsScreen> {
  static const _pageSize = 20;
  final PagingController<int, MockTest> _pagingController =
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

      final newItems = await TestService.instance.fetchPaginatedUserTests(
        authUserId: user.id,
        offset: pageKey,
        limit: _pageSize,
      );

      // Filtering and sorting on the client side since user tests are usually few
      // But we still paginate the initial fetch for safety
      var filtered = List<MockTest>.from(newItems);
      if (_searchQuery.isNotEmpty) {
        filtered = filtered.where((t) => t.title.toLowerCase().contains(_searchQuery)).toList();
      }

      if (_sortOption == 'Newest') {
        filtered.sort((a, b) => b.id.compareTo(a.id));
      } else if (_sortOption == 'Oldest') {
        filtered.sort((a, b) => a.id.compareTo(b.id));
      } else if (_sortOption == 'A-Z') {
        filtered.sort((a, b) => a.title.compareTo(b.title));
      }

      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(filtered);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _pagingController.appendPage(filtered, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () async => _pagingController.refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(context, theme),
            SliverToBoxAdapter(
              child: _buildSearchAndFilterBar(context, theme),
            ),
            PagedSliverList<int, MockTest>(
              pagingController: _pagingController,
              builderDelegate: PagedChildBuilderDelegate<MockTest>(
                  final bottomPadding = index == _pagingController.itemList!.length - 1
                      ? AppSpacing.md + MediaQuery.of(context).padding.bottom
                      : AppSpacing.md;
                  return Padding(
                    padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, bottomPadding),
                    child: DownloadItemCard(
                      title: item.title,
                      subtitle: '${item.totalQuestions} Questions',
                      coverUrl: item.signedUrl,
                      heroTag: 'test_image_${item.id}',
                      customAction: DownloadActionButton(
                        testId: item.id.toString(),
                        filename: 'mock_test_${item.id}.json',
                        url: item.filePath,
                        startLabel: "Start",
                        isFullWidth: false,
                        userId: ref.read(authProvider).user?.id,
                        displayName: item.title,
                        onAction: () async {
                          await ExamHelper.startExam(context, item);
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MockTestDetailScreen(
                              test: item,
                              isPurchased: true,
                              activeOffers: const [],
                              heroTag: 'test_image_${item.id}',
                            ),
                          ),
                        );
                      },
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
                },
                firstPageProgressIndicatorBuilder: (_) => _buildSkeletonLoader(context, theme),
                newPageProgressIndicatorBuilder: (_) => const Center(child: CircularProgressIndicator()),
                noItemsFoundIndicatorBuilder: (_) => _buildEmptyState(context, theme),
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

  Widget _buildSliverAppBar(BuildContext context, ThemeData theme) {
    return SliverAppBar(
      floating: false,
      pinned: true,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text(
        "Mocks",
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: context.sp(20),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: context.sp(14),
            ),
            decoration: InputDecoration(
              hintText: 'Search mock tests...',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: context.sp(14),
              ),
              prefixIcon: Icon(Icons.search,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: context.sp(20)),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
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
                _buildFilterChip(context, 'Newest', theme),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip(context, 'Oldest', theme),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip(context, 'A-Z', theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, ThemeData theme) {
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
        fontSize: context.sp(13),
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

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: context.sp(64),
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _searchQuery.isNotEmpty
                ? 'No matches found.'
                : 'No purchased tests yet.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: context.sp(16),
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () {
                ref.read(navigationProvider.notifier).setIndex(2); // Store
              },
              child: Text("Browse Store",
                  style: TextStyle(fontSize: context.sp(14))),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader(BuildContext context, ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerHighest,
      highlightColor: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: List.generate(
            4,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Container(
                width: double.infinity,
                height: context.h(120),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: context.w(80),
                      height: context.h(80),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                              height: context.h(16),
                              color: theme.colorScheme.surface),
                          const SizedBox(height: AppSpacing.xs),
                          Container(
                              height: context.h(14),
                              color: theme.colorScheme.surface),
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                              width: context.w(60),
                              height: context.h(12),
                              color: theme.colorScheme.surface),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
