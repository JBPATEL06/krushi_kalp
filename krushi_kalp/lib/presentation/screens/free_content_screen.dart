import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart'; // NEW
import '../../core/theme/app_spacing.dart';
import '../providers/test_provider.dart';
import '../providers/resource_provider.dart';
import '../widgets/free_content/free_item_card.dart';
import '../../domain/models/mock_test.dart';
import '../../domain/models/resource.dart';
import '../screens/mock_test_detail_screen.dart';
import '../screens/resource_detail_screen.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/test_service.dart';
import '../../core/theme/app_radius.dart';
import '../widgets/common/responsive_wrapper.dart';

class FreeContentScreen extends StatefulWidget {
  const FreeContentScreen({super.key});

  @override
  State<FreeContentScreen> createState() => _FreeContentScreenState();
}

class _FreeContentScreenState extends State<FreeContentScreen> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    debugPrint('[FreeContent] 🚀 Screen initialized');
    _searchController.addListener(_onSearchChanged);

    // Safely fetch data after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    debugPrint('[FreeContent] 🔴 Screen disposed');
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
      debugPrint('[FreeContent] 🔍 Search query updated: "$_searchQuery"');
    });
  }

  Future<void> _claimItem({
    MockTest? test,
    Resource? resource,
  }) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final user = AuthService.instance.currentUser;
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
          final testProvider = context.read<TestProvider>();
          await testProvider.fetchUserTests(user.id);
          testProvider.fetchTests(forceRefresh: true);
        }
      } else if (resource != null) {
        await context
            .read<ResourceProvider>()
            .claimResource(resource.id, user.id);
        if (mounted) {
          await context
              .read<ResourceProvider>()
              .fetchPurchasedResources(user.id);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Claimed ${test?.title ?? resource?.title} successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        _fetchData();
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _fetchData() async {
    debugPrint('[FreeContent] 📥 Starting data fetch...');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = AuthService.instance.currentUser;
      final testProvider = context.read<TestProvider>();
      final resourceProvider = context.read<ResourceProvider>();

      debugPrint(
          '[FreeContent] 📡 Fetching tests and resources from providers...');

      final List<Future> futures = [
        testProvider.fetchTests(),
        resourceProvider.fetchAll(),
      ];

      if (user != null) {
        futures.add(testProvider.fetchUserTests(user.id));
        futures.add(resourceProvider.fetchPurchasedResources(user.id));
      }

      // Fetch with caching support
      await Future.wait(futures);

      final testCount = testProvider.tests.length;
      final resourceCount = resourceProvider.ebooks.length +
          resourceProvider.studyMaterials.length +
          resourceProvider.pyqs.length +
          resourceProvider.currentAffairs.length;

      debugPrint(
          '[FreeContent] ✅ Fetch complete: $testCount tests, $resourceCount resources');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('[FreeContent] ❌ Error fetching data: $e');
      debugPrint('[FreeContent] Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load content. Please try again.';
        });
      }
    }
  }

  List<dynamic> _getFilteredItems() {
    debugPrint(
        '[FreeContent] 🔧 Filtering items with filter: "$_selectedFilter", search: "$_searchQuery"');

    final testProvider = context.read<TestProvider>();
    final resourceProvider = context.read<ResourceProvider>();

    List<dynamic> items = [];

    // Gather all items based on filter
    if (_selectedFilter == 'All' || _selectedFilter == 'Tests') {
      final purchasedTestIds = testProvider.userTests.map((t) => t.id).toSet();
      items.addAll(testProvider.tests.where(
          (test) => test.price == 0 && !purchasedTestIds.contains(test.id)));
    }

    if (_selectedFilter == 'All' || _selectedFilter == 'Resources') {
      final purchasedIds = resourceProvider.purchasedResourceIds;

      items.addAll(resourceProvider.ebooks
          .where((r) => r.price == 0 && !purchasedIds.contains(r.id)));
      items.addAll(resourceProvider.studyMaterials
          .where((r) => r.price == 0 && !purchasedIds.contains(r.id)));
      items.addAll(resourceProvider.pyqs
          .where((r) => r.price == 0 && !purchasedIds.contains(r.id)));
      items.addAll(resourceProvider.currentAffairs
          .where((r) => r.price == 0 && !purchasedIds.contains(r.id)));
    }

    debugPrint(
        '[FreeContent] 📊 Found ${items.length} free items before search filter');

    // Apply search filter (Title, Description, Category)
    if (_searchQuery.isNotEmpty) {
      items = items.where((item) {
        final String title;
        final String description;
        final String category;

        if (item is MockTest) {
          title = item.title.toLowerCase();
          description = item.description.toLowerCase();
          category = item.category.toLowerCase();
        } else if (item is Resource) {
          title = item.title.toLowerCase();
          description = (item.description ?? '').toLowerCase();
          category = (item.category ?? '').toLowerCase();
        } else {
          return false;
        }

        return title.contains(_searchQuery) ||
            description.contains(_searchQuery) ||
            category.contains(_searchQuery);
      }).toList();

      debugPrint(
          '[FreeContent] 🔎 Search results: ${items.length} items match "$_searchQuery"');
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[FreeContent] 🎨 Building UI (isLoading: $_isLoading)');
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
          // Unified Top Section (Search + Filters)
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: context.sp(15),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search free content...',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: theme.colorScheme.primary.withOpacity(0.5),
                        size: context.sp(22),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded,
                                  size: context.sp(20)),
                              onPressed: () {
                                _searchController.clear();
                                debugPrint('[FreeContent] 🧹 Search cleared');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor:
                          theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                    ),
                  ),
                ),

                // Filter Chips
                Padding(
                  padding: EdgeInsets.only(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: AppSpacing.md,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Tests', 'Resources'].map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedFilter = filter;
                                debugPrint(
                                    '[FreeContent] 🏷️ Filter changed to: $filter');
                              });
                            },
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.symmetric(
                                horizontal: context.w(20),
                                vertical: context.h(8),
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.surfaceVariant
                                        .withOpacity(0.5),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outline
                                          .withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                filter,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: isSelected
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: isSelected
                                      ? FontWeight.w900
                                      : FontWeight.w600,
                                  fontSize: context.sp(13),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content Area
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final theme = Theme.of(context);
    if (_isLoading) {
      debugPrint('[FreeContent] ⏳ Showing loading indicator');
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      debugPrint('[FreeContent] ⚠️ Showing error message: $_errorMessage');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      );
    }

    final items = _getFilteredItems();

    if (items.isEmpty) {
      debugPrint('[FreeContent] 📭 No items to display');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No results found for "$_searchQuery"'
                  : 'No free content available',
              style: TextStyle(
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    debugPrint('[FreeContent] 📱 Displaying ${items.length} items in grid');

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView.separated(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: AppSpacing.md + MediaQuery.of(context).padding.bottom,
        ),
        itemCount: items.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final item = items[index];
          Widget card;

          if (item is MockTest) {
            card = _buildTestCard(item, index);
          } else if (item is Resource) {
            card = _buildResourceCard(item, index);
          } else {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: card
                .animate(delay: (index < 5 ? index * 100 : 0).ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, end: 0),
          );
        },
      ),
    );
  }

  Widget _buildTestCard(MockTest test, int index) {
    debugPrint('[FreeContent] 🧪 Building card for test: ${test.title}');
    final uniqueTag = 'test_${test.id}_$index';
    final purchasedTestIds =
        context.read<TestProvider>().userTests.map((t) => t.id).toSet();
    final isPurchased = purchasedTestIds.contains(test.id);

    return FreeItemCard(
      title: test.title,
      subtitle:
          '${test.totalQuestions} Questions • ${test.totalMarks} Marks • ${test.durationMinutes ?? 0} mins',
      typeLabel: 'Mock Test',
      coverUrl: test.signedUrl,
      actionLabel: 'Claim Free',
      isPurchased: isPurchased,
      onTap: () {
        debugPrint('[FreeContent] 🎯 Navigating to test detail: ${test.id}');
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
    );
  }

  Widget _buildResourceCard(Resource resource, int index) {
    debugPrint(
        '[FreeContent] 📚 Building card for resource: ${resource.title}');

    String typeLabel = '';
    switch (resource.type) {
      case ResourceType.eBook:
        typeLabel = 'E-Book';
        break;
      case ResourceType.studyMaterial:
        typeLabel = 'Study Material';
        break;
      case ResourceType.pyq:
        typeLabel = 'PYQ';
        break;
      case ResourceType.currentAffair:
        typeLabel = 'Current Affair';
        break;
    }

    final uniqueTag = 'resource_${resource.id}_$index';
    final purchasedIds = context.read<ResourceProvider>().purchasedResourceIds;
    final isPurchased = purchasedIds.contains(resource.id);

    return FreeItemCard(
      title: resource.title,
      subtitle: resource.category ?? 'Free Material',
      typeLabel: typeLabel,
      coverUrl: resource.thumbnailUrl,
      actionLabel: 'Claim Free',
      isPurchased: isPurchased,
      onTap: () {
        debugPrint(
            '[FreeContent] 🎯 Navigating to resource detail: ${resource.id}');
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
    );
  }
}
