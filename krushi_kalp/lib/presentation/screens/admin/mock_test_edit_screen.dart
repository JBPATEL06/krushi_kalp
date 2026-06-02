import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:krushi_kalp/utils/responsive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../utils/excel_to_json_converter.dart';
import '../../utils/ui_helpers.dart';
import '../../../domain/models/mock_test.dart';
import '../../../data/services/test_service.dart';
import '../../../data/services/mock_test_file_service.dart';
import '../../../data/services/upload_queue_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../utils/supabase_url_helper.dart';
import '../../../utils/error_utils.dart';
import '../../../utils/crashlytics_service.dart';
import '../../utils/picker_lifecycle_mixin.dart';

class MockTestEditScreen extends StatefulWidget {
  final MockTest test;
  const MockTestEditScreen({super.key, required this.test});

  @override
  State<MockTestEditScreen> createState() => _MockTestEditScreenState();
}

class _MockTestEditScreenState extends State<MockTestEditScreen> with PickerLifecycleMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _durationController;
  late TextEditingController _totalQuestionsController;
  late TextEditingController _totalMarksController;
  late TextEditingController _negativeMarksController;

  late String _selectedCategory;
  late String _selectedLanguage;
  late bool _isNegativeMarking;

  PlatformFile? _coverImage;
  PlatformFile? _questionsFile;
  Uint8List? _imageBytes;
  Uint8List? _questionsBytes;
  final List<PlatformFile> _pendingFiles = [];

  final _customCategoryController = TextEditingController();
  List<String> _categories = ['Other'];
  List<String> _languages = ['English', 'Gujarati'];
  bool _isOtherCategory = false;

  static const int maxImageSizeBytes = 50 * 1024 * 1024; // 50MB

  @override
  void initState() {
    super.initState();
    final t = widget.test;
    _titleController = TextEditingController(text: t.title);
    _descriptionController = TextEditingController(text: t.description);
    _priceController = TextEditingController(text: t.price.toString());
    _durationController =
        TextEditingController(text: t.durationMinutes?.toString() ?? '');
    _totalQuestionsController =
        TextEditingController(text: t.totalQuestions.toString());
    _totalMarksController =
        TextEditingController(text: t.totalMarks.toString());
    _negativeMarksController =
        TextEditingController(text: t.negativeMarksPerQ.toString());

    _selectedCategory = t.category;
    _selectedLanguage = t.language;
    _isNegativeMarking = t.negativeMarking;

    _loadCategoriesAndTestDetails();
  }

  void _loadCategoriesAndTestDetails() async {
    final cats = await TestService.instance.fetchCategories();
    final langs = await TestService.instance.fetchLanguages();
    final freshTest =
        await TestService.instance.fetchMockTestById(widget.test.id);
    final t = freshTest ?? widget.test;

    if (mounted) {
      setState(() {
        _titleController.text = t.title;
        _descriptionController.text = t.description;
        _priceController.text = t.price.toString();
        _durationController.text = t.durationMinutes?.toString() ?? '';
        _totalQuestionsController.text = t.totalQuestions.toString();
        _totalMarksController.text = t.totalMarks.toString();
        _negativeMarksController.text = t.negativeMarksPerQ.toString();
        _isNegativeMarking = t.negativeMarking;
        _selectedLanguage = t.language;

        _categories = cats;
        _selectedCategory = t.category;

        if (!_categories.contains(_selectedCategory) &&
            _selectedCategory.isNotEmpty) {
          _isOtherCategory = true;
          _customCategoryController.text = _selectedCategory;
          _categories.add('Other');
          _selectedCategory = 'Other';
        } else {
          _isOtherCategory = false;
          if (!_categories.contains('Other')) _categories.add('Other');
        }

        _languages = langs;
        _selectedLanguage = t.language;
        if (!_languages.contains(_selectedLanguage)) {
          _selectedLanguage =
              _languages.isNotEmpty ? _languages.first : 'English';
        }
      });
    }
  }

  Future<void> _pickCoverImage() async {
    final result = await safePickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
    if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
      final file = result.files.first;
      final bytes = await File(file.path!).readAsBytes();
      if (file.size > maxImageSizeBytes) {
        if (mounted) {
          ErrorUtils.showError(context, 'Image too large (>50MB)');
        }
        return;
      }
      setState(() {
        _coverImage = file;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _pickQuestionsFile() async {
    final result = await safePickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'json'],
    );
    if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
      final file = result.files.first;
      final bytes = await File(file.path!).readAsBytes();
      setState(() {
        _questionsFile = file;
        _questionsBytes = bytes;
      });
    }
  }

  Future<void> _pickAdditionalFiles() async {
    final result = await safePickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pendingFiles.addAll(result.files);
      });
    }
  }

  Future<void> _downloadCurrentJson() async {
    if (widget.test.filePath.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final bucket = 'mock_test';
      final path =
          SupabaseUrlHelper.extractPathFromUrl(widget.test.filePath, bucket);
      final bytes =
          await Supabase.instance.client.storage.from(bucket).download(path);

      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/${widget.test.title.replaceAll(' ', '_')}.json');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(file.path)],
          text: 'Mock Test Questions: ${widget.test.title}');
    } catch (e, stack) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('not found') || errorStr.contains('404')) {
        if (mounted) {
          ErrorUtils.showError(context,
              'The questions file is missing from Cloud Storage. Please upload a new file.');
        }
      } else {
        CrashlyticsService.instance
            .recordError(e, stack, reason: 'mock_test_edit_screen');
        if (mounted) {
          ErrorUtils.showError(context, e);
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateMockTest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final updateData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _isOtherCategory
            ? _customCategoryController.text.trim()
            : _selectedCategory,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'duration_minutes': int.tryParse(_durationController.text) ?? 60,
        'total_questions': int.tryParse(_totalQuestionsController.text) ?? 0,
        'total_marks': int.tryParse(_totalMarksController.text) ?? 0,
        'negative_marking': _isNegativeMarking,
        'negative_marks_per_q':
            double.tryParse(_negativeMarksController.text) ?? 0.0,
        'language': _selectedLanguage,
      };

      // Perform local DB update first
      await TestService.instance.updateMockTest(widget.test.id, updateData);

      if (_coverImage != null && _imageBytes != null) {
        final imagePath = 'mock_test_cover/${widget.test.id}.jpg';
        UploadQueueService().enqueue(QueuedUploadRequest(
          taskId: 'image_${widget.test.id}',
          fileName: 'Cover Edit: ${_titleController.text}',
          itemName: 'Test Cover Image',
          bucketName: 'mock_test',
          storagePath: imagePath,
          fileBytes: _imageBytes!,
          fileType: 'mock_test_cover',
          dbUpdate: {
            'table': 'mock_tests',
            'idColumn': 'test_id',
            'idValue': widget.test.id,
            'updateColumn': 'cover_image_path',
          },
          onProgress: (p) {},
          onComplete: (path) {},
          onError: (err) {},
        ));
      }

      if (_questionsFile != null && _questionsBytes != null) {
        String jsonString;
        if (_questionsFile!.extension?.toLowerCase() == 'json') {
          jsonString = utf8.decode(_questionsBytes!);
        } else {
          final jsonList = ExcelToJsonConverter.convert(_questionsBytes!);
          if (jsonList.isEmpty) {
            throw Exception('Selected Excel file is malformed or contains no valid questions. Please check the file format.');
          }
          jsonString = jsonEncode(jsonList);
        }

        final jsonBytes = utf8.encode(jsonString);
        final jsonPath = 'mock_test_json_file/${widget.test.id}.json';

        UploadQueueService().enqueue(QueuedUploadRequest(
          taskId: 'json_${widget.test.id}',
          fileName: 'Questions Edit: ${_titleController.text}',
          itemName: 'Test Questions File',
          bucketName: 'mock_test',
          storagePath: jsonPath,
          fileBytes: Uint8List.fromList(jsonBytes),
          fileType: 'mock_test_json',
          dbUpdate: {
            'table': 'mock_tests',
            'idColumn': 'test_id',
            'idValue': widget.test.id,
            'updateColumn': 'file_path',
          },
          onProgress: (p) {},
          onComplete: (path) {},
          onError: (err) {},
        ));
      }

      // Upload pending supplementary files
      for (int i = 0; i < _pendingFiles.length; i++) {
        final pFile = _pendingFiles[i];
        if (pFile.path == null) continue;

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final cleanName = pFile.name.replaceAll(RegExp(r'[^\w\.-]'), '_');
        final storagePath = 'resources/${widget.test.id}/file_${timestamp}_${i}_$cleanName';

        UploadQueueService().enqueue(QueuedUploadRequest(
          taskId: 'mock_test_supplementary_${widget.test.id}_${timestamp}_$i',
          fileName: pFile.name,
          itemName: 'Supplementary File',
          bucketName: 'mock_test',
          storagePath: storagePath,
          filePath: pFile.path,
          fileType: 'mock_test_supplementary',
          onProgress: (p) {},
          onComplete: (completedPath) async {
            try {
              await MockTestFileService.instance.addMockTestFile(
                testId: widget.test.id,
                storagePath: completedPath,
                displayName: pFile.name.replaceAll('.pdf', '').replaceAll('_', ' '),
                fileSizeBytes: pFile.size,
                fileOrder: i,
              );
            } catch (e, stack) {
              CrashlyticsService.instance.recordError(e, stack, reason: 'Failed to insert mock_test_file onComplete');
            }
          },
          onError: (err) {},
        ));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Changes saved. You can safely leave the app; files will update in the background if replaced.'),
          duration: Duration(seconds: 4),
        ));
        Navigator.pop(context, true);
      }
    } catch (e, stack) {
      CrashlyticsService.instance
          .recordError(e, stack, reason: 'mock_test_edit_screen');
      if (mounted) {
        ErrorUtils.showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Edit Mock Test',
            style: TextStyle(fontSize: context.sp(20))), // FIXED
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg + MediaQuery.of(context).padding.bottom,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  return buildFormCard(
                    context,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _titleController,
                            decoration: getPremiumInputDecoration(context,
                                labelText: 'Title',
                                prefixIcon: const Icon(Icons.title_rounded)),
                            style: theme.textTheme.bodyLarge,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: getPremiumInputDecoration(context,
                                labelText: 'Description',
                                prefixIcon:
                                    const Icon(Icons.description_outlined)),
                            style: theme.textTheme.bodyLarge,
                            maxLines: 3,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          DropdownButtonFormField<String>(
                            initialValue:
                                _categories.contains(_selectedCategory)
                                    ? _selectedCategory
                                    : null,
                            decoration: getPremiumInputDecoration(context,
                                labelText: 'Category',
                                prefixIcon:
                                    const Icon(Icons.category_outlined)),
                            dropdownColor: colorScheme.surface,
                            style: theme.textTheme.bodyLarge,
                            items: _categories
                                .map((c) =>
                                    DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() {
                                  _selectedCategory = v;
                                  _isOtherCategory = v == 'Other';
                                  if (_isOtherCategory) {
                                    _customCategoryController.clear();
                                  }
                                });
                              }
                            },
                          ),
                          if (_isOtherCategory) ...[
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _customCategoryController,
                              decoration: getPremiumInputDecoration(context,
                                  labelText: 'Enter New Category',
                                  prefixIcon: const Icon(Icons.edit_rounded)),
                              validator: (v) =>
                                  _isOtherCategory && (v == null || v.isEmpty)
                                      ? 'Required'
                                      : null,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          DropdownButtonFormField<String>(
                            initialValue: _languages.contains(_selectedLanguage)
                                ? _selectedLanguage
                                : null,
                            decoration: getPremiumInputDecoration(context,
                                labelText: 'Language',
                                prefixIcon: const Icon(Icons.language_rounded)),
                            dropdownColor: colorScheme.surface,
                            style: theme.textTheme.bodyLarge,
                            items: _languages
                                .map((c) =>
                                    DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedLanguage = v!),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          if (isWide)
                            Row(
                              children: [
                                Expanded(
                                    child: TextFormField(
                                        controller: _priceController,
                                        decoration: getPremiumInputDecoration(
                                            context,
                                            labelText: 'Price',
                                            prefixIcon: const Icon(
                                                Icons.attach_money_rounded)),
                                        keyboardType: TextInputType.number)),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                    child: TextFormField(
                                        controller: _durationController,
                                        decoration: getPremiumInputDecoration(
                                            context,
                                            labelText: 'Duration (Mins)',
                                            prefixIcon: const Icon(
                                                Icons.timer_outlined)),
                                        keyboardType: TextInputType.number)),
                              ],
                            )
                          else ...[
                            TextFormField(
                                controller: _priceController,
                                decoration: getPremiumInputDecoration(context,
                                    labelText: 'Price',
                                    prefixIcon:
                                        const Icon(Icons.attach_money_rounded)),
                                keyboardType: TextInputType.number),
                            const SizedBox(height: AppSpacing.lg),
                            TextFormField(
                                controller: _durationController,
                                decoration: getPremiumInputDecoration(context,
                                    labelText: 'Duration (Mins)',
                                    prefixIcon:
                                        const Icon(Icons.timer_outlined)),
                                keyboardType: TextInputType.number),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          if (isWide)
                            Row(
                              children: [
                                Expanded(
                                    child: TextFormField(
                                        controller: _totalQuestionsController,
                                        decoration: getPremiumInputDecoration(
                                            context,
                                            labelText: 'Total Questions',
                                            prefixIcon: const Icon(
                                                Icons.quiz_outlined)),
                                        keyboardType: TextInputType.number)),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                    child: TextFormField(
                                        controller: _totalMarksController,
                                        decoration: getPremiumInputDecoration(
                                            context,
                                            labelText: 'Total Marks',
                                            prefixIcon: const Icon(
                                                Icons.grade_outlined)),
                                        keyboardType: TextInputType.number)),
                              ],
                            )
                          else ...[
                            TextFormField(
                                controller: _totalQuestionsController,
                                decoration: getPremiumInputDecoration(context,
                                    labelText: 'Total Questions',
                                    prefixIcon:
                                        const Icon(Icons.quiz_outlined)),
                                keyboardType: TextInputType.number),
                            const SizedBox(height: AppSpacing.lg),
                            TextFormField(
                                controller: _totalMarksController,
                                decoration: getPremiumInputDecoration(context,
                                    labelText: 'Total Marks',
                                    prefixIcon:
                                        const Icon(Icons.grade_outlined)),
                                keyboardType: TextInputType.number),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Negative Marking'),
                            subtitle:
                                const Text('Apply panelty for wrong answers'),
                            value: _isNegativeMarking,
                            activeThumbColor: colorScheme.primary,
                            onChanged: (v) =>
                                setState(() => _isNegativeMarking = v),
                          ),
                          if (_isNegativeMarking) ...[
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _negativeMarksController,
                              decoration: getPremiumInputDecoration(context,
                                  labelText: 'Negative Marks per Q',
                                  prefixIcon: const Icon(
                                      Icons.remove_circle_outline_rounded)),
                              keyboardType: TextInputType.number,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xl),
                          Text('Resource Files',
                              style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: context.sp(14))), // FIXED
                          const SizedBox(height: AppSpacing.sm),
                          _buildFilePicker(
                            context,
                            icon: Icons.image_outlined,
                            title: _coverImage?.name ??
                                'Current: ${extractFilename(widget.test.coverImagePath)}',
                            onPick: _pickCoverImage,
                          ),
                          if (widget.test.filePath.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            _buildFilePicker(
                              context,
                              icon: Icons.table_chart_outlined,
                              title: _questionsFile?.name ??
                                  'Current Questions File',
                              onPick: _pickQuestionsFile,
                              onDownload: _downloadCurrentJson,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          Text('Supplementary Files (Optional)',
                              style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: context.sp(14))), // FIXED
                          const SizedBox(height: AppSpacing.sm),
                          if (_pendingFiles.isNotEmpty) ...[
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _pendingFiles.length,
                              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (context, index) {
                                final file = _pendingFiles[index];
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerLow,
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
                                              file.name,
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                fontSize: context.sp(14),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '${(file.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                                fontSize: context.sp(11),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.close_rounded, color: colorScheme.error, size: context.sp(20)),
                                        onPressed: () {
                                          setState(() {
                                            _pendingFiles.removeAt(index);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _pickAdditionalFiles,
                              icon: Icon(Icons.add_link_rounded, size: context.sp(18)),
                              label: Text('ADD SUPPLEMENTARY FILE', style: TextStyle(fontSize: context.sp(14))),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _updateMockTest,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md)),
                                elevation: 0,
                              ),
                              child: Text('UPDATE MOCK TEST',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: context.sp(16))), // FIXED
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildFilePicker(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onPick,
      VoidCallback? onDownload}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        leading: Icon(icon,
            color: colorScheme.primary, size: context.sp(24)), // FIXED
        title: Text(title,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontSize: context.sp(12)), // FIXED
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onDownload != null)
              IconButton(
                onPressed: onDownload,
                icon: Icon(Icons.download_rounded,
                    color: colorScheme.primary, size: context.sp(20)), // FIXED
                tooltip: 'Download Original JSON',
              ),
            TextButton(
                onPressed: onPick,
                child: Text('Replace',
                    style: TextStyle(fontSize: context.sp(14)))), // FIXED
          ],
        ),
      ),
    );
  }
}
