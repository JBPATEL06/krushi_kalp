import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../utils/excel_to_json_converter.dart';
import '../utils/ui_helpers.dart';
import '../../data/services/test_service.dart';
import '../../data/services/admin_notification_service.dart';
import '../../core/theme/app_spacing.dart';

class MockTestUploadScreen extends StatefulWidget {
  const MockTestUploadScreen({super.key});

  @override
  State<MockTestUploadScreen> createState() => _MockTestUploadScreenState();
}

class _MockTestUploadScreenState extends State<MockTestUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form Fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _totalQuestionsController = TextEditingController();
  final _totalMarksController = TextEditingController();
  final _negativeMarksController = TextEditingController();
  final _customCategoryController = TextEditingController();
  List<String> _categories = ['Other'];
  List<String> _languages = ['English', 'Gujarati'];
  String _selectedCategory = 'Other';
  String _selectedLanguage = 'English';
  bool _isOtherCategory = false;
  bool _isNegativeMarking = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await TestService.instance.fetchCategories();
    final langs = await TestService.instance.fetchLanguages();
    if (mounted) {
      setState(() {
        _categories = cats;
        _languages = langs;
        if (!_categories.contains('Other')) _categories.add('Other');
        if (!_categories.contains(_selectedCategory)) {
          _selectedCategory =
              _categories.isNotEmpty ? _categories.first : 'Other';
        }
        if (!_languages.contains(_selectedLanguage)) {
          _selectedLanguage =
              _languages.isNotEmpty ? _languages.first : 'English';
        }
      });
    }
  }

  // Files
  PlatformFile? _coverImage;
  PlatformFile? _excelFile;
  Uint8List? _excelBytes;
  Uint8List? _imageBytes;

  static const int maxImageSizeBytes = 200 * 1024; // 200KB

  Future<void> _pickCoverImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null) {
      final file = result.files.first;
      if (file.size > maxImageSizeBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image must be less than 200KB')),
          );
        }
        return;
      }
      setState(() {
        _coverImage = file;
        _imageBytes = file.bytes;
      });
    }
  }

  Future<void> _pickExcelFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );

    if (result != null) {
      final file = result.files.first;
      setState(() {
        _excelFile = file;
        _excelBytes = file.bytes;
      });
    }
  }

  Future<void> _uploadMockTest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_coverImage == null || _excelFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both Cover Image and Excel File'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final theme = Theme.of(context);
    try {
      final insertData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _isOtherCategory
            ? _customCategoryController.text.trim()
            : _selectedCategory,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'duration_minutes': int.tryParse(_durationController.text) ?? 60,
        'total_questions': int.tryParse(_totalQuestionsController.text) ?? 0,
        'total_marks': int.tryParse(_totalMarksController.text) ?? 100,
        'negative_marking': _isNegativeMarking,
        'negative_marks_per_q':
            double.tryParse(_negativeMarksController.text) ?? 0.0,
        'language': _selectedLanguage,
        'is_active': true,
        'file_path': '',
      };

      if (_excelBytes == null) throw 'Excel file not selected';

      final jsonList = ExcelToJsonConverter.convert(_excelBytes!);

      await TestService.instance.uploadMockTestWithFiles(
        insertData: insertData,
        imageBytes: _imageBytes!,
        jsonString: jsonEncode(jsonList),
      );

      try {
        await AdminNotificationService().sendBroadcast(
          title: 'New Mock Test Available!',
          body: 'Check out the new ${_titleController.text.trim()} test now!',
        );
      } catch (e) {
        debugPrint("Notification Error: $e");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mock Test Uploaded Successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: theme.colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Upload Mock Test',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      boxShadow: [
                        BoxShadow(
                          color:
                              theme.colorScheme.shadow.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(context, 'Basic Info'),
                          TextFormField(
                            controller: _titleController,
                            decoration: getPremiumInputDecoration(
                              context,
                              labelText: 'Title',
                              prefixIcon: const Icon(Icons.title),
                            ),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: getPremiumInputDecoration(
                              context,
                              labelText: 'Description',
                              prefixIcon: const Icon(Icons.description),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: getPremiumInputDecoration(context,
                                labelText: 'Category',
                                prefixIcon: const Icon(Icons.category)),
                            items: _categories
                                .map(
                                  (c) => DropdownMenuItem(
                                      value: c, child: Text(c)),
                                )
                                .toList(),
                            onChanged: (v) {
                              setState(() {
                                _selectedCategory = v!;
                                _isOtherCategory = v == 'Other';
                              });
                            },
                          ),
                          if (_isOtherCategory) ...[
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _customCategoryController,
                              decoration: getPremiumInputDecoration(context,
                                  labelText: 'Enter New Category',
                                  prefixIcon: const Icon(Icons.edit)),
                              validator: (v) =>
                                  _isOtherCategory && (v == null || v.isEmpty)
                                      ? 'Required'
                                      : null,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          DropdownButtonFormField<String>(
                            value: _selectedLanguage,
                            decoration: getPremiumInputDecoration(context,
                                labelText: 'Language',
                                prefixIcon: const Icon(Icons.language)),
                            items: _languages
                                .map(
                                  (c) => DropdownMenuItem(
                                      value: c, child: Text(c)),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedLanguage = v!),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _buildSectionTitle(context, 'Test Details'),
                          if (isWide)
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _priceController,
                                    decoration: getPremiumInputDecoration(
                                      context,
                                      labelText: 'Price',
                                      prefixIcon:
                                          const Icon(Icons.currency_rupee),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (v) =>
                                        v!.isEmpty ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: TextFormField(
                                    controller: _durationController,
                                    decoration: getPremiumInputDecoration(
                                      context,
                                      labelText: 'Duration (mins)',
                                      prefixIcon: const Icon(Icons.timer),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            TextFormField(
                              controller: _priceController,
                              decoration: getPremiumInputDecoration(
                                context,
                                labelText: 'Price',
                                prefixIcon: const Icon(Icons.currency_rupee),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _durationController,
                              decoration: getPremiumInputDecoration(
                                context,
                                labelText: 'Duration (mins)',
                                prefixIcon: const Icon(Icons.timer),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          if (isWide)
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _totalQuestionsController,
                                    decoration: getPremiumInputDecoration(
                                      context,
                                      labelText: 'Total Questions',
                                      prefixIcon: const Icon(Icons.quiz),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: TextFormField(
                                    controller: _totalMarksController,
                                    decoration: getPremiumInputDecoration(
                                      context,
                                      labelText: 'Total Marks',
                                      prefixIcon: const Icon(Icons.grade),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            TextFormField(
                              controller: _totalQuestionsController,
                              decoration: getPremiumInputDecoration(
                                context,
                                labelText: 'Total Questions',
                                prefixIcon: const Icon(Icons.quiz),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _totalMarksController,
                              decoration: getPremiumInputDecoration(
                                context,
                                labelText: 'Total Marks',
                                prefixIcon: const Icon(Icons.grade),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ],
                          SwitchListTile(
                            title: Text('Negative Marking',
                                style: Theme.of(context).textTheme.bodyLarge),
                            value: _isNegativeMarking,
                            onChanged: (v) =>
                                setState(() => _isNegativeMarking = v),
                            activeColor: theme.colorScheme.primary,
                          ),
                          if (_isNegativeMarking)
                            TextFormField(
                              controller: _negativeMarksController,
                              decoration: getPremiumInputDecoration(
                                context,
                                labelText:
                                    'Negative Marks per Wrong Answer (e.g. 0.25)',
                                prefixIcon:
                                    const Icon(Icons.remove_circle_outline),
                              ),
                              keyboardType: TextInputType.number,
                              initialValue: null,
                            ),
                          const SizedBox(height: AppSpacing.xl),
                          _buildSectionTitle(context, 'Files'),

                          // Cover Image Picker
                          ListTile(
                            leading: Icon(Icons.image,
                                color: theme.colorScheme.primary),
                            title: Text(
                                _coverImage?.name ?? 'Select Cover Image',
                                style: Theme.of(context).textTheme.bodyMedium),
                            subtitle: const Text('Max size: 200KB'),
                            trailing: IconButton(
                              icon: const Icon(Icons.upload_file),
                              onPressed: _pickCoverImage,
                              color: theme.colorScheme.primary,
                            ),
                            tileColor: _coverImage != null
                                ? theme.colorScheme.primaryContainer
                                    .withValues(alpha: 0.1)
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                              side: BorderSide(
                                  color: theme.colorScheme.outlineVariant),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Excel File Picker
                          ListTile(
                            leading: Icon(Icons.table_chart,
                                color: theme.colorScheme.primary),
                            title: Text(
                              _excelFile?.name ?? 'Select Excel File (.xlsx)',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            subtitle: const Text('Will be converted to JSON'),
                            trailing: IconButton(
                              icon: const Icon(Icons.upload_file),
                              onPressed: _pickExcelFile,
                              color: theme.colorScheme.primary,
                            ),
                            tileColor: _excelFile != null
                                ? theme.colorScheme.primaryContainer
                                    .withValues(alpha: 0.1)
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                              side: BorderSide(
                                  color: theme.colorScheme.outlineVariant),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.xxl),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _uploadMockTest,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd),
                                ),
                              ),
                              child: Text(
                                'UPLOAD MOCK TEST',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: theme.colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
