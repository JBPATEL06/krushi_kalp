import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/excel_to_json_converter.dart';
import '../utils/ui_helpers.dart';
import '../../data/services/test_service.dart';
import '../../data/services/admin_notification_service.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

class MockTestUploadScreen extends StatefulWidget {
  const MockTestUploadScreen({super.key});

  @override
  State<MockTestUploadScreen> createState() => _MockTestUploadScreenState();
}

class _MockTestUploadScreenState extends State<MockTestUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

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
    final cats = await TestService.fetchCategories();
    final langs = await TestService.fetchLanguages();
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
              const SnackBar(content: Text('Image must be less than 200KB')));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select both Cover Image and Excel File')));
      return;
    }

    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;

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

      final response = await supabase
          .from('mock_tests')
          .insert(insertData)
          .select('test_id')
          .single();
      final int testId = response['test_id'];

      const imagePath = 'mock_test_cover/';
      final fullPath = '$imagePath$testId.jpg';

      if (_imageBytes != null) {
        await supabase.storage.from('mock_test').uploadBinary(
              fullPath,
              _imageBytes!,
              fileOptions:
                  const FileOptions(upsert: true, contentType: 'image/jpeg'),
            );
      }

      final jsonList = ExcelToJsonConverter.convert(_excelBytes!);
      final jsonString = jsonEncode(jsonList);
      final jsonBytes = utf8.encode(jsonString);
      final jsonPath = 'mock_test_json_file/$testId.json';

      await supabase.storage.from('mock_test').uploadBinary(
            jsonPath,
            jsonBytes,
            fileOptions: const FileOptions(
                upsert: true, contentType: 'application/json'),
          );

      await supabase.from('mock_tests').update({
        'file_path': jsonPath,
        'cover_image_path': fullPath,
      }).eq('test_id', testId);

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
            const SnackBar(content: Text('Mock Test Uploaded Successfully!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
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
        title: const Text('Upload Mock Test'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
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
                          _buildSectionTitle(context, 'Basic Info'),
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
                            value: _selectedCategory,
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
                                  prefixIcon: const Icon(Icons.edit_rounded)),
                              validator: (v) =>
                                  _isOtherCategory && (v == null || v.isEmpty)
                                      ? 'Required'
                                      : null,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          DropdownButtonFormField<String>(
                            value: _selectedLanguage,
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
                          _buildSectionTitle(context, 'Assessment Rules'),
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
                                    style: theme.textTheme.bodyLarge,
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
                                        prefixIcon:
                                            const Icon(Icons.timer_outlined)),
                                    style: theme.textTheme.bodyLarge,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            TextFormField(
                              controller: _priceController,
                              decoration: getPremiumInputDecoration(context,
                                  labelText: 'Price',
                                  prefixIcon:
                                      const Icon(Icons.attach_money_rounded)),
                              style: theme.textTheme.bodyLarge,
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            TextFormField(
                              controller: _durationController,
                              decoration: getPremiumInputDecoration(context,
                                  labelText: 'Duration (mins)',
                                  prefixIcon: const Icon(Icons.timer_outlined)),
                              style: theme.textTheme.bodyLarge,
                              keyboardType: TextInputType.number,
                            ),
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
                                        prefixIcon:
                                            const Icon(Icons.quiz_outlined)),
                                    style: theme.textTheme.bodyLarge,
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
                                        prefixIcon:
                                            const Icon(Icons.grade_outlined)),
                                    style: theme.textTheme.bodyLarge,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            TextFormField(
                              controller: _totalQuestionsController,
                              decoration: getPremiumInputDecoration(context,
                                  labelText: 'Total Questions',
                                  prefixIcon: const Icon(Icons.quiz_outlined)),
                              style: theme.textTheme.bodyLarge,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            TextFormField(
                              controller: _totalMarksController,
                              decoration: getPremiumInputDecoration(context,
                                  labelText: 'Total Marks',
                                  prefixIcon: const Icon(Icons.grade_outlined)),
                              style: theme.textTheme.bodyLarge,
                              keyboardType: TextInputType.number,
                            ),
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
                          if (_isNegativeMarking)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: AppSpacing.md),
                              child: TextFormField(
                                controller: _negativeMarksController,
                                decoration: getPremiumInputDecoration(context,
                                    labelText:
                                        'Negative Marks per Wrong Answer',
                                    prefixIcon: const Icon(
                                        Icons.remove_circle_outline_rounded)),
                                style: theme.textTheme.bodyLarge,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          const SizedBox(height: AppSpacing.xl),
                          _buildSectionTitle(context, 'Resources'),
                          const SizedBox(height: AppSpacing.sm),
                          _buildFileTile(
                            context,
                            icon: Icons.image_outlined,
                            title: _coverImage?.name ?? 'Select Cover Image',
                            subtitle: 'Recommended: 1200x630 (Max 200KB)',
                            onTap: _pickCoverImage,
                            isSelected: _coverImage != null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildFileTile(
                            context,
                            icon: Icons.table_chart_outlined,
                            title: _excelFile?.name ??
                                'Select Questions File (.xlsx)',
                            subtitle: 'Excel format required',
                            onTap: _pickExcelFile,
                            isSelected: _excelFile != null,
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _uploadMockTest,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md)),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2)
                                  : const Text('UPLOAD ASSESSMENT',
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
      ),
    );
  }

  Widget _buildFileTile(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
      required bool isSelected}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withOpacity(0.2),
              width: isSelected ? 2 : 1),
          color: isSelected
              ? colorScheme.primary.withOpacity(0.05)
              : colorScheme.surface,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface)),
                  Text(subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.add_circle_outline_rounded,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}
