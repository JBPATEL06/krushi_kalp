import 'dart:async';
import 'package:flutter/material.dart';
import 'package:krushi_kalp/utils/responsive.dart';
import '../../../../data/services/test_service.dart';
import '../../../../domain/models/mock_test.dart';
import '../../mock_test_upload_screen.dart';
import 'admin_mock_test_detail_screen.dart';
import 'package:krushi_kalp/core/theme/app_spacing.dart';
import 'package:krushi_kalp/core/theme/app_radius.dart';

class AdminMockTestList extends StatefulWidget {
  final bool? isFree; // null = all, true = free only, false = paid only

  const AdminMockTestList({super.key, this.isFree});

  @override
  State<AdminMockTestList> createState() => _AdminMockTestListState();
}

class _AdminMockTestListState extends State<AdminMockTestList> {
  // State
  List<MockTest> _allTests = [];
  List<MockTest> _displayTests = [];
  bool _isLoading = true;
  StreamSubscription? _subscription;

  // Filters
  String _searchQuery = '';
  String _sortOption = 'newest'; // newest, oldest, price_asc, price_desc

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() => _isLoading = true);
    _subscription = TestService.instance.streamMockTests().listen((tests) {
      if (mounted) {
        setState(() {
          _allTests = tests;
          _isLoading = false;
          _applyFilters();
        });
      }
    }, onError: (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    });
  }

  void _applyFilters() {
    List<MockTest> temp = List.from(_allTests);

    // 0. Filter by isFree (if set)
    if (widget.isFree != null) {
      if (widget.isFree == true) {
        temp = temp.where((t) => t.price == 0).toList();
      } else {
        temp = temp.where((t) => t.price > 0).toList();
      }
    }

    // 1. Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      temp = temp
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              t.category.toLowerCase().contains(q))
          .toList();
    }

    // 2. Sort
    switch (_sortOption) {
      case 'oldest':
        temp.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'price_asc':
        temp.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        temp.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'newest':
      default:
        temp.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    setState(() {
      _displayTests = temp;
    });
  }

  Future<void> _deleteTest(int id) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('Delete Test?'),
        content: const Text(
            'This action cannot be undone. All associated progress and data will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await TestService.instance.deleteMockTest(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Test deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MockTestUploadScreen()),
          );
        },
        label: Text('ADD TEST',
            style: TextStyle(fontSize: context.sp(14))), // FIXED
        icon: const Icon(Icons.add_rounded),
        elevation: 2,
      ),
      body: Column(
        children: [
          // Search & Sort Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                  bottom: BorderSide(
                      color:
                          colorScheme.outlineVariant.withValues(alpha: 0.5))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Tests',
                    labelStyle: TextStyle(fontSize: context.sp(14)), // FIXED
                    prefixIcon: Icon(Icons.search_rounded,
                        size: context.sp(20)), // FIXED
                    hintText: 'Search by title or category...',
                    hintStyle: TextStyle(fontSize: context.sp(14)), // FIXED
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                    _applyFilters();
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Text(
                      "SORT BY",
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurfaceVariant,
                        letterSpacing: 1.2,
                        fontSize: context.sp(10), // FIXED
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildSortChip('Newest', 'newest'),
                            _buildSortChip('Oldest', 'oldest'),
                            _buildSortChip('Price: Low', 'price_asc'),
                            _buildSortChip('Price: High', 'price_desc'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _subscription?.cancel();
                _loadData();
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _displayTests.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 100),
                            child: _buildEmptyState(),
                          ),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.only(
                            top: AppSpacing.md,
                            bottom: AppSpacing.md +
                                MediaQuery.of(context).padding.bottom +
                                80, // Space for FAB
                          ),
                          itemCount: _displayTests.length,
                          itemBuilder: (context, index) {
                            return _buildMockTestRow(
                                context, _displayTests[index]);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockTestRow(BuildContext context, MockTest test) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AdminMockTestDetailScreen(test: test)),
          );
          if (result == true) {
            // refresh data is already handled by the stream subscription
            // but if something changed that stream doesn't catch, we could trigger a refresh.
            // streamMockTests() should handle it.
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5))),
          ),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: context.sp(48), // FIXED
                height: context.sp(48), // FIXED
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: test.signedUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          test.signedUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                              Icons.broken_image_rounded,
                              size: context.sp(20), // FIXED
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5)),
                        ),
                      )
                    : Icon(Icons.description_rounded,
                        size: context.sp(24), // FIXED
                        color: colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5)),
              ),
              const SizedBox(width: AppSpacing.md),
              // Name and Category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: context.sp(14)), // FIXED
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          test.category.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: context.sp(9), // FIXED
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                                color: colorScheme.outline,
                                shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(
                          "${test.totalQuestions} Questions",
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                            fontWeight: FontWeight.bold,
                            fontSize: context.sp(10), // FIXED
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Price and Delete
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    test.price == 0 ? 'FREE' : '₹${test.price}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: test.price == 0
                          ? const Color(0xFF10B981)
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                      fontSize: context.sp(12), // FIXED
                    ),
                  ),
                  const SizedBox(height: 4),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        color: colorScheme.error.withValues(alpha: 0.5),
                        size: context.sp(16)), // FIXED
                    onPressed: () => _deleteTest(test.id),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_late_outlined,
              size: context.sp(64), // FIXED
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No tests found.',
            style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: context.sp(16), // FIXED
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _sortOption == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          if (selected) {
            setState(() {
              _sortOption = value;
              _applyFilters();
            });
          }
        },
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        selectedColor: colorScheme.primary.withValues(alpha: 0.1),
        checkmarkColor: colorScheme.primary,
        labelStyle: theme.textTheme.labelMedium?.copyWith(
          color:
              isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
    );
  }
}
