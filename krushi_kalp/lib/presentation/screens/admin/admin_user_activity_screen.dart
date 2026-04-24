import 'package:flutter/material.dart';
import '../../../../data/services/admin_service.dart';
import 'package:krushi_kalp/core/theme/app_spacing.dart';
import 'package:krushi_kalp/core/theme/app_radius.dart';
import 'package:krushi_kalp/presentation/widgets/common/modern_card.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:krushi_kalp/presentation/widgets/common/network_error_state.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:krushi_kalp/core/theme/app_colors.dart';

class AdminUserActivityScreen extends StatefulWidget {
  final String userId;
  final String username;
  final int initialIndex;

  const AdminUserActivityScreen({
    super.key,
    required this.userId,
    required this.username,
    this.initialIndex = 0,
  });

  @override
  State<AdminUserActivityScreen> createState() => _AdminUserActivityScreenState();
}

class _AdminUserActivityScreenState extends State<AdminUserActivityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialIndex);
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _searchQuery = query.trim());
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User Activity', style: theme.textTheme.titleLarge),
            Text(widget.username, style: theme.textTheme.bodySmall),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Purchases'),
            Tab(text: 'Attempts'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by item name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _PurchasedItemsTab(userId: widget.userId, searchQuery: _searchQuery),
                _AttemptsTab(userId: widget.userId, searchQuery: _searchQuery),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchasedItemsTab extends StatefulWidget {
  final String userId;
  final String searchQuery;

  const _PurchasedItemsTab({required this.userId, required this.searchQuery});

  @override
  State<_PurchasedItemsTab> createState() => _PurchasedItemsTabState();
}

class _PurchasedItemsTabState extends State<_PurchasedItemsTab> with AutomaticKeepAliveClientMixin {
  final PagingController<int, Map<String, dynamic>> _pagingController =
      PagingController(firstPageKey: 0);
  static const int _pageSize = 15;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  @override
  void didUpdateWidget(_PurchasedItemsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _pagingController.refresh();
    }
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems = await AdminService.getUserOrdersPaginated(
        widget.userId,
        from: pageKey,
        to: pageKey + _pageSize - 1,
        searchQuery: widget.searchQuery,
      );

      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PagedListView<int, Map<String, dynamic>>.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      pagingController: _pagingController,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      builderDelegate: PagedChildBuilderDelegate<Map<String, dynamic>>(
        itemBuilder: (context, item, index) => _buildOrderCard(context, item),
        firstPageErrorIndicatorBuilder: (context) => NetworkErrorState(
          onRetry: () => _pagingController.refresh(),
        ),
        newPageErrorIndicatorBuilder: (context) => NetworkErrorState(
          onRetry: () => _pagingController.retryLastFailedRequest(),
        ),
        noItemsFoundIndicatorBuilder: (context) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
              const SizedBox(height: AppSpacing.md),
              Text(
                widget.searchQuery.isEmpty
                    ? 'No purchases found'
                    : 'No matches for "${widget.searchQuery}"',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        firstPageProgressIndicatorBuilder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
        newPageProgressIndicatorBuilder: (context) => const Center(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final name = item['item_name'] ?? 'Untitled Item';
    final date = DateTime.parse(item['created_at']);
    final accessType = item['access_type'] ?? 'free_claim';
    final payment = item['payment_details'] as Map<String, dynamic>?;

    Color badgeColor;
    String badgeText;

    switch (accessType) {
      case 'paid':
        badgeColor = const Color(0xFF10B981);
        badgeText = 'Paid';
        break;
      case 'free_claim':
        badgeColor = const Color(0xFF3B82F6);
        badgeText = 'Free Claim';
        break;
      case 'manual_granted':
        badgeColor = const Color(0xFFF59E0B);
        badgeText = 'Manual Grant';
        break;
      default:
        badgeColor = Colors.grey;
        badgeText = accessType.toUpperCase();
    }

    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    item['item_type'] == 'test'
                        ? Icons.quiz_rounded
                        : Icons.menu_book_rounded,
                    color: badgeColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(date),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    badgeText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (accessType == 'paid' || (item['price_paid'] ?? 0) > 0) ...[
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Price Paid: ₹${(item['price_paid'] ?? 0) is num ? (item['price_paid'] % 1 == 0 ? item['price_paid'].toInt() : item['price_paid'].toStringAsFixed(2)) : (item['price_paid'] ?? 0)}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (payment != null && (payment['discount_amount'] ?? 0) > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Offer: ${payment['offer_code'] ?? 'Discount'} (-₹${(payment['discount_amount'] ?? 0) is num ? (payment['discount_amount'] % 1 == 0 ? payment['discount_amount'].toInt() : payment['discount_amount'].toStringAsFixed(2)) : (payment['discount_amount'] ?? 0)})',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AttemptsTab extends StatefulWidget {
  final String userId;
  final String searchQuery;

  const _AttemptsTab({required this.userId, required this.searchQuery});

  @override
  State<_AttemptsTab> createState() => _AttemptsTabState();
}

class _AttemptsTabState extends State<_AttemptsTab> with AutomaticKeepAliveClientMixin {
  final PagingController<int, Map<String, dynamic>> _pagingController =
      PagingController(firstPageKey: 0);
  static const int _pageSize = 15;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  @override
  void didUpdateWidget(_AttemptsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _pagingController.refresh();
    }
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newResults = await AdminService.getUserResultsPaginated(
        widget.userId,
        from: pageKey,
        to: pageKey + _pageSize - 1,
        searchQuery: widget.searchQuery,
      );

      final isLastPage = newResults.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newResults);
      } else {
        final nextPageKey = pageKey + newResults.length;
        _pagingController.appendPage(newResults, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PagedListView<int, Map<String, dynamic>>.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      pagingController: _pagingController,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      builderDelegate: PagedChildBuilderDelegate<Map<String, dynamic>>(
        itemBuilder: (context, item, index) => _buildAttemptCard(context, item),
        firstPageErrorIndicatorBuilder: (context) => NetworkErrorState(
          onRetry: () => _pagingController.refresh(),
        ),
        newPageErrorIndicatorBuilder: (context) => NetworkErrorState(
          onRetry: () => _pagingController.retryLastFailedRequest(),
        ),
        noItemsFoundIndicatorBuilder: (context) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_late_rounded, size: 64, color: Colors.grey[300]),
              const SizedBox(height: AppSpacing.md),
              Text(
                widget.searchQuery.isEmpty
                    ? 'No attempts found'
                    : 'No matches for "${widget.searchQuery}"',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        firstPageProgressIndicatorBuilder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
        newPageProgressIndicatorBuilder: (context) => const Center(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  Widget _buildAttemptCard(BuildContext context, Map<String, dynamic> result) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final testName = result['mock_tests']?['title'] ?? 'Unknown Test';
    final rawScore = result['score_obtained'] ?? 0;
    final score = rawScore is num 
        ? (rawScore % 1 == 0 ? rawScore.toInt().toString() : rawScore.toStringAsFixed(2))
        : rawScore.toString();
    final total = result['mock_tests']?['total_marks'] ?? 0;
    final date = DateTime.parse(result['attempt_date']);

    return ModernCard(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: const Icon(Icons.assignment_rounded,
              color: Color(0xFFF59E0B), size: 24),
        ),
        title: Text(testName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text(
            DateFormat('dd MMM yyyy, hh:mm a').format(date),
            style: theme.textTheme.bodySmall),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            '$score / $total',
            style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13),
          ),
        ),
      ),
    );
  }
}
