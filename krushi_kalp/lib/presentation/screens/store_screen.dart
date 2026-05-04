import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '../../domain/models/mock_test.dart';
import '../../domain/models/resource.dart';
import '../../data/services/test_service.dart';
import '../../data/services/resource_service.dart';
import '../providers/test_notifier.dart';
import '../providers/offer_notifier.dart';
import '../providers/cart_notifier.dart';
import '../providers/resource_notifier.dart';
import '../providers/auth_notifier.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';
import 'store/widgets/store_grid.dart';
import 'store/widgets/store_resource_grid.dart';
import '../widgets/direct_checkout_sheet.dart';
import 'mock_test_detail_screen.dart';
import 'resource_detail_screen.dart';
import '../../utils/error_utils.dart';
import '../../utils/crashlytics_service.dart';

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen>
    with SingleTickerProviderStateMixin {
  static const _pageSize = 20;
  String _searchQuery = '';
  bool _isSearching = false;

  final Map<String, String> _categoryMap = {
    'Mock Tests': 'Mocks',
    'E-Books': 'E-Books',
    'Study Material': 'Study Material',
    'Daily CA': 'Daily CA',
    'PYQs': 'PYQs',
  };

  late TabController _tabController;
  final List<PagingController<int, dynamic>> _pagingControllers = [];

  List<String> get _keys => _categoryMap.keys.toList();
  List<String> get _labels => _categoryMap.values.toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categoryMap.length, vsync: this);
    
    for (int i = 0; i < _categoryMap.length; i++) {
      final controller = PagingController<int, dynamic>(firstPageKey: 0);
      controller.addPageRequestListener((pageKey) => _fetchPage(i, pageKey));
      _pagingControllers.add(controller);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var controller in _pagingControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchPage(int tabIndex, int pageKey) async {
    try {
      final category = _keys[tabIndex];
      List<dynamic> newItems = [];
      bool isLastPage = false;

      if (category == 'Mock Tests') {
        final tests = await TestService.instance.fetchPaginatedMockTests(
          offset: pageKey,
          limit: _pageSize,
          searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        );
        newItems = tests;
        isLastPage = tests.length < _pageSize;
      } else {
        ResourceType? type;
        switch (category) {
          case 'E-Books': type = ResourceType.eBook; break;
          case 'Study Material': type = ResourceType.studyMaterial; break;
          case 'PYQs': type = ResourceType.pyq; break;
          case 'Daily CA': type = ResourceType.currentAffair; break;
        }

        final resources = await ResourceService.instance.fetchPaginatedResources(
          offset: pageKey,
          limit: _pageSize,
          type: type ?? ResourceType.eBook, // Default if null
          searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        );
        newItems = resources;
        isLastPage = resources.length < _pageSize;
      }

      if (isLastPage) {
        _pagingControllers[tabIndex].appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _pagingControllers[tabIndex].appendPage(newItems, nextPageKey);
      }
    } catch (error, stack) {
      CrashlyticsService.instance.recordError(error, stack, reason: 'store_fetch_page');
      _pagingControllers[tabIndex].error = error;
    }
  }

  void _refreshAll() {
    for (var controller in _pagingControllers) {
      controller.refresh();
    }
    ref.read(offerProvider.notifier).fetchActiveOffers(forceRefresh: true);
  }


  Future<void> _claimItem({MockTest? test, Resource? resource}) async {
    try {
      final user = ref.read(authProvider).user;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to claim')),
        );
        return;
      }

      if (test != null) {
        await TestService.instance.claimFreeTest(testId: test.id, authUserId: user.id);
        ref.read(testProvider.notifier).fetchUserTests(user.id);
      } else if (resource != null) {
        await ref.read(resourceProvider.notifier).claimResource(resource.id, user.id);
      }

      if (mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Free Claimed ${test?.title ?? resource?.title} successfully!'),
            backgroundColor: theme.colorScheme.tertiary,
          ),
        );
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'store_screen');
      if (mounted) ErrorUtils.showError(context, e);
    }
  }

  void _buyNow({MockTest? test, Resource? resource}) {
    if (test != null && test.price == 0) {
      _claimItem(test: test);
      return;
    }
    if (resource != null && resource.price == 0) {
      _claimItem(resource: resource);
      return;
    }

    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      builder: (_) => DirectCheckoutSheet(
        test: test,
        resource: resource,
        initialOffer: null,
      ),
    );
  }

  void _openTestDetail(MockTest test) {
    final activeOffers = ref.read(offerProvider).activeOffers;
    final isPurchased = ref.read(testProvider).purchasedTestIds.contains(test.id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MockTestDetailScreen(
          test: test,
          isPurchased: isPurchased,
          activeOffers: activeOffers,
          heroTag: 'test_image_${test.id}',
        ),
      ),
    );
  }

  void _openResourceDetail(Resource resource) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResourceDetailScreen(resource: resource),
      ),
    );
  }

  Future<void> _handleCartAction(dynamic item, String? userId) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add to cart')),
      );
      return;
    }

    final cartState = ref.read(cartProvider);
    if (cartState.isLoading) return;

    final isTest = item is MockTest;
    final itemId = item.id;
    
    final cartItemIds = cartState.cartItems
        .map((i) => i.testId ?? i.resourceId)
        .whereType<int>()
        .toSet();

    try {
      if (cartItemIds.contains(itemId)) {
        final cartItem = cartState.cartItems.firstWhere(
            (i) => (isTest ? i.testId : i.resourceId) == itemId);
        await ref.read(cartProvider.notifier).removeFromCart(itemId: cartItem.itemId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed ${item.title} from Cart'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      await ref.read(cartProvider.notifier).addToCart(
            testId: isTest ? item.id : null,
            resourceId: isTest ? null : item.id,
            price: item.price,
            authUserId: userId,
          );

      if (mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${item.title} to Cart'),
            backgroundColor: theme.colorScheme.tertiary,
          ),
        );
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'store_screen');
      if (mounted) ErrorUtils.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final testState = ref.watch(testProvider);
    final resourceState = ref.watch(resourceProvider);
    final cartState = ref.watch(cartProvider);
    final offerState = ref.watch(offerProvider);
    final user = ref.watch(authProvider).user;

    final cartItemIds = cartState.cartItems
        .map((item) => item.testId ?? item.resourceId)
        .whereType<int>()
        .toSet();

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Store",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
            onPressed: _refreshAll,
            tooltip: 'Refresh Store',
          ),
          IconButton(
            icon: Icon(Icons.search, color: theme.colorScheme.primary),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _refreshAll();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _buildSearchBar(),
            ),
          const SizedBox(height: AppSpacing.md),
          _buildTabBar(theme),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _pagingControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;
                final category = _keys[index];

                return RefreshIndicator(
                  onRefresh: () async => controller.refresh(),
                  child: CustomScrollView(
                    slivers: [
                      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
                      if (category == 'Mock Tests')
                        StoreGrid(
                          pagingController: controller as PagingController<int, MockTest>,
                          activeOffers: offerState.activeOffers,
                          cartItemIds: cartItemIds,
                          purchasedTestIds: testState.purchasedTestIds,
                          onBuyTap: (test) => _buyNow(test: test),
                          onCartTap: (test) => _handleCartAction(test, user?.id),
                          onTap: (test) => _openTestDetail(test),
                        )
                      else
                        StoreResourceGrid(
                          pagingController: controller as PagingController<int, Resource>,
                          activeOffers: offerState.activeOffers,
                          purchasedIds: resourceState.purchasedResourceIds.toSet(),
                          cartItemIds: cartItemIds,
                          onBuyTap: (res) => _buyNow(resource: res),
                          onCartTap: (res) => _handleCartAction(res, user?.id),
                          onTap: (res) => _openResourceDetail(res),
                        ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: AppSpacing.xl + MediaQuery.of(context).padding.bottom,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    return TextField(
      onSubmitted: (val) {
        setState(() {
          _searchQuery = val.trim();
          _refreshAll();
        });
      },
      decoration: InputDecoration(
        hintText: 'Search products...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      height: 40,
      width: double.infinity,
      padding: const EdgeInsets.only(left: AppSpacing.lg),
      child: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          return TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: theme.colorScheme.onPrimary,
            unselectedLabelColor: theme.colorScheme.primary,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            indicator: const BoxDecoration(color: Colors.transparent),
            labelPadding: const EdgeInsets.only(right: AppSpacing.sm),
            tabAlignment: TabAlignment.start,
            tabs: _labels.asMap().entries.map((entry) {
              final index = entry.key;
              final label = entry.value;
              final isSelected = _tabController.index == index;

              return Tab(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
