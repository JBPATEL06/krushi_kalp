import 'dart:io';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/services/auth_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/services/test_service.dart';
import '../../domain/models/mock_test.dart';
import '../widgets/active_test_card.dart';
import '../widgets/common/network_error_state.dart';
import 'pdf_viewer_screen.dart';
import 'mock_test_detail_screen.dart';
import '../../core/theme/app_spacing.dart';
import '../../utils/crashlytics_service.dart';
import '../widgets/common/debounced_search_bar.dart';

class AllTestsScreen extends StatefulWidget {
  const AllTestsScreen({super.key});

  @override
  State<AllTestsScreen> createState() => _AllTestsScreenState();
}

class _AllTestsScreenState extends State<AllTestsScreen> {
  static const _pageSize = 20;
  final PagingController<int, MockTest> _pagingController =
      PagingController(firstPageKey: 0);

  List<int> _completedTestIds = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    _fetchUserResults();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems = await TestService.instance.fetchPaginatedMockTests(
        offset: pageKey,
        limit: _pageSize,
        searchQuery: _searchQuery,
      );

      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  void _onSearch(String query) {
    _searchQuery = query;
    _pagingController.refresh();
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserResults() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId != null) {
      try {
        final results = await TestService.instance.fetchUserResults(userId);
        if (mounted) {
          setState(() {
            _completedTestIds = results.map((r) => r.testId).toList();
          });
        }
      } catch (e, stack) {
        CrashlyticsService.instance.recordError(e, stack, reason: 'all_tests_screen: _fetchUserResults failed');
      }
    }
  }

  Future<void> _downloadAndOpenResult(int testId, String title) async {
    try {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/exam_result_$testId.pdf');

      if (await file.exists()) {
        _openPdf(file, title);
        return;
      }

      final bucketPath = 'exam_result/$testId.pdf';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading Result...')),
      );

      final bytes = await TestService.instance.downloadResultPdf(bucketPath);

      await file.writeAsBytes(bytes);
      _openPdf(file, title);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'all_tests_screen');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading result: $e')),
        );
      }
    }
  }

  void _openPdf(File file, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          file: file,
          title: '$title Result',
          password: null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'All Mock Tests',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: DebouncedSearchBar(
              hintText: 'Search mock tests...',
              onChanged: _onSearch,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _pagingController.refresh();
          await _fetchUserResults();
        },
        child: PagedListView<int, MockTest>(
          pagingController: _pagingController,
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.md,
            bottom: AppSpacing.lg + MediaQuery.of(context).padding.bottom,
          ),
          builderDelegate: PagedChildBuilderDelegate<MockTest>(
            itemBuilder: (context, test, index) {
              final isCompleted = _completedTestIds.contains(test.id);
              return ActiveTestCard(
                category: test.category,
                title: test.title,
                subtitle: '${test.language} • ${test.durationMinutes} mins',
                status:
                    isCompleted ? TestStatus.evaluated : TestStatus.newTest,
                time: '${test.durationMinutes}m',
                questionCount: test.totalQuestions,
                imageUrl: test.signedUrl,
                onTap: () {
                  if (isCompleted) {
                    _downloadAndOpenResult(test.id, test.title);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MockTestDetailScreen(test: test),
                      ),
                    );
                  }
                },
              );
            },
            firstPageErrorIndicatorBuilder: (context) => NetworkErrorState(
              message: 'Failed to load tests',
              onRetry: () => _pagingController.refresh(),
            ),
            noItemsFoundIndicatorBuilder: (context) => _buildEmptyState(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.5)),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No tests found.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
