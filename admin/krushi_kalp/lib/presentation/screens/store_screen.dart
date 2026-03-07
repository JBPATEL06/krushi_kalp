import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/mock_test.dart';
import '../../data/services/test_service.dart';
import 'mock_test_detail_screen.dart';
import '../../domain/models/offer.dart';
import 'cart_screen.dart';
import '../providers/test_provider.dart';
import '../providers/offer_provider.dart';
import '../providers/network_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/navigation_provider.dart';
import '../../utils/price_calculator.dart';
import 'dart:async';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';
import 'store/widgets/store_grid.dart';
import '../widgets/direct_checkout_sheet.dart';
import '../providers/resource_provider.dart';
import '../../domain/models/resource.dart';
import 'store/widgets/store_resource_grid.dart';
import 'store/widgets/store_current_affairs_list.dart';
import '../widgets/resource_detail_dialog.dart';
import 'resource_detail_screen.dart';
import '../widgets/common/responsive_wrapper.dart';
import '../../data/services/download_service.dart';
import 'pdf_viewer_screen.dart';
import 'dart:io';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String _sortOption = 'Latest';

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

  bool _hadNetworkError = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categoryMap.length, vsync: this);
    Future.microtask(() => _loadData());
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final offerProvider = context.read<OfferProvider>();
        final cartProvider = context.read<CartProvider>();
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

  Future<void> _addToCart({
    int? testId,
    int? resourceId,
    required double price,
    required String title,
  }) async {
    final colorScheme = Theme.of(context).colorScheme;
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
            backgroundColor: colorScheme.tertiary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cart Error: $e'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _claimItem({
    MockTest? test,
    Resource? resource,
  }) async {
    final colorScheme = Theme.of(context).colorScheme;
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
            backgroundColor: colorScheme.tertiary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Claim Error: $e'),
            backgroundColor: colorScheme.error,
          ),
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
    final isDownloaded = await DownloadService().isFileDownloaded(filename);

    if (isDownloaded) {
      final path = await DownloadService().getLocalPath(filename);
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
        final path =
            await DownloadService().downloadFile(resource.fileUrl!, filename);
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

  Widget _buildMockTestsTab(TestProvider provider, OfferProvider offerProvider,
      CartProvider cartProvider,
      {bool isFree = false}) {
    List<MockTest> tests = provider.tests;

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

    if (_sortOption == 'Price: Low to High') {
      tests.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortOption == 'Price: High to Low') {
      tests.sort((a, b) => b.price.compareTo(a.price));
    } else {
      tests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final purchasedTestIds = provider.purchasedTests.map((t) => t.id).toSet();
    tests = tests.where((t) => !purchasedTestIds.contains(t.id)).toList();

    return StoreGrid(
      tests: tests,
      isWide: ResponsiveWrapper.isWide(context),
      activeOffers: offerProvider.activeOffers,
      cartItemIds: cartProvider.cartItems
          .where((i) => i['test_id'] != null)
          .map((i) => i['test_id'] as int)
          .toSet(),
      purchasedTestIds: purchasedTestIds,
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
                Navigator.pop(context);
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs),
          child: Text(
            "Store",
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onBackground,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _buildSearchBar(),
          ),
          const SizedBox(height: AppSpacing.md),

          // Custom Pill Tab Bar
          Container(
            height: 40,
            width: double.infinity,
            padding: const EdgeInsets.only(left: AppSpacing.lg),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: colorScheme.onPrimary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(AppRadius.full),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              tabAlignment: TabAlignment.start,
              tabs: _labels.map((t) => Tab(text: t)).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

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
                    _buildTabContent(
                      RefreshIndicator(
                        onRefresh: _refreshAll,
                        child: CustomScrollView(
                          slivers: [
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
                    ),
                    _buildTabContent(
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
                    ),
                    _buildTabContent(
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
                    ),
                    _buildTabContent(
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
                    ),
                    _buildTabContent(
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

  Widget _buildTabContent(Widget child) {
    return child;
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: TextField(
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        style:
            theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: 'Search for tests, books...',
          hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCartIcon() {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      icon: Icon(Icons.shopping_cart_outlined, color: colorScheme.onBackground),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CartScreen()),
        );
      },
    );
  }
}
