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
import '../../utils/error_utils.dart';
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

    _searchController.addListener(_onSearchChanged);

    // Safely fetch data after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  Future<void> _claimItem({
    MockTest? test,
    Resource? resource,
  }) async {
    final String itemName = test?.title ?? resource?.title ?? 'Item';

    if (_isProcessing) {
      return;
    }

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

      setState(() => _isProcessing = true);

      if (test != null) {
        await TestService.instance.claimFreeTest(
          testId: test.id,
          authUserId: user.id,
        );
        if (mounted) {
          final testProvider = context.read<TestProvider>();
          await testProvider.fetchUserTests(user.id);
          await testProvider.fetchTests(forceRefresh: true);
        }
      } else if (resource != null) {
        await context
            .read<ResourceProvider>()
            .claimResource(resource.id, user.id);
        // Provider.claimResource already calls fetchPurchasedResources
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Claimed $itemName successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        // No need to call _fetchData here if using Consumer,
        // but we'll call it to ensure all state is synced
        await _fetchData();
      }
    } catch (e) {
      if (mounted) {
        ErrorUtils.showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = AuthService.instance.currentUser;
      final testProvider = context.read<TestProvider>();
      final resourceProvider = context.read<ResourceProvider>();

      // Fetch with caching support
      await Future.wait([
        testProvider.fetchTests(forceRefresh: true),
        resourceProvider.fetchAll(forceRefresh: true),
        if (user != null) testProvider.fetchUserTests(user.id),
        if (user != null) resourceProvider.fetchPurchasedResources(user.id),
      ]);

      final testCount = testProvider.tests.length;
      final resourceCount = resourceProvider.ebooks.length +
          resourceProvider.studyMaterials.length +
          resourceProvider.pyqs.length +
          resourceProvider.currentAffairs.length;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load content. Please try again.';
        });
      }
    }
  }

  List<dynamic> _getFilteredItems(
    TestProvider testProvider,
    ResourceProvider resourceProvider,
  ) {
    List<dynamic> items = [];

    // Gather all items based on filter
    if (_selectedFilter == 'All' || _selectedFilter == 'Tests') {
      final purchasedTestIds = testProvider.purchasedTestIds;
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
    }

    return items;
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
          // Unified Top Section (Search + Filters)
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
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                        size: context.sp(22),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded,
                                  size: context.sp(20)),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor:
                          theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                                    : theme.colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.5),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outline
                                          .withValues(alpha: 0.2),
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
            child: Consumer2<TestProvider, ResourceProvider>(
              builder: (context, testProvider, resourceProvider, _) {
                return _buildContent(testProvider, resourceProvider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      TestProvider testProvider, ResourceProvider resourceProvider) {
    final theme = Theme.of(context);
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
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

    final items = _getFilteredItems(testProvider, resourceProvider);

    if (items.isEmpty) {
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
            card = _buildTestCard(item, index, testProvider);
          } else if (item is Resource) {
            card = _buildResourceCard(item, index, resourceProvider);
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

  Widget _buildTestCard(MockTest test, int index, TestProvider provider) {
    final uniqueTag = 'test_${test.id}_$index';
    final isPurchased = provider.purchasedTestIds.contains(test.id);

    return FreeItemCard(
      title: test.title,
      subtitle:
          '${test.totalQuestions} Questions â€¢ ${test.totalMarks} Marks â€¢ ${test.durationMinutes ?? 0} mins',
      typeLabel: 'Mock Test',
      coverUrl: test.signedUrl,
      actionLabel: 'Claim Free',
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
    );
  }

  Widget _buildResourceCard(
      Resource resource, int index, ResourceProvider provider) {
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
    final isPurchased = provider.purchasedResourceIds.contains(resource.id);

    return FreeItemCard(
      title: resource.title,
      subtitle: resource.category ?? 'Free Material',
      typeLabel: typeLabel,
      coverUrl: resource.thumbnailUrl,
      actionLabel: 'Claim Free',
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
    );
  }
}
