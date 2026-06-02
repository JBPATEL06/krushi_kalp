import 'dart:async';
import 'package:flutter/material.dart';
import 'package:krushi_kalp/utils/responsive.dart';
import '../../../../data/services/test_service.dart';
import '../../../../domain/models/mock_test.dart';
import '../../mock_test_upload_screen.dart';
import 'admin_mock_test_detail_screen.dart';
import 'package:krushi_kalp/core/theme/app_spacing.dart';
import 'package:krushi_kalp/core/theme/app_radius.dart';
import '../../../../utils/crashlytics_service.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:easy_debounce/easy_debounce.dart';
import '../../../../data/services/admin_service.dart';
import '../admin_grant_access_screen.dart';

class AdminMockTestList extends StatefulWidget {
  final bool? isFree; // null = all, true = free only, false = paid only

  const AdminMockTestList({super.key, this.isFree});

  @override
  State<AdminMockTestList> createState() => AdminMockTestListState();
}

class AdminMockTestListState extends State<AdminMockTestList> {
  void refresh() => _pagingController.refresh();
  static const _pageSize = 20;
  
  final PagingController<int, MockTest> _pagingController =
      PagingController(firstPageKey: 0);

  // Filters
  String _searchQuery = '';
  String _sortOption = 'newest'; // newest, oldest, price_asc, price_desc

  final TextEditingController _searchController = TextEditingController();

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
      String sortBy = 'created_at';
      bool ascending = false;

      switch (_sortOption) {
        case 'oldest':
          sortBy = 'created_at';
          ascending = true;
          break;
        case 'price_asc':
          sortBy = 'price';
          ascending = true;
          break;
        case 'price_desc':
          sortBy = 'price';
          ascending = false;
          break;
        case 'newest':
        default:
          sortBy = 'created_at';
          ascending = false;
          break;
      }

      final newItems = await TestService.instance.fetchPaginatedMockTests(
        offset: pageKey,
        limit: _pageSize,
        searchQuery: _searchQuery,
        isAdmin: true,
        sortBy: sortBy,
        ascending: ascending,
        isFree: widget.isFree,
      );

      final isLastPage = newItems.length < _pageSize;
      if (!mounted) return;

      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error, stack) {
      if (!mounted) return;
      CrashlyticsService.instance
          .recordError(error, stack, reason: 'admin_mock_test_list: _fetchPage');
      _pagingController.error = error;
    }
  }

  void _onSearchChanged(String val) {
    _searchQuery = val;
    EasyDebounce.debounce(
      'mock_test_search',
      const Duration(milliseconds: 500),
      () => _pagingController.refresh(),
    );
  }

  void _onSortChanged(String option) {
    if (_sortOption != option) {
      setState(() {
        _sortOption = option;
      });
      _pagingController.refresh();
    }
  }

  Future<void> _deleteTest(int id) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('Delete Test?'),
        content: const Text(
            'This action cannot be undone. All associated progress and data will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await TestService.instance.deleteMockTest(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Test deleted successfully')),
          );
          _pagingController.refresh();
        }
      } catch (e, stack) {
        CrashlyticsService.instance.recordError(e, stack, reason: 'admin_mock_test_list');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleVisibility(MockTest test, bool val) async {
    try {
      final success = await AdminService.toggleMockTestPublicStatus(test.id, val);
      if (success && mounted) {
        setState(() {
          // Update the item in the paging controller's list directly if possible
          // or just refresh. Refreshing is safer for pagination consistency.
          _pagingController.refresh();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Test visibility ${val ? "enabled" : "disabled"}')),
        );
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'admin_mock_test_list_toggle');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MockTestUploadScreen()),
          );
          if (result == true) {
            _pagingController.refresh();
          }
        },
        label: Text('ADD TEST',
            style: TextStyle(fontSize: context.sp(14))), // FIXED
        icon: const Icon(Icons.add_rounded),
        elevation: 2,
      ),
      body: Column(
        children: [
          // Search & Sort Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                  bottom: BorderSide(
                      color:
                          colorScheme.outlineVariant.withValues(alpha: 0.5))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Tests',
                    labelStyle: TextStyle(fontSize: context.sp(14)), // FIXED
                    prefixIcon: Icon(Icons.search_rounded,
                        size: context.sp(20)), // FIXED
                    hintText: 'Search by title or category...',
                    hintStyle: TextStyle(fontSize: context.sp(14)), // FIXED
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Text(
                      "SORT BY",
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurfaceVariant,
                        letterSpacing: 1.2,
                        fontSize: context.sp(10), // FIXED
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildSortChip('Newest', 'newest'),
                            _buildSortChip('Oldest', 'oldest'),
                            _buildSortChip('Price: Low', 'price_asc'),
                            _buildSortChip('Price: High', 'price_desc'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _pagingController.refresh(),
              child: PagedListView<int, MockTest>(
                pagingController: _pagingController,
                padding: EdgeInsets.only(
                  top: AppSpacing.md,
                  bottom: AppSpacing.md +
                      MediaQuery.of(context).padding.bottom +
                      80, // Space for FAB
                ),
                builderDelegate: PagedChildBuilderDelegate<MockTest>(
                  itemBuilder: (context, item, index) =>
                      _buildMockTestRow(context, item),
                  firstPageProgressIndicatorBuilder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                newPageProgressIndicatorBuilder: (_) =>
                    const Center(child: CircularProgressIndicator()),
                noItemsFoundIndicatorBuilder: (_) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 100),
                    child: _buildEmptyState(),
                  ),
                ),
                firstPageErrorIndicatorBuilder: (_) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: colorScheme.error, size: context.sp(48)),
                      const SizedBox(height: AppSpacing.md),
                      Text('Something went wrong. Please try again.',
                          style: theme.textTheme.bodySmall),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton(
                        onPressed: () => _pagingController.refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                ), // Add missing PagedChildBuilderDelegate closing
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockTestRow(BuildContext context, MockTest test) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AdminMockTestDetailScreen(test: test)),
          );
          if (result == true) {
            _pagingController.refresh();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5))),
          ),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: context.sp(48), // FIXED
                height: context.sp(48), // FIXED
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: test.signedUrl != null && test.signedUrl!.startsWith('http')
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          test.signedUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                              Icons.broken_image_rounded,
                              size: context.sp(20), // FIXED
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5)),
                        ),
                      )
                    : Icon(Icons.description_rounded,
                        size: context.sp(24), // FIXED
                        color: colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5)),
              ),
              const SizedBox(width: AppSpacing.md),
              // Name and Category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: context.sp(14)), // FIXED
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          test.category.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: context.sp(9), // FIXED
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                                color: colorScheme.outline,
                                shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(
                          "${test.totalQuestions} Questions",
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                            fontWeight: FontWeight.bold,
                            fontSize: context.sp(10), // FIXED
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Price and Delete
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    test.price == 0 ? 'FREE' : '₹${test.price}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: test.price == 0
                          ? const Color(0xFF10B981)
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                      fontSize: context.sp(12), // FIXED
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.people_alt_outlined,
                            color: colorScheme.primary.withValues(alpha: 0.7),
                            size: context.sp(18)),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminGrantAccessScreen(
                              itemType: 'test',
                              itemId: test.id,
                              itemTitle: test.title,
                              itemSnapshot: test.toJson(),
                              isAuditMode: true,
                            ),
                          ),
                        ),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 8),
                      Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          value: test.isPublic,
                          onChanged: (val) => _toggleVisibility(test, val),
                          activeThumbColor: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded,
                            color: colorScheme.error.withValues(alpha: 0.5),
                            size: context.sp(16)), // FIXED
                        onPressed: () => _deleteTest(test.id),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_late_outlined,
              size: context.sp(64), // FIXED
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No tests found.',
            style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: context.sp(16), // FIXED
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
  Widget _buildSortChip(String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _sortOption == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          if (selected) {
            _onSortChanged(value);
          }
        },
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        selectedColor: colorScheme.primary.withValues(alpha: 0.1),
        checkmarkColor: colorScheme.primary,
        labelStyle: theme.textTheme.labelMedium?.copyWith(
          color:
              isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
    );
  }

}
