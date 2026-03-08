import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../utils/excel_to_json_converter.dart';
import '../../utils/ui_helpers.dart';
import '../../../domain/models/mock_test.dart';
import '../../../data/services/test_service.dart';
import '../../../data/services/background_upload_service.dart';
import '../../../data/services/transfer_notification_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../utils/supabase_url_helper.dart';
import '../../../utils/error_utils.dart';

class MockTestEditScreen extends StatefulWidget {
  final MockTest test;
  const MockTestEditScreen({super.key, required this.test});

  @override
  State<MockTestEditScreen> createState() => _MockTestEditScreenState();
}

class _MockTestEditScreenState extends State<MockTestEditScreen> {
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

  final _customCategoryController = TextEditingController();
  List<String> _categories = ['Other'];
  List<String> _languages = ['English', 'Gujarati'];
  bool _isOtherCategory = false;

  static const int maxImageSizeBytes = 200 * 1024; // 200KB

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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null) {
      final file = result.files.first;
      if (file.size > maxImageSizeBytes) {
        if (mounted) {
          ErrorUtils.showError(context, 'Image too large (>200KB)');
        }
        return;
      }
      setState(() {
        _coverImage = file;
        _imageBytes = file.bytes;
      });
    }
  }

  Future<void> _pickQuestionsFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'json'],
      withData: true,
    );
    if (result != null) {
      final file = result.files.first;
      setState(() {
        _questionsFile = file;
        _questionsBytes = file.bytes;
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
    } catch (e) {
      if (mounted) {
        ErrorUtils.showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateMockTest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;

    try {
      final Map<String, dynamic> updates = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _isOtherCategory
            ? _customCategoryController.text.trim()
            : _selectedCategory,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'duration_minutes': int.tryParse(_durationController.text),
        'total_questions': int.tryParse(_totalQuestionsController.text) ?? 0,
        'total_marks': int.tryParse(_totalMarksController.text) ?? 0,
        'negative_marking': _isNegativeMarking,
        'negative_marks_per_q':
            double.tryParse(_negativeMarksController.text) ?? 0.0,
        'language': _selectedLanguage,
      };

      // Perform local DB update first
      await TestService.instance.updateMockTest(widget.test.id, updates);

      if (_coverImage != null && _imageBytes != null) {
        final imagePath = 'mock_test_cover/${widget.test.id}.jpg';
        BackgroundUploadService().uploadFile(
          fileName: 'Cover Edit: ${_titleController.text}',
          bucketName: 'mock_test',
          storagePath: imagePath,
          fileBytes: _imageBytes!,
          fileType: 'mock_test_cover',
          onProgress: (p) => TransferNotificationService().showUploadProgress(
            taskId: 'image_${widget.test.id}',
            fileName: 'Cover for ${_titleController.text}',
            progress: p,
          ),
          onComplete: (path) async {
            await supabase.from('mock_tests').update(
                {'cover_image_path': path}).eq('test_id', widget.test.id);
            TransferNotificationService().showUploadSuccess(
              taskId: 'image_${widget.test.id}',
              fileName: 'Cover replacement',
            );
          },
          onError: (err) => TransferNotificationService().showUploadFailure(
            taskId: 'image_${widget.test.id}',
            fileName: 'Cover replacement',
            error: err,
          ),
        );
      }

      if (_questionsFile != null && _questionsBytes != null) {
        String jsonString;
        if (_questionsFile!.extension?.toLowerCase() == 'json') {
          jsonString = utf8.decode(_questionsBytes!);
        } else {
          final jsonList = ExcelToJsonConverter.convert(_questionsBytes!);
          jsonString = jsonEncode(jsonList);
        }

        final jsonBytes = utf8.encode(jsonString);
        final jsonPath = 'mock_test_json_file/${widget.test.id}.json';

        BackgroundUploadService().uploadFile(
          fileName: 'Questions Edit: ${_titleController.text}',
          bucketName: 'mock_test',
          storagePath: jsonPath,
          fileBytes: Uint8List.fromList(jsonBytes),
          fileType: 'mock_test_json',
          onProgress: (p) => TransferNotificationService().showUploadProgress(
            taskId: 'json_${widget.test.id}',
            fileName: 'Questions for ${_titleController.text}',
            progress: p,
          ),
          onComplete: (path) async {
            await supabase
                .from('mock_tests')
                .update({'file_path': path}).eq('test_id', widget.test.id);
            TransferNotificationService().showUploadSuccess(
              taskId: 'json_${widget.test.id}',
              fileName: 'Questions replacement',
            );
          },
          onError: (err) => TransferNotificationService().showUploadFailure(
            taskId: 'json_${widget.test.id}',
            fileName: 'Questions replacement',
            error: err,
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Test metadata updated. Files uploading in background if replaced.')));
        Navigator.pop(context, true);
      }
    } catch (e) {
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
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Edit Mock Test'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
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
                            value: _categories.contains(_selectedCategory)
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
                                  if (_isOtherCategory)
                                    _customCategoryController.clear();
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
                            value: _languages.contains(_selectedLanguage)
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
                            activeColor: colorScheme.primary,
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
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: AppSpacing.sm),
                          _buildFilePicker(
                            context,
                            icon: Icons.image_outlined,
                            title: _coverImage?.name ??
                                'Current: ${extractFilename(widget.test.coverImagePath)}',
                            onPick: _pickCoverImage,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _buildFilePicker(
                            context,
                            icon: Icons.table_chart_outlined,
                            title: _questionsFile?.name ??
                                'Current Questions File',
                            onPick: _pickQuestionsFile,
                            onDownload: _downloadCurrentJson,
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
                              child: const Text('UPDATE MOCK TEST',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
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
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        leading: Icon(icon, color: colorScheme.primary),
        title: Text(title,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onDownload != null)
              IconButton(
                onPressed: onDownload,
                icon: Icon(Icons.download_rounded,
                    color: colorScheme.primary, size: 20),
                tooltip: 'Download Original JSON',
              ),
            TextButton(onPressed: onPick, child: const Text('Replace')),
          ],
        ),
      ),
    );
  }
}
