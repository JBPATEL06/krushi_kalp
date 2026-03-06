import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart'; // NEW
import '../../core/theme/app_spacing.dart';
import '../providers/test_provider.dart';
import '../providers/resource_provider.dart';
import '../widgets/common/universal_item_card.dart';
import '../../domain/models/mock_test.dart';
import '../../domain/models/resource.dart';
import '../screens/mock_test_detail_screen.dart';
import '../screens/resource_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/test_service.dart';

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
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        _fetchData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Claim Error: $e')),
        );
      }
    }
  }

  Future<void> _fetchData() async {
    debugPrint('[FreeContent] 📥 Starting data fetch...');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final testProvider = context.read<TestProvider>();
      final resourceProvider = context.read<ResourceProvider>();

      debugPrint(
          '[FreeContent] 📡 Fetching tests and resources from providers...');

      // Fetch with caching support (won't refetch if already cached)
      await Future.wait([
        testProvider.fetchTests(),
        resourceProvider.fetchAll(),
      ]);

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
          // Search Bar
          Container(
            color: theme.colorScheme.surface,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search free content...',
                prefixIcon: Icon(Icons.search,
                    color: theme.colorScheme.onSurfaceVariant),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color: theme.colorScheme.onSurfaceVariant),
                        onPressed: () {
                          _searchController.clear();
                          debugPrint('[FreeContent] 🧹 Search cleared');
                        },
                      )
                    : null,
                filled: true,
                fillColor:
                    theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
          ),

          // Filter Chips
          Container(
            color: theme.colorScheme.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
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
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                          debugPrint(
                              '[FreeContent] 🏷️ Filter changed to: $filter');
                        });
                      },
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      selectedColor: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.5),
                      checkmarkColor: theme.colorScheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(height: 1),

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
        padding: const EdgeInsets.all(AppSpacing.md),
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

          return card
              .animate(delay: (index < 5 ? index * 100 : 0).ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1, end: 0);
        },
      ),
    );
  }

  Widget _buildTestCard(MockTest test, int index) {
    debugPrint('[FreeContent] 🧪 Building card for test: ${test.title}');
    final uniqueTag = 'test_${test.id}_$index';

    return UniversalItemCard(
      title: test.title,
      subtitle: '${test.totalQuestions} Questions • ${test.totalMarks} Marks',
      time: test.durationMinutes != null
          ? '${test.durationMinutes} mins'
          : 'No Limit',
      price: test.price,
      coverUrl: test.signedUrl,
      actionLabel: 'Claim Free',
      onTap: () {
        debugPrint('[FreeContent] 🎯 Navigating to test detail: ${test.id}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MockTestDetailScreen(
              test: test,
              isPurchased: test.price == 0,
              heroTag: uniqueTag,
            ),
          ),
        );
      },
      onActionTap: () => _claimItem(test: test),
      hideTags: true,
      heroTag: uniqueTag, // Unique tag
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

    return UniversalItemCard(
      title: resource.title,
      subtitle: typeLabel +
          (resource.category != null ? ' • ${resource.category}' : ''),
      price: resource.price,
      coverUrl: resource.thumbnailUrl,
      actionLabel: 'Claim Free',
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
      hideTags: true,
      heroTag: uniqueTag, // Unique tag
    );
  }
}
