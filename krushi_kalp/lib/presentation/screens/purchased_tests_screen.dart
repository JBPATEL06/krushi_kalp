import 'package:flutter/material.dart';
import 'package:krushi_kalp/utils/responsive.dart';
import 'package:provider/provider.dart';
import '../../data/services/auth_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/models/mock_test.dart';
import '../providers/test_provider.dart';
import '../utils/exam_helper.dart';
import '../widgets/common/download_action_button.dart';
import 'mock_test_detail_screen.dart';
import '../../core/theme/app_spacing.dart';
import 'package:shimmer/shimmer.dart';
import '../widgets/common/download_item_card.dart';
import '../providers/navigation_provider.dart';

class PurchasedTestsScreen extends StatefulWidget {
  const PurchasedTestsScreen({super.key});

  @override
  State<PurchasedTestsScreen> createState() => _PurchasedTestsScreenState();
}

class _PurchasedTestsScreenState extends State<PurchasedTestsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortOption = 'Newest';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
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
    final user = AuthService.instance.currentUser;
    if (user != null) {
      await context.read<TestProvider>().fetchUserTests(user.id);
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<MockTest> _getFilteredData(List<MockTest> tests) {
    var filtered = List<MockTest>.from(tests);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((t) => t.title.toLowerCase().contains(_searchQuery))
          .toList();
    }

    if (_sortOption == 'Newest') {
      filtered.sort((a, b) => b.id.compareTo(a.id));
    } else if (_sortOption == 'Oldest') {
      filtered.sort((a, b) => a.id.compareTo(b.id));
    } else if (_sortOption == 'A-Z') {
      filtered.sort((a, b) => a.title.compareTo(b.title));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final testProvider = context.watch<TestProvider>();
    final tests = testProvider.userTests;
    final filteredTests = _getFilteredData(tests);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(context, theme),
            SliverToBoxAdapter(
              child: _buildSearchAndFilterBar(context, theme), // FIXED: context
            ),
            if (_isLoading || (testProvider.isLoading && tests.isEmpty))
              SliverToBoxAdapter(
                  child: _buildSkeletonLoader(context, theme)) // FIXED: context
            else if (filteredTests.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(context, theme), // FIXED: context
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = filteredTests[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: DownloadItemCard(
                          title: item.title,
                          subtitle: '${item.totalQuestions} Questions',
                          coverUrl: item.signedUrl,
                          heroTag: 'test_image_${item.id}',
                          customAction: DownloadActionButton(
                            testId: item.id.toString(),
                            filename: 'mock_test_${item.id}.json',
                            url: item.contentUrl,
                            startLabel: "Start",
                            isFullWidth: false,
                            userId: AuthService.instance.currentUser?.id,
                            displayName: item.title,
                            onAction: () async {
                              if (item.contentUrl == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          "Error: Content not found for '${item.title}'")),
                                );
                                return;
                              }
                              await ExamHelper.startExam(context, item);
                            },
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MockTestDetailScreen(
                                  test: item,
                                  isPurchased: true,
                                  activeOffers: const [],
                                  heroTag: 'test_image_${item.id}',
                                ),
                              ),
                            );
                          },
                        ),
                      )
                          .animate(delay: (index < 5 ? index * 100 : 0).ms)
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.1, end: 0);
                    },
                    childCount: filteredTests.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, ThemeData theme) {
    return SliverAppBar(
      floating: false,
      pinned: true,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text(
        "Mocks",
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: context.sp(20), // FIXED: context.sp(20)
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar(BuildContext context, ThemeData theme) {
    // FIXED: context
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: context.sp(14), // FIXED: context.sp(14)
            ),
            decoration: InputDecoration(
              hintText: 'Search mock tests...',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: context.sp(14), // FIXED: context.sp(14)
              ),
              prefixIcon: Icon(Icons.search,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: context.sp(20)), // FIXED
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Sort Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(context, 'Newest', theme), // FIXED: context
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip(context, 'Oldest', theme), // FIXED: context
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip(context, 'A-Z', theme), // FIXED: context
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, ThemeData theme) {
    // FIXED: context
    final isSelected = _sortOption == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _sortOption = label;
        });
      },
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      checkmarkColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: context.sp(13), // FIXED: context.sp(13)
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    // FIXED: context
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: context.sp(64), // FIXED: context.sp(64)
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _searchQuery.isNotEmpty
                ? 'No matches found.'
                : 'No purchased tests yet.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: context.sp(16), // FIXED: context.sp(16)
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () {
                context.read<NavigationProvider>().setIndex(2); // Store
              },
              child: Text("Browse Store",
                  style: TextStyle(fontSize: context.sp(14))), // FIXED
            )
          ]
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader(BuildContext context, ThemeData theme) {
    // FIXED: context
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerHighest,
      highlightColor: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: List.generate(
            4,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Container(
                width: double.infinity,
                height: context.h(120), // FIXED
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: context.w(80), // FIXED
                      height: context.h(80), // FIXED
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                              height: context.h(16),
                              color: theme.colorScheme.surface), // FIXED
                          const SizedBox(height: AppSpacing.xs),
                          Container(
                              height: context.h(14),
                              color: theme.colorScheme.surface), // FIXED
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                              width: context.w(60),
                              height: context.h(12),
                              color: theme.colorScheme.surface), // FIXED
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
