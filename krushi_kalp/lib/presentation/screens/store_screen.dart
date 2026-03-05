import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/mock_test.dart';
import '../../data/services/test_service.dart';
import 'mock_test_detail_screen.dart';
import '../../domain/models/offer.dart';

import 'cart_screen.dart'; // NEW
import '../providers/test_provider.dart';
import '../providers/offer_provider.dart';
import '../providers/network_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/navigation_provider.dart'; // Re-added
import '../../utils/price_calculator.dart';
import 'dart:async';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart'; // NEW
import 'store/widgets/store_grid.dart';
import '../widgets/direct_checkout_sheet.dart';
// For Start Exam

import '../providers/resource_provider.dart';
import '../../domain/models/resource.dart';
import 'store/widgets/store_resource_grid.dart';
import 'store/widgets/store_current_affairs_list.dart';
import '../widgets/resource_detail_dialog.dart';
import 'resource_detail_screen.dart'; // NEW
import '../widgets/common/responsive_wrapper.dart';
import '../../data/services/download_service.dart'; // NEW
import 'pdf_viewer_screen.dart'; // NEW
import 'dart:io'; // NEW

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen>
    with SingleTickerProviderStateMixin {
  // State for Filtering
  String _searchQuery = '';
  String _sortOption = 'Latest';

  // Tabs: Key -> Label
  final Map<String, String> _categoryMap = {
    'Mock Tests': 'Tests',
    'E-Books': 'E-Books',
    'Study Materials': 'Materials',
    'Current Affairs': 'GK & CA',
    'PYQs': 'PYQs',
  };

  late TabController _tabController;

  List<String> get _keys => _categoryMap.keys.toList();
  List<String> get _labels => _categoryMap.values.toList();

  // Track if we had an error to auto-retry on reconnect
  bool _hadNetworkError = false;

  // Loader Timer

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categoryMap.length, vsync: this);
    // Defer loading to allow context access
    Future.microtask(() => _loadData());
    // Listen for network reconnection to auto-retry
    NetworkProvider().addListener(_onNetworkChange);
  }

  @override
  void dispose() {
    _tabController.dispose();
    NetworkProvider().removeListener(_onNetworkChange);
    super.dispose();
  }

  void _onNetworkChange() {
    final isConnected = NetworkProvider().isConnected;
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
    final navProvider = Provider.of<NavigationProvider>(context);
    if (navProvider.selectedStoreCategory != 'All') {
      final index = _keys.indexOf(navProvider.selectedStoreCategory);
      if (index != -1 && _tabController.index != index) {
        _tabController.animateTo(index);
      }
    }
  }

  Future<void> _loadData() async {
    // Start timer to show retry button if loading takes too long
    // _loadingTimer = Timer(const Duration(seconds: 10), () {
    //   if (mounted && context.read<TestProvider>().isLoading) {
    //     setState(() {
    //       _showRetryButton = true;
    //     });
    //   }
    // });

    // NotificationService().schedulePurchaseReminder(); // Removed excessive scheduling
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final offerProvider = context.read<OfferProvider>();
        final cartProvider = context.read<CartProvider>();

        // We only fetch things specific to the store functionality here.
        // Tests and Purchased Resources are synced by MainScreen globally.
        await Future.wait([
          offerProvider.fetchActiveOffers(),
          cartProvider.fetchCart(),
        ]);
      }
    });
  }

  Future<void> _refreshAll() async {
    final testProvider = context.read<TestProvider>();
    final offerProvider = context.read<OfferProvider>();
    final cartProvider = context.read<CartProvider>();
    final resourceProvider = context.read<ResourceProvider>();

    await Future.wait([
      testProvider.fetchTests(forceRefresh: true),
      resourceProvider.fetchAll(),
      offerProvider.fetchActiveOffers(),
      cartProvider.fetchCart(),
    ]);
  }

  // --- ACTIONS ---

  Future<void> _addToCart({
    int? testId,
    int? resourceId,
    required double price,
    required String title,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login to add to cart')),
          );
        }
        return;
      }

      await context.read<CartProvider>().addToCart(
            testId: testId,
            resourceId: resourceId,
            price: price,
            authUserId: user.id,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $title to Cart'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cart Error: $e')),
        );
      }
    }
  }

  Future<void> _claimItem({
    MockTest? test,
    Resource? resource,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login to claim')),
          );
        }
        return;
      }

      if (test != null) {
        await TestService.claimFreeTest(
          testId: test.id,
          authUserId: user.id,
        );
        if (mounted) {
          context.read<TestProvider>().fetchTests(forceRefresh: true);
        }
      } else if (resource != null) {
        await context
            .read<ResourceProvider>()
            .claimResource(resource.id, user.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Claimed ${test?.title ?? resource?.title} successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Claim Error: $e')),
        );
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

    Offer? bestOffer;
    double price = test?.price ?? resource?.price ?? 0;
    int? id = test?.id ?? resource?.id;

    if (price > 0 && id != null) {
      final saleOffers = context.read<OfferProvider>().activeOffers;
      if (saleOffers.isNotEmpty) {
        final priceData = PriceCalculator.calculateDisplayPrice(
          basePrice: price,
          activeOffers: saleOffers,
          testId: test?.id,
          resourceId: resource?.id,
        );
        final offer = priceData['offer'] as Offer?;
        if (offer != null && offer.isSale) {
          bestOffer = offer;
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DirectCheckoutSheet(
        test: test,
        resource: resource,
        initialOffer: bestOffer,
      ),
    );
  }

  Future<void> _openOrDownloadResource(Resource resource) async {
    final filename = 'resource_${resource.id}.pdf';
    final userId = Supabase.instance.client.auth.currentUser?.id;

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
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("File URL not found")));
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
          Navigator.pop(context);
          _openPdf(File(path), resource.title);
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Download Failed: $e")));
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
    final activeOffers = context.read<OfferProvider>().activeOffers;
    // Check purchase status dynamically
    final isPurchased =
        context.read<TestProvider>().purchasedTests.any((t) => t.id == test.id);

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

  // --- BUILDERS ---

  Widget _buildMockTestsTab(TestProvider provider, OfferProvider offerProvider,
      CartProvider cartProvider,
      {bool isFree = false}) {
    List<MockTest> tests = provider.tests;

    if (isFree) {
      tests = tests.where((t) => t.price == 0).toList();
    } else {
      // Show paid tests only in "Mock Tests" tab?
      // Or show all except free?
      // Usually "Mock Tests" implies all or paid. Let's show all for now, maybe exclude free if they are in Free Tests?
      // User requirement says "Free Test" is a category. So maybe exclude free from "Mock Tests"?
      // Let's keep them in both or exclude. Usually separate is better.
      tests = tests.where((t) => t.price > 0).toList();
    }

    if (_searchQuery.isNotEmpty) {
      tests = tests
          .where(
              (t) => t.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Sort
    if (_sortOption == 'Price: Low to High') {
      tests.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortOption == 'Price: High to Low') {
      tests.sort((a, b) => b.price.compareTo(a.price));
    } else {
      tests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    // Get Purchased IDs
    final purchasedTestIds = provider.purchasedTests.map((t) => t.id).toSet();

    // HIDE PURCHASED TESTS
    tests = tests.where((t) => !purchasedTestIds.contains(t.id)).toList();

    // StoreGrid handles display
    return StoreGrid(
      tests: tests,
      isWide: ResponsiveWrapper.isWide(context),
      activeOffers: offerProvider.activeOffers,
      cartItemIds: cartProvider.cartItems
          .where((i) => i['test_id'] != null)
          .map((i) => i['test_id'] as int)
          .toSet(),
      purchasedTestIds:
          purchasedTestIds, // Pass purchased IDs (though list is filtered, good for safety)
      onBuyTap: (test) => _buyNow(test: test),
      onCartTap: (test) {
        double finalPrice = test.price;
        final activeOffers = context.read<OfferProvider>().activeOffers;
        if (activeOffers.isNotEmpty) {
          final priceData = PriceCalculator.calculateDisplayPrice(
            basePrice: test.price,
            activeOffers: activeOffers,
            testId: test.id,
          );
          finalPrice = priceData['finalPrice'];
        }
        _addToCart(testId: test.id, price: finalPrice, title: test.title);
      },
      onTap: (test) => _openTestDetail(test),
    );
  }

  Widget _buildResourcesTab(
      ResourceProvider provider, CartProvider cartProvider, String category) {
    List<Resource> resources;
    if (category == 'E-Books') {
      resources = provider.ebooks;
    } else if (category == 'Study Materials') {
      resources = provider.studyMaterials;
    } else if (category == 'PYQs') {
      resources = provider.pyqs;
    } else if (category == 'Current Affairs') {
      return StoreCurrentAffairsList(
        items: provider.currentAffairs,
        purchasedIds: provider.purchasedResourceIds,
        onTap: (item) {
          final isPurchased = provider.purchasedResourceIds.contains(item.id);
          showDialog(
            context: context,
            builder: (context) => ResourceDetailDialog(
              resource: item,
              isPurchased: isPurchased,
              onBuyTap: () {
                Navigator.pop(context); // Close dialog
                _buyNow(resource: item);
              },
            ),
          );
        },
      );
    } else {
      resources = [];
    }

    if (_searchQuery.isNotEmpty) {
      resources = resources
          .where(
              (r) => r.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // HIDE PURCHASED RESOURCES
    resources = resources
        .where((r) => !provider.purchasedResourceIds.contains(r.id))
        .toList();

    return StoreResourceGrid(
      resources: resources,
      activeOffers: context.read<OfferProvider>().activeOffers,
      purchasedIds: provider.purchasedResourceIds,
      cartItemIds: cartProvider.cartItems
          .where((i) => i['resource_id'] != null)
          .map((i) => i['resource_id'] as int)
          .toSet(),
      onBuyTap: (r) {
        // Fallback or for Claim
        if (provider.purchasedResourceIds.contains(r.id)) {
          _openOrDownloadResource(r);
        } else {
          _buyNow(resource: r);
        }
      },
      onCartTap: (r) {
        double finalPrice = r.price;
        final activeOffers = context.read<OfferProvider>().activeOffers;
        if (activeOffers.isNotEmpty) {
          final priceData = PriceCalculator.calculateDisplayPrice(
            basePrice: r.price,
            activeOffers: activeOffers,
            resourceId: r.id,
          );
          finalPrice = priceData['finalPrice'];
        }
        _addToCart(resourceId: r.id, price: finalPrice, title: r.title);
      },
      onTap: _openResourceDetail,
      isWide: ResponsiveWrapper.isWide(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs),
          child: Text(
            "Store",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
        ),
        actions: [
          _buildCartIcon(),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _buildSearchBar(),
          ),
          const SizedBox(height: AppSpacing.md),

          // Custom Pill Tab Bar
          Container(
            height: context.h(40),
            width: double.infinity,
            padding: const EdgeInsets.only(left: AppSpacing.lg),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelPadding:
                  const EdgeInsets.symmetric(horizontal: 12), // Tighter padding
              tabAlignment: TabAlignment.start, // Align tabs to start (left)
              tabs: _labels.map((t) => Tab(text: t)).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Tab Content
          Expanded(
            child: Consumer4<TestProvider, OfferProvider, ResourceProvider,
                CartProvider>(
              builder: (context, testProvider, offerProvider, resourceProvider,
                  cartProvider, child) {
                if (testProvider.isLoading || resourceProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // ... Content
                    RefreshIndicator(
                      onRefresh: _refreshAll,
                      child: CustomScrollView(
                        slivers: [
                          // Add top padding for content separation
                          const SliverToBoxAdapter(
                              child: SizedBox(height: AppSpacing.sm)),
                          _buildMockTestsTab(
                              testProvider, offerProvider, cartProvider,
                              isFree: false),
                          const SliverToBoxAdapter(
                              child: SizedBox(height: AppSpacing.xl)),
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
                              resourceProvider, cartProvider, 'E-Books'),
                          const SliverToBoxAdapter(
                              child: SizedBox(height: AppSpacing.xl)),
                        ],
                      ),
                    ),
                    RefreshIndicator(
                      onRefresh: _refreshAll,
                      child: CustomScrollView(
                        slivers: [
                          const SliverToBoxAdapter(
                              child: SizedBox(height: AppSpacing.sm)),
                          _buildResourcesTab(resourceProvider, cartProvider,
                              'Study Materials'),
                          const SliverToBoxAdapter(
                              child: SizedBox(height: AppSpacing.xl)),
                        ],
                      ),
                    ),
                    RefreshIndicator(
                      onRefresh: _refreshAll,
                      child: CustomScrollView(
                        slivers: [
                          const SliverToBoxAdapter(
                              child: SizedBox(height: AppSpacing.sm)),
                          _buildResourcesTab(resourceProvider, cartProvider,
                              'Current Affairs'),
                          const SliverToBoxAdapter(
                              child: SizedBox(height: AppSpacing.xl)),
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
                              resourceProvider, cartProvider, 'PYQs'),
                          const SliverToBoxAdapter(
                              child: SizedBox(height: AppSpacing.xl)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: context.h(48), // Slightly taller
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColors.neutral200),
      ),
      child: TextField(
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        decoration: const InputDecoration(
          hintText: 'Search for tests, books...',
          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCartIcon() {
    return IconButton(
      icon: const Icon(Icons.shopping_cart_outlined,
          color: AppColors.textPrimary),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CartScreen()),
        );
      },
    );
  }
}
