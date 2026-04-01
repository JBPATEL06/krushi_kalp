import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krushi_kalp/presentation/providers/offer_state.dart';
import 'package:krushi_kalp/presentation/providers/test_state.dart';
import '../../domain/models/mock_test.dart';
import '../../data/services/test_service.dart';
import 'mock_test_detail_screen.dart';

import '../providers/test_notifier.dart';
import '../providers/offer_notifier.dart';
import '../providers/network_notifier.dart';
import '../providers/cart_notifier.dart';
import '../providers/navigation_notifier.dart';
import '../providers/resource_notifier.dart';
import '../providers/auth_notifier.dart';
import '../providers/resource_state.dart';
import 'dart:async';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';
import 'store/widgets/store_grid.dart';
import '../widgets/direct_checkout_sheet.dart';

// Replaced local legacy providers with Notifiers
import '../../domain/models/resource.dart';
import 'store/widgets/store_resource_grid.dart';
import 'resource_detail_screen.dart';
import '../widgets/common/responsive_wrapper.dart';
import '../../data/services/download_service.dart';
import 'pdf_viewer_screen.dart';
import 'dart:io';
import '../../utils/error_utils.dart';
import '../../utils/crashlytics_service.dart';

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  final String _sortOption = 'Latest';
  bool _isSearching = false;

  final Map<String, String> _categoryMap = {
    'Mock Tests': 'Mocks',
    'E-Books': 'E-Books',
    'Study Materials': 'Materials',
    'Current Affairs': 'GK & CA',
    'PYQs': 'PYQs',
  };

  late TabController _tabController;

  List<String> get _keys => _categoryMap.keys.toList();
  List<String> get _labels => _categoryMap.values.toList();

  bool _hadNetworkError = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categoryMap.length, vsync: this);
    Future.microtask(() => _loadData());
    // listen to network changes via ref.listen in build or use a provider
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onNetworkChange() {
    final isConnected = ref.read(networkNotifierProvider);
    if (isConnected && _hadNetworkError && mounted) {
      _hadNetworkError = false;
      _loadData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkCategorySelection();
  }

  void _checkCategorySelection() {
    final navState = ref.watch(navigationProvider);
    if (navState.selectedStoreCategory != 'All') {
      final index = _keys.indexOf(navState.selectedStoreCategory);
      if (index != -1 && _tabController.index != index) {
        _tabController.animateTo(index);
      }
    }
  }

  Future<void> _loadData() async {
    if (_isProcessing) return;
    _isProcessing = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await Future.wait([
          ref.read(testNotifierProvider.notifier).fetchTests(),
          ref.read(resourceNotifierProvider.notifier).fetchAll(),
          ref.read(offerNotifierProvider.notifier).fetchActiveOffers(),
        ]);
        final user = ref.read(authNotifierProvider).user;
        if (user != null) {
          await ref.read(cartNotifierProvider.notifier).fetchCart();
        }
      } catch (e, stack) {
        CrashlyticsService.instance
            .recordError(e, stack, reason: 'store_screen_load');
      } finally {
        if (mounted) _isProcessing = false;
      }
    });
  }

  Future<void> _refreshAll() async {
    _loadData();
  }

  Future<void> _addToCart({
    int? testId,
    int? resourceId,
    required double price,
    required String title,
  }) async {
    try {
      final user = ref.read(authNotifierProvider).user;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login to add to cart')),
          );
        }
        return;
      }

      await ref.read(cartNotifierProvider.notifier).addToCart(
            testId: testId,
            resourceId: resourceId,
            price: price,
            authUserId: user.id,
          );

      if (mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $title to Cart'),
            backgroundColor: theme.colorScheme.tertiary,
          ),
        );
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'store_screen');
      if (mounted) {
        ErrorUtils.showError(context, e);
      }
    }
  }

  Future<void> _claimItem({
    MockTest? test,
    Resource? resource,
  }) async {
    try {
      final user = ref.read(authNotifierProvider).user;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login to claim')),
          );
        }
        return;
      }

      if (test != null) {
        await TestService.instance.claimFreeTest(
          testId: test.id,
          authUserId: user.id,
        );
        if (mounted) {
          ref
              .read(testNotifierProvider.notifier)
              .fetchTests(forceRefresh: true);
        }
      } else if (resource != null) {
        await ref
            .read(resourceNotifierProvider.notifier)
            .claimResource(resource.id, user.id);
      }

      if (mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Claimed ${test?.title ?? resource?.title} successfully!'),
            backgroundColor: theme.colorScheme.tertiary,
          ),
        );
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'store_screen');
      if (mounted) {
        ErrorUtils.showError(context, e);
      }
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

  Future<void> _openOrDownloadResource(Resource resource) async {
    final filename = 'resource_${resource.id}.pdf';
    final user = ref.read(authNotifierProvider).user;
    final userId = user?.id;

    final isDownloaded =
        await DownloadService().isFileDownloaded(filename, userId: userId);

    if (isDownloaded) {
      final path =
          await DownloadService().getLocalPath(filename, userId: userId);
      if (mounted) {
        _openPdf(File(path), resource.title);
      }
    } else {
      if (resource.fileUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("File URL not found")));
        }
        return;
      }

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final path = await DownloadService()
            .downloadFile(resource.fileUrl!, filename, userId: userId);
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Download complete: ${resource.title}'),
              action: SnackBarAction(
                label: 'OPEN',
                onPressed: () => _openPdf(File(path), resource.title),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } catch (e, stack) {
        CrashlyticsService.instance.recordError(e, stack,
            reason: 'store_screen: resource download failed');
        if (mounted) {
          Navigator.maybePop(context);
          ErrorUtils.showError(context, e);
        }
      }
    }
  }

  void _openPdf(File file, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          file: file,
          title: title,
        ),
      ),
    );
  }

  void _openTestDetail(MockTest test) {
    final activeOffers = ref.read(offerNotifierProvider).activeOffers;
    final isPurchased =
        ref.read(testNotifierProvider).purchasedTestIds.contains(test.id);

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

  Future<void> _handleCartAction(MockTest test, String? userId) async {
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to add to cart')),
        );
      }
      return;
    }

    final cartState = ref.read(cartNotifierProvider);
    if (cartState.isLoading) return; // Prevent multiple taps during sync

    final cartItemIds = cartState.cartItems
        .map((item) => item.testId ?? item.resourceId)
        .whereType<int>()
        .toSet();

    try {
      if (cartItemIds.contains(test.id)) {
        final cartItem =
            cartState.cartItems.firstWhere((item) => item.testId == test.id);
        await ref
            .read(cartNotifierProvider.notifier)
            .removeFromCart(itemId: cartItem.itemId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed ${test.title} from Cart'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      await ref.read(cartNotifierProvider.notifier).addToCart(
            testId: test.id,
            price: test.price,
            authUserId: userId,
          );

      if (mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${test.title} to Cart'),
            backgroundColor: theme.colorScheme.tertiary,
          ),
        );
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'store_screen');
      if (mounted) {
        ErrorUtils.showError(context, e);
      }
    }
  }

  Future<void> _handleResourceCartAction(
      Resource resource, String? userId) async {
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to add to cart')),
        );
      }
      return;
    }

    final cartState = ref.read(cartNotifierProvider);
    if (cartState.isLoading) return; // Prevent multiple taps during sync

    final cartItemIds = cartState.cartItems
        .map((item) => item.testId ?? item.resourceId)
        .whereType<int>()
        .toSet();

    try {
      if (cartItemIds.contains(resource.id)) {
        final cartItem = cartState.cartItems
            .firstWhere((item) => item.resourceId == resource.id);
        await ref
            .read(cartNotifierProvider.notifier)
            .removeFromCart(itemId: cartItem.itemId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed ${resource.title} from Cart'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      await ref.read(cartNotifierProvider.notifier).addToCart(
            resourceId: resource.id,
            price: resource.price,
            authUserId: userId,
          );

      if (mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${resource.title} to Cart'),
            backgroundColor: theme.colorScheme.tertiary,
          ),
        );
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'store_screen');
      if (mounted) {
        ErrorUtils.showError(context, e);
      }
    }
  }

  void _handleBuyMockTest(MockTest test, String? userId) {
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to purchase')),
        );
      }
      return;
    }
    _buyNow(test: test);
  }

  void _handleBuyResource(Resource resource, String? userId) {
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to purchase')),
        );
      }
      return;
    }
    final resourceState = ref.read(resourceNotifierProvider);
    if (resourceState.purchasedResourceIds.contains(resource.id)) {
      _openOrDownloadResource(resource);
    } else {
      _buyNow(resource: resource);
    }
  }

  Widget _buildMockTestsTab(
      TestState testState, OfferState offerState, Set<int> cartItemIds,
      {bool isFree = false}) {
    List<MockTest> tests = testState.allTests;

    if (isFree) {
      tests = tests.where((t) => t.price == 0).toList();
    } else {
      tests = tests.where((t) => t.price > 0).toList();
    }

    if (_searchQuery.isNotEmpty) {
      tests = tests
          .where(
              (t) => t.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    tests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final purchasedTestIds = testState.purchasedTestIds;
    tests = tests.where((t) => !purchasedTestIds.contains(t.id)).toList();

    final user = ref.read(authNotifierProvider).user;

    return StoreGrid(
      allTests: tests,
      isWide: ResponsiveWrapper.isWide(context),
      activeOffers: offerState.activeOffers,
      cartItemIds: cartItemIds,
      purchasedTestIds: purchasedTestIds,
      onBuyTap: (test) => _handleBuyMockTest(test, user?.id),
      onCartTap: (test) => _handleCartAction(test, user?.id),
      onTap: (test) => _openTestDetail(test),
    );
  }

  Widget _buildResourcesTab(
      ResourceState resourceState, Set<int> cartItemIds, String category) {
    List<Resource> resources;
    if (category == 'E-Books') {
      resources = resourceState.ebooks;
    } else if (category == 'Study Materials') {
      resources = resourceState.studyMaterials;
    } else if (category == 'PYQs') {
      resources = resourceState.pyqs;
    } else if (category == 'Current Affairs') {
      resources = resourceState.currentAffairs;
    } else {
      resources = [];
    }

    if (_searchQuery.isNotEmpty) {
      resources = resources
          .where(
              (r) => r.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    resources = resources
        .where((r) => !resourceState.purchasedResourceIds.contains(r.id))
        .toList();

    resources.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final user = ref.read(authNotifierProvider).user;

    return StoreResourceGrid(
      resources: resources,
      activeOffers: ref.read(offerNotifierProvider).activeOffers,
      purchasedIds: resourceState.purchasedResourceIds,
      cartItemIds: cartItemIds,
      onBuyTap: (r) => _handleBuyResource(r, user?.id),
      onCartTap: (r) => _handleResourceCartAction(r, user?.id),
      onTap: _openResourceDetail,
      isWide: ResponsiveWrapper.isWide(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for network changes to retry loading
    ref.listen<bool>(networkNotifierProvider.select((value) => value),
        (previous, next) {
      if (next && !(previous ?? true)) {
        _loadData();
      }
    });

    final testState = ref.watch(testNotifierProvider);
    final resourceState = ref.watch(resourceNotifierProvider);
    final cartState = ref.watch(cartNotifierProvider);
    final offerState = ref.watch(offerNotifierProvider);
    final authState = ref.watch(authNotifierProvider);

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
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
        title: Text(
          "Store",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: theme.colorScheme.primary),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchQuery = '';
              });
            },
          ),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      body: Column(
        children: [
          if (_isSearching) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _buildSearchBar(),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Container(
            height: context.h(40),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg),
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
                }),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: (testState.isLoading || resourceState.isLoading) &&
                    (testState.allTests.isEmpty &&
                        resourceState.ebooks.isEmpty &&
                        resourceState.studyMaterials.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      RefreshIndicator(
                        onRefresh: _refreshAll,
                        child: CustomScrollView(
                          slivers: [
                            const SliverToBoxAdapter(
                                child: SizedBox(height: AppSpacing.sm)),
                            _buildMockTestsTab(
                                testState, offerState, cartItemIds,
                                isFree: false),
                            SliverToBoxAdapter(
                                child: SizedBox(
                                    height: AppSpacing.xl +
                                        MediaQuery.of(context).padding.bottom)),
                          ],
                        ),
                      ),
                      RefreshIndicator(
                        onRefresh: _refreshAll,
                        child: CustomScrollView(
                          slivers: [
                            const SliverToBoxAdapter(
                                child: SizedBox(height: AppSpacing.sm)),
                            _buildResourcesTab(
                                resourceState, cartItemIds, 'E-Books'),
                            SliverToBoxAdapter(
                                child: SizedBox(
                                    height: AppSpacing.xl +
                                        MediaQuery.of(context).padding.bottom)),
                          ],
                        ),
                      ),
                      RefreshIndicator(
                        onRefresh: _refreshAll,
                        child: CustomScrollView(
                          slivers: [
                            const SliverToBoxAdapter(
                                child: SizedBox(height: AppSpacing.sm)),
                            _buildResourcesTab(
                                resourceState, cartItemIds, 'Study Materials'),
                            SliverToBoxAdapter(
                                child: SizedBox(
                                    height: AppSpacing.xl +
                                        MediaQuery.of(context).padding.bottom)),
                          ],
                        ),
                      ),
                      RefreshIndicator(
                        onRefresh: _refreshAll,
                        child: CustomScrollView(
                          slivers: [
                            const SliverToBoxAdapter(
                                child: SizedBox(height: AppSpacing.sm)),
                            _buildResourcesTab(
                                resourceState, cartItemIds, 'Current Affairs'),
                            SliverToBoxAdapter(
                                child: SizedBox(
                                    height: AppSpacing.xl +
                                        MediaQuery.of(context).padding.bottom)),
                          ],
                        ),
                      ),
                      RefreshIndicator(
                        onRefresh: _refreshAll,
                        child: CustomScrollView(
                          slivers: [
                            const SliverToBoxAdapter(
                                child: SizedBox(height: AppSpacing.sm)),
                            _buildResourcesTab(
                                resourceState, cartItemIds, 'PYQs'),
                            SliverToBoxAdapter(
                                child: SizedBox(
                                    height: AppSpacing.xl +
                                        MediaQuery.of(context).padding.bottom)),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: context.h(48),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: TextField(
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        style: TextStyle(color: theme.colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: 'Search for tests, books...',
          hintStyle: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: context.sp(14)),
          prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: context.h(14)),
        ),
      ),
    );
  }
}
