import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart'; // NEW
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
  String _selectedSort = 'Newest';
  String _selectedFilter = 'All';

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
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchAndFilterBar(theme),
                const SizedBox(height: AppSpacing.sm),
                _buildFilterChips(theme),
                Expanded(child: _buildContentList()),
              ],
            ),
    );
  }

  Widget _buildSearchAndFilterBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search my library...',
                prefixIcon: Icon(Icons.search,
                    color: theme.colorScheme.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor:
                    theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          PopupMenuButton<String>(
            icon: Icon(Icons.sort, color: theme.colorScheme.onSurface),
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
                setState(() => _selectedFilter = filter);
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

  Widget _buildContentList() {
    final theme = Theme.of(context);
    final testProvider = context.watch<TestProvider>();
    final resourceProvider = context.watch<ResourceProvider>();

    final tests = testProvider.userTests;
    final resources = resourceProvider.purchasedResources;

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

    if (_searchQuery.isNotEmpty) {
      items = items.where((item) {
        final title = (item is MockTest
                ? item.title
                : (item is Resource ? item.title : ''))
            .toLowerCase();
        return title.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    items.sort((a, b) {
      String titleA = '';
      String titleB = '';
      int idA = 0;
      int idB = 0;

      if (a is MockTest) {
        titleA = a.title;
        idA = a.id;
      } else if (a is Resource) {
        titleA = a.title;
        idA = a.id;
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
          return idB.compareTo(idA);
        case 'Oldest':
          return idA.compareTo(idB);
        case 'A-Z':
          return titleA.compareTo(titleB);
        case 'Z-A':
          return titleB.compareTo(titleA);
        default:
          return 0;
      }
    });

    if (items.isEmpty) {
      return _buildEmptyState(theme, "No items found.");
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: AppSpacing.lg + MediaQuery.of(context).padding.bottom,
        ),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final item = items[index];
          Widget card = const SizedBox();

          if (item is MockTest) {
            card = UniversalItemCard(
              title: item.title,
              subtitle: 'Mock Test â€¢ ${item.totalQuestions} Qs',
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
            card = UniversalItemCard(
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
          return card
              .animate(delay: (index < 5 ? index * 100 : 0).ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1, end: 0);
        },
      ),
    );
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
