import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart'; // NEW
import '../../domain/models/mock_test.dart';
import '../providers/test_provider.dart';
import '../widgets/common/universal_item_card.dart';
import '../utils/exam_helper.dart';
import '../widgets/common/download_action_button.dart';
import 'mock_test_detail_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'package:shimmer/shimmer.dart';
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
    // We rely on MainScreen's initial sync or pull-to-refresh to avoid redundant fetches
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
    final testProvider = context.watch<TestProvider>();
    final tests = testProvider.userTests;
    final filteredTests = _getFilteredData(tests);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(context),
            SliverToBoxAdapter(
              child: _buildSearchAndFilterBar(),
            ),
            if (testProvider.isLoading && tests.isEmpty)
              SliverToBoxAdapter(child: _buildSkeletonLoader())
            else if (filteredTests.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(),
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
                        child: UniversalItemCard(
                          title: item.title,
                          subtitle: 'Mock Test • ${item.totalQuestions} Qs',
                          price: -1,
                          coverUrl: item.signedUrl,
                          customAction: DownloadActionButton(
                            filename: 'mock_test_${item.id}.json',
                            url: item.contentUrl,
                            startLabel: "Start",
                            userId:
                                Supabase.instance.client.auth.currentUser?.id,
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
                          isPurchased: true,
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

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      floating: false,
      pinned: true,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true, // Center alignment
      title: Text(
        "My Mock Tests",
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search mock tests...',
              prefixIcon: const Icon(Icons.search, color: AppColors.neutral500),
              filled: true,
              fillColor: AppColors.neutral100,
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
                _buildFilterChip('Newest'),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Oldest'),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('A-Z'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _sortOption == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _sortOption = label;
        });
      },
      selectedColor: AppColors.primary.withOpacity(0.1),
      checkmarkColor: AppColors.primary,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.neutral200,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppColors.neutral400,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _searchQuery.isNotEmpty
                ? 'No matches found.'
                : 'No purchased tests yet.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () {
                context.read<NavigationProvider>().setIndex(2); // Store
              },
              child: const Text("Browse Store"),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: AppColors.neutral200,
      highlightColor: AppColors.neutral100,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: List.generate(
            4,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                          Container(height: 16, color: Colors.white),
                          const SizedBox(height: 8),
                          Container(height: 14, color: Colors.white),
                          const SizedBox(height: 12),
                          Container(width: 60, height: 12, color: Colors.white),
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
