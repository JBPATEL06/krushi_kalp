import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/services/auth_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/services/test_service.dart';
import '../../domain/models/mock_test.dart';
import '../widgets/active_test_card.dart';
import '../widgets/common/network_error_state.dart';
import 'pdf_viewer_screen.dart';
import 'mock_test_detail_screen.dart'; // Import Detail Screen
import '../../core/theme/app_spacing.dart';

class AllTestsScreen extends StatefulWidget {
  const AllTestsScreen({super.key});

  @override
  State<AllTestsScreen> createState() => _AllTestsScreenState();
}

class _AllTestsScreenState extends State<AllTestsScreen> {
  late Future<List<MockTest>> _testsFuture;
  List<int> _completedTestIds = [];

  @override
  void initState() {
    super.initState();
    _testsFuture = TestService.instance.fetchMockTests();
    _fetchUserResults();
  }

  Future<void> _fetchUserResults() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId != null) {
      final results = await TestService.instance.fetchUserResults(userId);
      if (mounted) {
        setState(() {
          _completedTestIds = results.map((r) => r['test_id'] as int).toList();
        });
      }
    } else {}
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading Result...')),
      );

      final bytes = await TestService.instance.downloadResultPdf(bucketPath);

      await file.writeAsBytes(bytes);
      _openPdf(file, title);
    } catch (e) {
      
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
      ),
      body: FutureBuilder<List<MockTest>>(
        future: _testsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return NetworkErrorState(
              message: isNetworkError(snapshot.error)
                  ? 'Unable to load tests. Check your connection.'
                  : 'Error: ${snapshot.error}',
              onRetry: () => setState(() {
                _testsFuture = TestService.instance.fetchMockTests();
              }),
            );
          }

          final tests = snapshot.data;
          if (tests == null || tests.isEmpty) {
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
                    'No tests available.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _testsFuture = TestService.instance.fetchMockTests();
              });
              await _fetchUserResults();
            },
            child: ListView.builder(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
                bottom: AppSpacing.lg + MediaQuery.of(context).padding.bottom,
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: tests.length,
              itemBuilder: (context, index) {
                final test = tests[index];
                final isCompleted = _completedTestIds.contains(test.id);
                return ActiveTestCard(
                  category: test.category,
                  title: test.title,
                  subtitle: '${test.language} â€¢ ${test.durationMinutes} mins',
                  status:
                      isCompleted ? TestStatus.evaluated : TestStatus.newTest,
                  time: '${test.durationMinutes}m',
                  questionCount: test.totalQuestions,
                  imageUrl: test.signedUrl,
                  onTap: () {
                    if (isCompleted) {
                      _downloadAndOpenResult(test.id, test.title);
                    } else {
                      // Navigate to Detail Screen for purchase/start
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
            ),
          );
        },
      ),
    );
  }
}
