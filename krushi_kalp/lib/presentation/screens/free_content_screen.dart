import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_spacing.dart';
import '../providers/test_notifier.dart';
import '../providers/resource_notifier.dart';
import '../providers/auth_notifier.dart';
import '../providers/test_state.dart';
import '../providers/resource_state.dart';
import '../widgets/free_content/free_item_card.dart';
import '../../domain/models/mock_test.dart';
import '../../domain/models/resource.dart';
import '../screens/mock_test_detail_screen.dart';
import '../screens/resource_detail_screen.dart';
import '../../data/services/test_service.dart';
import '../../utils/error_utils.dart';
import '../../core/theme/app_radius.dart';
import '../../utils/crashlytics_service.dart';

class FreeContentScreen extends ConsumerStatefulWidget {
  const FreeContentScreen({super.key});

  @override
  ConsumerState<FreeContentScreen> createState() => _FreeContentScreenState();
}

class _FreeContentScreenState extends ConsumerState<FreeContentScreen> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
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
    if (_isProcessing) return;

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

      setState(() => _isProcessing = true);

      if (test != null) {
        await TestService.instance.claimFreeTest(
          testId: test.id,
          authUserId: user.id,
        );
        if (mounted) {
          await ref.read(testNotifierProvider.notifier).fetchUserTests(user.id);
          await ref.read(testNotifierProvider.notifier).fetchTests(forceRefresh: true);
        }
      } else if (resource != null) {
        await ref
            .read(resourceNotifierProvider.notifier)
            .claimResource(resource.id, user.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Claimed $itemName successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        await _fetchData();
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'free_content_screen');
      if (mounted) {
        ErrorUtils.showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _fetchData({bool forceRefresh = true, bool bypassThrottle = false}) async {
    if (_isProcessing) return;

    // Smart Refresh Logic: Throttling Supabase hits to 15s
    bool shouldHitSupabase = forceRefresh;
    if (forceRefresh && !bypassThrottle && _lastSyncTime != null) {
      final diff = DateTime.now().difference(_lastSyncTime!);
      if (diff < const Duration(seconds: 15)) {
        shouldHitSupabase = false;
        if (mounted && forceRefresh) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Refreshing from local cache...'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    }

    setState(() {
      _isLoading = _lastSyncTime == null; // Only show full loader if first load
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final user = ref.read(authNotifierProvider).user;
      
      // Use silent catches for each future to prevent one timeout from killing the whole UI
      await Future.wait([
        ref.read(testNotifierProvider.notifier).fetchTests(forceRefresh: shouldHitSupabase).catchError((e) {
          CrashlyticsService.instance.log('FreeContent: fetchTests failed: $e');
          return null;
        }),
        ref.read(resourceNotifierProvider.notifier).fetchAll(forceRefresh: shouldHitSupabase).catchError((e) {
          CrashlyticsService.instance.log('FreeContent: fetchAll resources failed: $e');
          return null;
        }),
        if (user != null) 
          ref.read(testNotifierProvider.notifier).fetchUserTests(user.id).catchError((e) => null),
        if (user != null) 
          ref.read(resourceNotifierProvider.notifier).fetchPurchasedResources(user.id).catchError((e) => null),
      ]);

      if (shouldHitSupabase) {
        _lastSyncTime = DateTime.now();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isProcessing = false;
        });
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'free_content_screen_fetch');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isProcessing = false;
          // Only show error if we have no data at all
          final testState = ref.read(testNotifierProvider);
          final resourceState = ref.read(resourceNotifierProvider);
          if (testState.allTests.isEmpty && resourceState.ebooks.isEmpty) {
            _errorMessage = 'Failed to load content. Please check your connection.';
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _refreshAll() async {
    // Manual refresh always bypasses throttle
    await _fetchData(forceRefresh: true, bypassThrottle: true);
  }

  List<dynamic> _getFilteredItems(
    TestState testState,
    ResourceState resourceState,
  ) {
    List<dynamic> items = [];

    if (_selectedFilter == 'All' || _selectedFilter == 'Tests') {
      final purchasedTestIds = testState.purchasedTestIds;
      items.addAll(testState.allTests.where(
          (test) => test.price == 0 && !purchasedTestIds.contains(test.id)));
    }

    if (_selectedFilter == 'All' || _selectedFilter == 'Resources') {
      final purchasedIds = resourceState.purchasedResourceIds;
      items.addAll(resourceState.ebooks
          .where((r) => r.price == 0 && !purchasedIds.contains(r.id)));
      items.addAll(resourceState.studyMaterials
          .where((r) => r.price == 0 && !purchasedIds.contains(r.id)));
      items.addAll(resourceState.pyqs
          .where((r) => r.price == 0 && !purchasedIds.contains(r.id)));
      items.addAll(resourceState.currentAffairs
          .where((r) => r.price == 0 && !purchasedIds.contains(r.id)));
    }

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
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
            onPressed: _refreshAll,
            tooltip: 'Refresh Content',
          ),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      body: Column(
        children: [
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
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search free content...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.md, bottom: AppSpacing.md),
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
                            onSelected: (val) => setState(() => _selectedFilter = filter),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final testState = ref.watch(testNotifierProvider);
                final resourceState = ref.watch(resourceNotifierProvider);
                return _buildContent(testState, resourceState);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(TestState testState, ResourceState resourceState) {
    final items = _getFilteredItems(testState, resourceState);
    
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    if (_errorMessage != null && items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: AppSpacing.md),
            Text(_errorMessage!),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(onPressed: () => _fetchData(), child: const Text('Retry')),
          ],
        ),
      );
    }

    if (items.isEmpty) return const Center(child: Text("No items found."));

    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final item = items[index];
          if (item is MockTest) {
            return _buildTestCard(item, index, testState);
          } else if (item is Resource) {
            return _buildResourceCard(item, index, resourceState);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildTestCard(MockTest test, int index, TestState state) {
    final uniqueTag = 'test_${test.id}_$index';
    final isPurchased = state.purchasedTestIds.contains(test.id);
    return FreeItemCard(
      title: test.title,
      subtitle: '${test.totalQuestions} Questions',
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

  Widget _buildResourceCard(Resource resource, int index, ResourceState state) {
    final uniqueTag = 'resource_${resource.id}_$index';
    final isPurchased = state.purchasedResourceIds.contains(resource.id);
    return FreeItemCard(
      title: resource.title,
      subtitle: resource.category ?? 'Free Material',
      typeLabel: 'Resource',
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
