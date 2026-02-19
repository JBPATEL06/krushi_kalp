import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../utils/excel_to_json_converter.dart';
import '../../utils/ui_helpers.dart'; // NEW
import '../../../domain/models/mock_test.dart';
import '../../../data/services/test_service.dart';

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

  // Files (Optional for edit)
  PlatformFile? _coverImage;
  PlatformFile? _excelFile;
  Uint8List? _imageBytes;

  Uint8List? _excelBytes;

  final _customCategoryController = TextEditingController(); // NEW
  List<String> _categories = ['Other']; // Start with only Other
  List<String> _languages = ['English', 'Gujarati']; // UPDATED
  bool _isOtherCategory = false; // NEW

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

    _loadCategoriesAndTestDetails(); // UPDATED
  }

  void _loadCategoriesAndTestDetails() async {
    // 1. Fetch Categories & Languages
    final cats = await TestService.fetchCategories();
    final langs = await TestService.fetchLanguages(); // NEW

    // 2. Fetch Latest Test Details (Optional but requested)
    final freshTest = await TestService.fetchMockTestById(widget.test.id);
    final t = freshTest ?? widget.test;

    if (mounted) {
      setState(() {
        // Update Controllers with fresh data
        _titleController.text = t.title;
        _descriptionController.text = t.description;
        _priceController.text = t.price.toString();
        _durationController.text = t.durationMinutes?.toString() ?? '';
        _totalQuestionsController.text = t.totalQuestions.toString();
        _totalMarksController.text = t.totalMarks.toString();
        _negativeMarksController.text = t.negativeMarksPerQ.toString();
        _isNegativeMarking = t.negativeMarking;
        _selectedLanguage = t.language;
        // Ensure language is valid dropdown option
        if (!['English', 'Hindi', 'Gujarati'].contains(_selectedLanguage)) {
          _selectedLanguage = 'English';
        }

        // Category Logic
        _categories = cats;
        _selectedCategory = t.category;

        if (!_categories.contains(_selectedCategory) &&
            _selectedCategory.isNotEmpty) {
          // It's a custom category
          _isOtherCategory = true;
          _customCategoryController.text = _selectedCategory;
          _categories.add('Other'); // Ensure 'Other' is present
          _selectedCategory = 'Other'; // Select 'Other' in dropdown
        } else {
          _isOtherCategory = false;
          if (!_categories.contains('Other')) _categories.add('Other');
        }

        // Language Logic
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
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image too large (>200KB)')));
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
            : _selectedCategory, // UPDATED
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'duration_minutes': int.tryParse(_durationController.text),
        'total_questions': int.tryParse(_totalQuestionsController.text) ?? 0,
        'total_marks': int.tryParse(_totalMarksController.text) ?? 0,
        'negative_marking': _isNegativeMarking,
        'negative_marks_per_q':
            double.tryParse(_negativeMarksController.text) ?? 0.0,
        'language': _selectedLanguage,
      };

      // 1. Update cover image if changed
      if (_coverImage != null && _imageBytes != null) {
        final imagePath = 'mock_test_cover/${widget.test.id}.jpg';
        await supabase.storage.from('mock_test').uploadBinary(
              imagePath,
              _imageBytes!,
              fileOptions:
                  const FileOptions(upsert: true, contentType: 'image/jpeg'),
            );
        // No need to update 'cover_image_path' column if keeping same naming convention,
        // but if the original path was different, we should update it.
        // Let's safe update it.
        updates['cover_image_path'] = imagePath;
      }

      // 2. Update Excel/JSON if changed
      if (_excelFile != null && _excelBytes != null) {
        final jsonList = ExcelToJsonConverter.convert(_excelBytes!);
        final jsonString = jsonEncode(jsonList);
        final jsonBytes = utf8.encode(jsonString);
        final jsonPath = 'mock_test_json_file/${widget.test.id}.json';

        await supabase.storage.from('mock_test').uploadBinary(
              jsonPath,
              jsonBytes,
              fileOptions: const FileOptions(
                  upsert: true, contentType: 'application/json'),
            );
        updates['file_path'] = jsonPath;
      }

      // 3. Update DB Row
      await TestService.updateMockTest(widget.test.id, updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test Updated Successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
// ...

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Edit Mock Test'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
            color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
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
                            decoration: getPremiumInputDecoration(
                              context,
                              labelText: 'Title',
                              prefixIcon: const Icon(Icons.title),
                            ),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: getPremiumInputDecoration(
                              context,
                              labelText: 'Description',
                              prefixIcon: const Icon(Icons.description),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _categories.contains(_selectedCategory)
                                ? _selectedCategory
                                : null,
                            decoration: getPremiumInputDecoration(
                              context,
                              labelText: 'Category',
                              prefixIcon: const Icon(Icons.category),
                            ),
                            dropdownColor: Colors.white,
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
                            validator: (v) =>
                                (v == null || v.isEmpty) && !_isOtherCategory
                                    ? 'Required'
                                    : null,
                          ),
                          if (_isOtherCategory) ...[
                            const SizedBox(height: 10),
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
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _languages.contains(_selectedLanguage)
                                ? _selectedLanguage
                                : null,
                            decoration: getPremiumInputDecoration(
                              context,
                              labelText: 'Language',
                              prefixIcon: const Icon(Icons.language),
                            ),
                            items: _languages
                                .map((c) =>
                                    DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedLanguage = v!),
                          ),
                          const SizedBox(height: 20),
                          const SizedBox(height: 20),
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
                                        keyboardType: TextInputType.number)),
                                const SizedBox(width: 16),
                                Expanded(
                                    child: TextFormField(
                                        controller: _durationController,
                                        decoration: getPremiumInputDecoration(
                                          context,
                                          labelText: 'Minutes',
                                          prefixIcon: const Icon(Icons.timer),
                                        ),
                                        keyboardType: TextInputType.number)),
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
                                keyboardType: TextInputType.number),
                            const SizedBox(height: 16),
                            TextFormField(
                                controller: _durationController,
                                decoration: getPremiumInputDecoration(
                                  context,
                                  labelText: 'Minutes',
                                  prefixIcon: const Icon(Icons.timer),
                                ),
                                keyboardType: TextInputType.number),
                          ],
                          const SizedBox(height: 16),
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
                                        keyboardType: TextInputType.number)),
                                const SizedBox(width: 16),
                                Expanded(
                                    child: TextFormField(
                                        controller: _totalMarksController,
                                        decoration: getPremiumInputDecoration(
                                          context,
                                          labelText: 'Total Marks',
                                          prefixIcon: const Icon(Icons.grade),
                                        ),
                                        keyboardType: TextInputType.number)),
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
                                keyboardType: TextInputType.number),
                            const SizedBox(height: 16),
                            TextFormField(
                                controller: _totalMarksController,
                                decoration: getPremiumInputDecoration(
                                  context,
                                  labelText: 'Total Marks',
                                  prefixIcon: const Icon(Icons.grade),
                                ),
                                keyboardType: TextInputType.number),
                          ],
                          SwitchListTile(
                            title: const Text('Negative Marking'),
                            value: _isNegativeMarking,
                            onChanged: (v) =>
                                setState(() => _isNegativeMarking = v),
                          ),
                          if (_isNegativeMarking) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _negativeMarksController,
                              decoration: getPremiumInputDecoration(
                                context,
                                labelText: 'Negative Marks per Q',
                                prefixIcon:
                                    const Icon(Icons.remove_circle_outline),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ],
                          const SizedBox(height: 20),
                          const Text('Files (Select new to replace)',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          ListTile(
                            leading: const Icon(Icons.image),
                            title: Text(_coverImage?.name ??
                                'Current: ${extractFilename(widget.test.coverImagePath)}'),
                            trailing: IconButton(
                                icon: const Icon(Icons.upload),
                                onPressed: _pickCoverImage),
                          ),
                          ListTile(
                            leading: const Icon(Icons.table_chart),
                            title: Text(
                                _excelFile?.name ?? 'Current Questions File'),
                            trailing: IconButton(
                                icon: const Icon(Icons.upload),
                                onPressed: _pickExcelFile),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _updateMockTest,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white),
                              child: const Text('UPDATE MOCK TEST'),
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
}
