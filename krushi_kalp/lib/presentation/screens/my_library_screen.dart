import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/models/mock_test.dart';
import '../../domain/models/resource.dart';
import '../../data/services/test_service.dart';
import '../../data/services/resource_service.dart';
import '../../utils/crashlytics_service.dart';
import '../providers/auth_notifier.dart';
import '../../core/theme/app_spacing.dart';
import '../widgets/common/universal_item_card.dart';
import '../utils/exam_helper.dart';
import 'mock_test_detail_screen.dart';
import 'resource_detail_screen.dart';

class MyLibraryScreen extends ConsumerStatefulWidget {
  const MyLibraryScreen({super.key});

  @override
  ConsumerState<MyLibraryScreen> createState() => _MyLibraryScreenState();
}

class _MyLibraryScreenState extends ConsumerState<MyLibraryScreen> {
  static const _pageSize = 20;
  final PagingController<int, dynamic> _pagingController =
      PagingController(firstPageKey: 0);

  String _searchQuery = '';
  String _selectedFilter = 'All';

  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = [
    'All',
    'Tests',
    'E-Books',
    'Study Material',
    'PYQs',
    'Daily CA'
  ];

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
    final user = ref.read(authProvider).user;
    if (user == null) {
      _pagingController.appendLastPage([]);
      return;
    }

    try {
      List<dynamic> newItems = [];
      bool isLastPage = false;

      if (_selectedFilter == 'All') {
        final halfSize = _pageSize ~/ 2;
        final results = await Future.wait([
          TestService.instance.fetchPaginatedUserTests(
            authUserId: user.id,
            offset: pageKey ~/ 2,
            limit: halfSize,
            searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
          ),
          ResourceService.instance.fetchPaginatedPurchasedResources(
            userId: user.id,
            offset: pageKey ~/ 2,
            limit: halfSize,
            searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
          ),
        ]);
        
        final tests = results[0] as List<MockTest>;
        final resources = results[1] as List<Resource>;
        newItems = [...tests, ...resources];
        isLastPage = tests.length < halfSize && resources.length < halfSize;
      } else if (_selectedFilter == 'Tests') {
        final tests = await TestService.instance.fetchPaginatedUserTests(
          authUserId: user.id,
          offset: pageKey,
          limit: _pageSize,
          searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        );
        newItems = tests;
        isLastPage = tests.length < _pageSize;
      } else {
        ResourceType? type;
        switch (_selectedFilter) {
          case 'E-Books': type = ResourceType.eBook; break;
          case 'Study Material': type = ResourceType.studyMaterial; break;
          case 'PYQs': type = ResourceType.pyq; break;
          case 'Daily CA': type = ResourceType.currentAffair; break;
        }

        final resources = await ResourceService.instance.fetchPaginatedPurchasedResources(
          userId: user.id,
          offset: pageKey,
          limit: _pageSize,
          type: type,
          searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        );
        newItems = resources;
        isLastPage = resources.length < _pageSize;
      }

      if (!mounted) return;

      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error, stack) {
      if (!mounted) return;
      CrashlyticsService.instance.recordError(error, stack, reason: 'library_fetch');
      _pagingController.error = error;
    }
  }

  void _updateFilter(String filter) {
    if (_selectedFilter == filter) return;
    setState(() {
      _selectedFilter = filter;
      _pagingController.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "My Library",
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchAndFilterBar(theme),
          const SizedBox(height: AppSpacing.sm),
          _buildFilterChips(theme),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _pagingController.refresh(),
              child: PagedListView<int, dynamic>.separated(
                pagingController: _pagingController,
                padding: EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.lg,
                  bottom: AppSpacing.lg + MediaQuery.of(context).padding.bottom,
                ),
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                builderDelegate: PagedChildBuilderDelegate<dynamic>(
                  itemBuilder: (context, item, index) {
                    if (item is MockTest) {
                      return _buildTestCard(item, index);
                    } else if (item is Resource) {
                      return _buildResourceCard(item, index);
                    }
                    return const SizedBox.shrink();
                  },
                  firstPageProgressIndicatorBuilder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                  newPageProgressIndicatorBuilder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                  noItemsFoundIndicatorBuilder: (_) =>
                      _buildEmptyState(theme, "No items found."),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: theme.colorScheme.surface,
      child: TextField(
        controller: _searchController,
        onSubmitted: (val) {
          _searchQuery = val.trim();
          _pagingController.refresh();
        },
        decoration: InputDecoration(
          hintText: 'Search my library...',
          prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          isDense: true,
          suffixIcon: IconButton(
            icon: const Icon(Icons.send_rounded),
            onPressed: () {
              _searchQuery = _searchController.text.trim();
              _pagingController.refresh();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return ChoiceChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                _updateFilter(filter);
              }
            },
            selectedColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            labelStyle: TextStyle(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            backgroundColor: theme.colorScheme.surface,
            side: BorderSide(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildTestCard(MockTest item, int index) {
    return UniversalItemCard(
      title: item.title,
      subtitle: 'Mock Test • ${item.totalQuestions} Qs',
      time: item.time,
      price: -1,
      coverUrl: item.signedUrl,
      actionLabel: 'Start',
      onActionTap: () => ExamHelper.startExam(context, item),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MockTestDetailScreen(
              test: item,
              isPurchased: true,
              activeOffers: const [],
              heroTag: 'test_image_${item.id}_lib_$index',
            ),
          ),
        );
      },
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildResourceCard(Resource item, int index) {
    return UniversalItemCard(
      title: item.title,
      subtitle: item.type.name.toUpperCase(),
      price: -1,
      coverUrl: item.thumbnailUrl,
      actionLabel: 'View',
      onActionTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResourceDetailScreen(resource: item),
          ),
        );
      },
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResourceDetailScreen(resource: item),
          ),
        );
      },
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildEmptyState(ThemeData theme, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

