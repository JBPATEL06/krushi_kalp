import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:krushi_kalp/utils/responsive.dart';
import 'package:krushi_kalp/core/theme/app_spacing.dart';
import 'package:krushi_kalp/core/theme/app_radius.dart';
import 'package:krushi_kalp/data/services/test_service.dart';
import 'package:krushi_kalp/data/services/admin_service.dart';
import 'package:krushi_kalp/domain/models/mock_test.dart';
import 'package:krushi_kalp/utils/supabase_url_helper.dart';
import 'package:krushi_kalp/utils/network_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:krushi_kalp/utils/excel_to_json_converter.dart';

import '../mock_test_edit_screen.dart';
import '../../../../utils/crashlytics_service.dart';
import '../../../../utils/error_utils.dart';
import '../admin_grant_access_screen.dart' as admin_grant;
import 'package:file_picker/file_picker.dart';
import '../../../../domain/models/mock_test_file.dart';
import '../../../../data/services/mock_test_file_service.dart';
import '../../../../data/services/upload_queue_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../utils/picker_lifecycle_mixin.dart';


class AdminMockTestDetailScreen extends StatefulWidget {
  final MockTest test;

  const AdminMockTestDetailScreen({super.key, required this.test});

  @override
  State<AdminMockTestDetailScreen> createState() =>
      _AdminMockTestDetailScreenState();
}

class _AdminMockTestDetailScreenState extends State<AdminMockTestDetailScreen> with PickerLifecycleMixin {
  late MockTest _test;
  Map<String, dynamic>? _stats;
  bool _isLoadingStats = true;
  List<MockTestFile> _quizzes = [];
  List<MockTestFile> _supplementaryFiles = [];
  bool _isLoadingFiles = true;

  @override
  void initState() {
    super.initState();
    _test = widget.test;
    _loadStats();
    _loadSupplementaryFiles();
  }

  Future<void> _loadSupplementaryFiles() async {
    if (!mounted) return;
    setState(() => _isLoadingFiles = true);
    try {
      final files = await MockTestFileService.instance.fetchMockTestFiles(_test.id);
      if (mounted) {
        setState(() {
          _quizzes = files.where((f) => f.isQuiz).toList();
          _supplementaryFiles = files.where((f) => !f.isQuiz).toList();
          _isLoadingFiles = false;
        });
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'admin_mock_test_detail_screen _loadSupplementaryFiles');
      if (mounted) {
        setState(() => _isLoadingFiles = false);
      }
    }
  }

  Future<void> _renameFile(MockTestFile file) async {
    final controller = TextEditingController(text: file.displayName);
    final formKey = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename File'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Display Name'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      try {
        await MockTestFileService.instance.renameMockTestFile(file.id, controller.text.trim());
        await _loadSupplementaryFiles();
      } catch (e, stack) {
        CrashlyticsService.instance.recordError(e, stack, reason: 'Rename supplementary file failed');
        if (mounted) ErrorUtils.showError(context, e);
      }
    }
  }

  Future<void> _deleteFile(MockTestFile file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete File?'),
        content: Text('Are you sure you want to delete "${file.displayName}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await MockTestFileService.instance.deleteMockTestFile(file.id, file.storagePath);
        await _loadSupplementaryFiles();
      } catch (e, stack) {
        CrashlyticsService.instance.recordError(e, stack, reason: 'Delete supplementary file failed');
        if (mounted) ErrorUtils.showError(context, e);
      }
    }
  }

  Future<void> _replaceFile(MockTestFile file) async {
    final allowedExts = file.isQuiz ? ['json', 'xlsx', 'xls'] : ['pdf'];
    final result = await safePickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExts,
    );
    if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
      final platformFile = result.files.first;
      final ext = platformFile.name.split('.').last.toLowerCase();
      
      String? uploadFilePath = platformFile.path;
      int fileSize = platformFile.size;

      // Handle Excel -> JSON conversion for replacement if needed
      if (file.isQuiz) {
        if (ext == 'xlsx' || ext == 'xls') {
          try {
            final bytes = await File(platformFile.path!).readAsBytes();
            final jsonList = ExcelToJsonConverter.convert(bytes);
            if (jsonList.isEmpty) {
              throw Exception('Excel contains no valid questions.');
            }
            final jsonStr = jsonEncode(jsonList);
            final tempDir = await getTemporaryDirectory();
            final tempFile = File('${tempDir.path}/temp_replace_${file.id}.json');
            await tempFile.writeAsString(jsonStr);
            uploadFilePath = tempFile.path;
            fileSize = utf8.encode(jsonStr).length;
          } catch (e) {
            if (mounted) {
              ErrorUtils.showError(context, 'Excel conversion failed: $e');
            }
            return;
          }
        } else if (ext == 'json') {
          // Verify JSON structure
          try {
            final bytes = await File(platformFile.path!).readAsBytes();
            final decoded = jsonDecode(utf8.decode(bytes));
            if (decoded is! List) throw 'JSON must be a list of questions';
          } catch (e) {
            if (mounted) {
              ErrorUtils.showError(context, 'Invalid JSON file: $e');
            }
            return;
          }
        }
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final cleanName = platformFile.name.replaceAll(RegExp(r'[^\w\.-]'), '_');
      final newPath = file.isQuiz
          ? 'mock_test_json_file/${_test.id}/${timestamp}_$cleanName.json'
          : 'resources/${_test.id}/file_${timestamp}_$cleanName';

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Starting replacement upload... You can safely leave the screen.'),
          duration: Duration(seconds: 3),
        ),
      );

      UploadQueueService().enqueue(QueuedUploadRequest(
        taskId: 'replace_mock_test_file_${file.id}',
        fileName: platformFile.name,
        itemName: 'Replace File',
        bucketName: 'mock_test',
        storagePath: newPath,
        filePath: uploadFilePath,
        fileType: file.isQuiz ? 'mock_test_json' : 'mock_test_supplementary',
        onProgress: (p) {},
        onComplete: (completedPath) async {
          try {
            // Delete the old file in Storage
            await MockTestFileService.instance.deleteFileFromStorage(file.storagePath).catchError((_) => null);
            // Update table record
            await Supabase.instance.client.from('mock_test_files').update({
              'storage_path': completedPath,
              'file_size_bytes': fileSize,
              'updated_at': DateTime.now().toIso8601String(),
            }).eq('id', file.id);

            await _loadSupplementaryFiles();
          } catch (e, stack) {
            CrashlyticsService.instance.recordError(e, stack, reason: 'Failed to update record on file replacement');
          }
        },
        onError: (err) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('File replacement failed: $err'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
      ));
    }
  }

  Future<void> _addQuizFile() async {
    final result = await safePickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'xlsx', 'xls'],
    );
    if (result == null || result.files.isEmpty || result.files.first.path == null) return;
    
    final platformFile = result.files.first;
    final ext = platformFile.name.split('.').last.toLowerCase();
    final nameWithoutExt = platformFile.name.contains('.')
        ? platformFile.name.substring(0, platformFile.name.lastIndexOf('.'))
        : platformFile.name;
        
    final nameController = TextEditingController(text: nameWithoutExt);
    final formKey = GlobalKey<FormState>();
    
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Quiz'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Quiz Display Name'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (confirmed != true || nameController.text.trim().isEmpty) return;
    final displayName = nameController.text.trim();

    String? uploadFilePath = platformFile.path;
    int fileSize = platformFile.size;

    if (ext == 'xlsx' || ext == 'xls') {
      try {
        final bytes = await File(platformFile.path!).readAsBytes();
        final jsonList = ExcelToJsonConverter.convert(bytes);
        if (jsonList.isEmpty) {
          throw Exception('Excel contains no valid questions.');
        }
        final jsonStr = jsonEncode(jsonList);
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/temp_add_${_test.id}_${DateTime.now().millisecondsSinceEpoch}.json');
        await tempFile.writeAsString(jsonStr);
        uploadFilePath = tempFile.path;
        fileSize = utf8.encode(jsonStr).length;
      } catch (e) {
        if (mounted) ErrorUtils.showError(context, 'Excel conversion failed: $e');
        return;
      }
    } else if (ext == 'json') {
      try {
        final bytes = await File(platformFile.path!).readAsBytes();
        final decoded = jsonDecode(utf8.decode(bytes));
        if (decoded is! List) throw 'JSON must be a list of questions';
      } catch (e) {
        if (mounted) ErrorUtils.showError(context, 'Invalid JSON file: $e');
        return;
      }
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanName = displayName.replaceAll(RegExp(r'[^\w\.-]'), '_');
    final newPath = 'mock_test_json_file/${_test.id}/${timestamp}_$cleanName.json';

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Starting quiz upload... You can safely leave the screen.'),
        duration: Duration(seconds: 3),
      ),
    );

    final int nextOrder = _quizzes.length;

    UploadQueueService().enqueue(QueuedUploadRequest(
      taskId: 'add_mock_test_quiz_${_test.id}_$timestamp',
      fileName: platformFile.name,
      itemName: 'Add Quiz: $displayName',
      bucketName: 'mock_test',
      storagePath: newPath,
      filePath: uploadFilePath,
      fileType: 'mock_test_json',
      onProgress: (p) {},
      onComplete: (completedPath) async {
        try {
          await MockTestFileService.instance.addMockTestFile(
            testId: _test.id,
            storagePath: completedPath,
            displayName: displayName,
            fileSizeBytes: fileSize,
            fileOrder: nextOrder,
            fileType: 'quiz_json',
          );
          await _loadSupplementaryFiles();
        } catch (e, stack) {
          CrashlyticsService.instance.recordError(e, stack, reason: 'Failed to insert mock test file on add_mock_test_quiz');
        }
      },
      onError: (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Quiz upload failed: $err'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
    ));
  }

  Future<void> _addSupplementaryFile() async {
    final result = await safePickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty || result.files.first.path == null) return;
    
    final platformFile = result.files.first;
    final nameWithoutExt = platformFile.name.replaceAll('.pdf', '').replaceAll('_', ' ');
    final nameController = TextEditingController(text: nameWithoutExt);
    final formKey = GlobalKey<FormState>();
    
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Supplementary File'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Display Name'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (confirmed != true || nameController.text.trim().isEmpty) return;
    final displayName = nameController.text.trim();

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanName = displayName.replaceAll(RegExp(r'[^\w\.-]'), '_');
    final newPath = 'resources/${_test.id}/file_${timestamp}_$cleanName.pdf';

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Starting supplementary file upload... You can safely leave the screen.'),
        duration: Duration(seconds: 3),
      ),
    );

    final int nextOrder = _supplementaryFiles.length;

    UploadQueueService().enqueue(QueuedUploadRequest(
      taskId: 'add_mock_test_pdf_${_test.id}_$timestamp',
      fileName: platformFile.name,
      itemName: 'Add PDF: $displayName',
      bucketName: 'mock_test',
      storagePath: newPath,
      filePath: platformFile.path,
      fileType: 'mock_test_supplementary',
      onProgress: (p) {},
      onComplete: (completedPath) async {
        try {
          await MockTestFileService.instance.addMockTestFile(
            testId: _test.id,
            storagePath: completedPath,
            displayName: displayName,
            fileSizeBytes: platformFile.size,
            fileOrder: nextOrder,
            fileType: 'supplementary_pdf',
          );
          await _loadSupplementaryFiles();
        } catch (e, stack) {
          CrashlyticsService.instance.recordError(e, stack, reason: 'Failed to insert mock test file on add_mock_test_pdf');
        }
      },
      onError: (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: $err'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
    ));
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    double size = bytes.toDouble();
    int suffixIndex = 0;
    while (size >= 1024 && suffixIndex < suffixes.length - 1) {
      size /= 1024;
      suffixIndex++;
    }
    return "${size.toStringAsFixed(2)} ${suffixes[suffixIndex]}";
  }

  Future<void> _loadStats() async {
    try {
      final stats = await AdminService.getMockTestItemStats(_test.id);
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'admin_mock_test_detail_screen');
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  Future<void> _deleteTest() async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
            'Are you sure you want to delete this mock test? This action cannot be undone.'),
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

    if (confirmed == true) {
      try {
        await TestService.instance.deleteMockTest(_test.id);
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e, stack) {
        CrashlyticsService.instance.recordError(e, stack, reason: 'admin_mock_test_detail_screen');
        if (mounted) {
          ErrorUtils.showError(context, e);
        }
      }
    }
  }

  Future<void> _downloadQuestions() async {
    if (_test.filePath.isEmpty) return;

    try {
      const bucket = 'mock_test';
      final path = SupabaseUrlHelper.extractPathFromUrl(_test.filePath, bucket);
      final signedUrl = await SupabaseUrlHelper().getFreshSignedUrl(bucket, path);
      
      if (signedUrl.isEmpty || !signedUrl.startsWith('http')) {
        throw Exception('File does not exist in Cloud Storage. You may need to re-upload it.');
      }

      await NetworkUtils.downloadAndOpen(
        url: signedUrl,
        fileName: '${_test.title.replaceAll(' ', '_')}.json',
        onStatus: (status) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(status), duration: const Duration(seconds: 1)),
            );
          }
        },
      );
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'admin_mock_test_detail_screen');
      if (mounted) {
        ErrorUtils.showError(context, e);
      }
    }
  }

  void _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MockTestEditScreen(test: _test),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Mock Test Details',
            style: TextStyle(fontSize: context.sp(20))), // FIXED
        actions: [
          IconButton(
            icon: const Icon(Icons.card_giftcard),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => admin_grant.AdminGrantAccessScreen(
                    itemType: 'test',
                    itemId: _test.id,
                    itemTitle: _test.title,
                    itemSnapshot: _test.toJson(),
                  ),
                ),
              );
            },
            tooltip: 'Gift Access',
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: _navigateToEdit,
            tooltip: 'Edit',
          ),
          IconButton(
            icon: Icon(Icons.delete_rounded, color: colorScheme.error),
            onPressed: _deleteTest,
            tooltip: 'Delete',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadStats();
          await _loadSupplementaryFiles();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail
                  Container(
                    width: context.sp(100), // FIXED
                    height: context.sp(100), // FIXED
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: _test.signedUrl != null && _test.signedUrl!.startsWith('http')
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Image.network(
                              _test.signedUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(Icons.assignment_rounded,
                            size: context.sp(40), // FIXED
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5)),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _test.category.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _test.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: context.sp(24)), // FIXED
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _test.language,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Text(
                              _test.price == 0
                                  ? 'FREE'
                                  : '₹${_test.price.toStringAsFixed(0)}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: _test.price == 0
                                    ? const Color(0xFF10B981)
                                    : colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: context.sp(20), // FIXED
                              ),
                            ),
                            if (_test.mrp != null &&
                                _test.mrp! > _test.price) ...[
                              const SizedBox(width: 8),
                              Text(
                                '₹${_test.mrp!.toStringAsFixed(0)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Key Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildInfoBox(
                    context,
                    label: 'MOCK TESTS',
                    value: '${_test.totalQuestions}',
                    icon: Icons.help_outline_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildInfoBox(
                    context,
                    label: 'DURATION',
                    value: _test.time,
                    icon: Icons.timer_outlined,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildInfoBox(
                    context,
                    label: 'MARKS / QUESTION',
                    value: _test.marksPerQuestion.toString().replaceAll(RegExp(r'\.0$'), ''),
                    icon: Icons.emoji_events_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Performance Stats
            _buildSectionHeader(context, "PERFORMANCE STATS"),
            const SizedBox(height: AppSpacing.sm),
            _buildStatCard(
              context,
              label: 'Total Sales',
              value: _isLoadingStats ? '...' : '${_stats?['salesCount'] ?? 0}',
              icon: Icons.shopping_cart_rounded,
              color: Colors.blue,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Settings Section
            _buildSectionHeader(context, "TEST SETTINGS"),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  _buildSettingRow(
                    context,
                    label: 'Negative Marking',
                    value: _test.negativeMarking ? 'Enabled' : 'Disabled',
                    icon: Icons.remove_circle_outline_rounded,
                    color: _test.negativeMarking
                        ? Colors.orange
                        : colorScheme.onSurfaceVariant,
                  ),
                  if (_test.negativeMarking) ...[
                    const Divider(height: 1),
                    _buildSettingRow(
                      context,
                      label: 'Marks per Incorrect',
                      value: '-${_test.negativeMarksPerQ}',
                      icon: Icons.trending_down_rounded,
                      color: Colors.red,
                    ),
                  ],
                  const Divider(height: 1),
                  _buildSettingRow(
                    context,
                    label: 'Created On',
                    value: _formatDate(_test.createdAt),
                    icon: Icons.calendar_today_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Content/Quizzes section
            if (_quizzes.isEmpty && _test.filePath.isNotEmpty) ...[
              _buildSectionHeader(context, "CONTENT FILES"),
              const SizedBox(height: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: ListTile(
                  leading: Icon(Icons.description_outlined,
                      color: colorScheme.primary),
                  title: const Text('Questions File (JSON)'),
                  subtitle: Text(_test.filePath.split('/').last),
                  trailing: IconButton(
                    icon: const Icon(Icons.download_for_offline_outlined),
                    onPressed: _downloadQuestions,
                    color: colorScheme.primary,
                    tooltip: 'Download original JSON',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ] else ...[
              _buildSectionHeader(context, "QUIZZES"),
              const SizedBox(height: AppSpacing.sm),
              if (_quizzes.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    'No quiz files attached.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _quizzes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final file = _quizzes[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.quiz_outlined, color: colorScheme.primary, size: context.sp(22)),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.displayName,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: context.sp(14),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (file.fileSizeBytes != null)
                                  Text(
                                    _formatBytes(file.fileSizeBytes!),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: context.sp(11),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert_rounded, color: colorScheme.onSurfaceVariant, size: context.sp(20)),
                            onSelected: (action) {
                              if (action == 'rename') {
                                _renameFile(file);
                              } else if (action == 'replace') {
                                _replaceFile(file);
                              } else if (action == 'delete') {
                                _deleteFile(file);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'rename',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Rename'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'replace',
                                child: Row(
                                  children: [
                                    Icon(Icons.swap_horiz_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Replace File'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_rounded, color: Colors.red, size: 18),
                                    SizedBox(width: 8),
                                    Text('Delete File', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addQuizFile,
                  icon: Icon(Icons.add_circle_outline_rounded, size: context.sp(18)),
                  label: Text('ADD NEW QUIZ FILE', style: TextStyle(fontSize: context.sp(14))),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            // Supplementary Files section
            _buildSectionHeader(context, 'SUPPLEMENTARY FILES'),
            const SizedBox(height: AppSpacing.sm),
            if (_isLoadingFiles)
              const Center(child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: CircularProgressIndicator(),
              ))
            else ...[
              if (_supplementaryFiles.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    'No supplementary files attached.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _supplementaryFiles.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final file = _supplementaryFiles[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf_outlined, color: colorScheme.error, size: context.sp(22)),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.displayName,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: context.sp(14),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (file.fileSizeBytes != null)
                                  Text(
                                    _formatBytes(file.fileSizeBytes!),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: context.sp(11),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert_rounded, color: colorScheme.onSurfaceVariant, size: context.sp(20)),
                            onSelected: (action) {
                              if (action == 'rename') {
                                _renameFile(file);
                              } else if (action == 'replace') {
                                _replaceFile(file);
                              } else if (action == 'delete') {
                                _deleteFile(file);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'rename',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Rename'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'replace',
                                child: Row(
                                  children: [
                                    Icon(Icons.swap_horiz_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Replace File'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_rounded, color: Colors.red, size: 18),
                                    SizedBox(width: 8),
                                    Text('Delete File', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addSupplementaryFile,
                  icon: Icon(Icons.add_link_rounded, size: context.sp(18)),
                  label: Text('ADD SUPPLEMENTARY FILE', style: TextStyle(fontSize: context.sp(14))),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),

            // Description
            _buildSectionHeader(context, "DESCRIPTION"),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Text(
                _test.description.isEmpty
                    ? 'No description provided.'
                    : _test.description,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 0.0), // Reduced
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
          fontSize: context.sp(12), // FIXED
        ),
      ),
    );
  }

  Widget _buildInfoBox(BuildContext context,
      {required String label, required String value, required IconData icon}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, size: context.sp(20), color: colorScheme.primary), // FIXED
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold, fontSize: context.sp(16)), // FIXED
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: context.sp(8), // FIXED
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: context.sp(24)), // FIXED
          ),
          const SizedBox(width: AppSpacing.lg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: context.sp(24)), // FIXED
              ),
              Text(
                label,
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(BuildContext context,
      {required String label,
      required String value,
      required IconData icon,
      required Color color}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(icon, size: context.sp(20), color: color), // FIXED
          const SizedBox(width: AppSpacing.md),
          Text(label, style: theme.textTheme.bodyMedium),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
