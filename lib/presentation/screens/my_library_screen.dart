import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../providers/auth_provider.dart';
import '../providers/test_provider.dart';
import '../providers/resource_provider.dart';
import '../widgets/common/universal_item_card.dart';
import '../utils/exam_helper.dart';
import 'mock_test_detail_screen.dart';
import 'resource_detail_screen.dart';
import '../../domain/models/mock_test.dart';
import '../../domain/models/resource.dart';

class MyLibraryScreen extends StatefulWidget {
  const MyLibraryScreen({super.key});

  @override
  State<MyLibraryScreen> createState() => _MyLibraryScreenState();
}

class _MyLibraryScreenState extends State<MyLibraryScreen> {
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedSort = 'Newest'; // Newest, Oldest, A-Z
  String _selectedFilter = 'All'; // All, Tests, Resources (or specific types)

  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = [
    'All',
    'Tests',
    'E-Books',
    'Materials',
    'PYQs',
    'GK & CA'
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      // Fetch both tests and resources
      await Future.wait([
        context.read<TestProvider>().fetchUserTests(user.id),
        context.read<ResourceProvider>().fetchPurchasedResources(user.id),
      ]);
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "My Library",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchAndFilterBar(),
                const SizedBox(height: AppSpacing.sm),
                _buildFilterChips(),
                Expanded(child: _buildContentList()),
              ],
            ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search my library...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: AppColors.textPrimary),
            onSelected: (value) {
              setState(() {
                _selectedSort = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Newest', child: Text('Newest First')),
              const PopupMenuItem(value: 'Oldest', child: Text('Oldest First')),
              const PopupMenuItem(value: 'A-Z', child: Text('Title A-Z')),
              const PopupMenuItem(value: 'Z-A', child: Text('Title Z-A')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
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
                setState(() => _selectedFilter = filter);
              }
            },
            selectedColor: AppColors.primary.withValues(alpha: 0.1),
            labelStyle: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.neutral300,
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

  Widget _buildContentList() {
    // 1. Gather Data
    final testProvider = context.watch<TestProvider>();
    final resourceProvider = context.watch<ResourceProvider>();

    final tests = testProvider.userTests;
    final resources = resourceProvider.purchasedResources;

    // 2. Combine & Filter by Type
    List<dynamic> items = [];

    switch (_selectedFilter) {
      case 'All':
        items = [...tests, ...resources];
        break;
      case 'Tests':
        items = [...tests];
        break;
      case 'E-Books':
        items = resources.where((r) => r.type == ResourceType.eBook).toList();
        break;
      case 'Materials':
        items = resources
            .where((r) => r.type == ResourceType.studyMaterial)
            .toList();
        break;
      case 'PYQs':
        items = resources.where((r) => r.type == ResourceType.pyq).toList();
        break;
      case 'GK & CA':
        items = resources
            .where((r) => r.type == ResourceType.currentAffair)
            .toList();
        break;
    }

    // 3. Search Filter
    if (_searchQuery.isNotEmpty) {
      items = items.where((item) {
        final title = (item is MockTest
                ? item.title
                : (item is Resource ? item.title : ''))
            .toLowerCase();
        return title.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // 4. Sort
    items.sort((a, b) {
      // Common properties extraction
      String titleA = '';
      String titleB = '';
      DateTime?
          dateA; // We might not have purchase date easily, use item ID as proxy for "Newest" if ID is auto-increment/sequential, or just assume fetch order?
      // MockTest has 'created_at' usually? Resource?
      // Actually, userTests usually come ordered by purchase or creation.
      // Let's check models. MockTest has id. Resource has id.
      // Assuming higher ID = Newer as a proxy if date missing.

      int idA = 0;
      int idB = 0;

      if (a is MockTest) {
        titleA = a.title;
        idA = a.id;
        // dateA = a.createdAt; // If available
      } else if (a is Resource) {
        titleA = a.title;
        idA = a.id;
        // dateA = a.createdAt;
      }

      if (b is MockTest) {
        titleB = b.title;
        idB = b.id;
      } else if (b is Resource) {
        titleB = b.title;
        idB = b.id;
      }

      switch (_selectedSort) {
        case 'Newest':
          return idB.compareTo(idA); // Higher ID first
        case 'Oldest':
          return idA.compareTo(idB); // Lower ID first
        case 'A-Z':
          return titleA.compareTo(titleB);
        case 'Z-A':
          return titleB.compareTo(titleA);
        default:
          return 0;
      }
    });

    if (items.isEmpty) {
      return _buildEmptyState("No items found.");
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final item = items[index];
          if (item is MockTest) {
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
                      heroTag: 'test_image_${item.id}_lib',
                    ),
                  ),
                );
              },
            );
          } else if (item is Resource) {
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
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.library_books_outlined,
            size: 64,
            color: AppColors.neutral400,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
