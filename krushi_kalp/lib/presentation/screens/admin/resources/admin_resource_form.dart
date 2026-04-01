import 'package:file_picker/file_picker.dart';
import 'package:krushi_kalp/utils/responsive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../data/services/resource_service.dart';
import '../../../../domain/models/resource.dart';
import '../../../utils/ui_helpers.dart';
import 'package:krushi_kalp/core/theme/app_spacing.dart';
import '../../../../utils/supabase_url_helper.dart';
import '../../../../utils/error_utils.dart';
import '../../../../utils/crashlytics_service.dart';

class AdminResourceForm extends StatefulWidget {
  final ResourceType type;
  final Resource? resource;
  final ResourceService? resourceService;

  const AdminResourceForm({
    super.key,
    required this.type,
    this.resource,
    this.resourceService,
  });

  @override
  State<AdminResourceForm> createState() => _AdminResourceFormState();
}

class _AdminResourceFormState extends State<AdminResourceForm> {
  final _formKey = GlobalKey<FormState>();
  late final ResourceService _resourceService;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  late TextEditingController _priceController;

  bool _isActive = true;
  bool _isSaving = false;

  String? _fileName;
  Uint8List? _fileBytes;
  String? _existingFileUrl;

  String? _coverName;
  Uint8List? _coverBytes;
  String? _existingCoverUrl;

  @override
  void initState() {
    super.initState();
    _resourceService = widget.resourceService ?? ResourceService.instance;
    _titleController =
        TextEditingController(text: widget.resource?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.resource?.description ?? '');
    _categoryController =
        TextEditingController(text: widget.resource?.category ?? '');
    _priceController = TextEditingController(
        text: widget.resource?.price.toStringAsFixed(2) ?? '0.00');
    _isActive = widget.resource?.isActive ?? true;

    _existingFileUrl = widget.resource?.fileUrl;
    _existingCoverUrl = widget.resource?.thumbnailUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null) {
        setState(() {
          _fileBytes = result.files.first.bytes;
          _fileName = result.files.first.name;
        });
      }
    } catch (e, stack) {
      await CrashlyticsService.instance.recordError(e, stack, reason: 'Failed to pick file');
    }
  }

  Future<void> _pickCover() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null) {
        setState(() {
          _coverBytes = result.files.first.bytes;
          _coverName = result.files.first.name;
        });
      }
    } catch (e, stack) {
      await CrashlyticsService.instance.recordError(e, stack, reason: 'Failed to pick cover');
    }
  }

  /// Handles the saving logic with proper awaits and loading states.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.resource == null && _fileBytes == null) {
      ErrorUtils.showError(context, 'Please attach a PDF file');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final category = _categoryController.text.trim();
      final price = double.tryParse(_priceController.text) ?? 0.0;
      final active = _isActive;
      final createdAt = widget.resource?.createdAt ?? DateTime.now();
      final existingId = widget.resource?.id;

      String finalFileUrl = _existingFileUrl ?? '';
      String finalCoverUrl = _existingCoverUrl ?? '';

      final typeStr = widget.type == ResourceType.eBook
          ? 'ebook'
          : widget.type == ResourceType.currentAffair
              ? 'current_affair'
              : widget.type == ResourceType.studyMaterial
                  ? 'study_material'
                  : 'pyq';

      // 1. Handle PDF Upload (Sequential Await)
      if (_fileBytes != null) {
        final cleanName = _fileName!.replaceAll(' ', '_');
        final path = 'Resources/$typeStr/file/${DateTime.now().millisecondsSinceEpoch}_$cleanName';
        
        final uploadedPath = await _resourceService.uploadFile(
          path: path, 
          fileBytes: _fileBytes!,
          bucket: 'mock_test',
        );
        
        if (uploadedPath != null) {
          finalFileUrl = uploadedPath;
          if (widget.resource != null && _existingFileUrl != null) {
            await _resourceService.deleteFileFromStorage(_existingFileUrl!).catchError((_) => null);
          }
        }
      }

      // 2. Handle Cover Upload (Sequential Await)
      if (_coverBytes != null) {
        final cleanCover = _coverName!.replaceAll(' ', '_');
        final path = 'Resources/$typeStr/cover/${DateTime.now().millisecondsSinceEpoch}_$cleanCover';
        
        final uploadedPath = await _resourceService.uploadFile(
          path: path, 
          fileBytes: _coverBytes!,
          bucket: 'mock_test',
        );
        
        if (uploadedPath != null) {
          finalCoverUrl = uploadedPath;
          if (widget.resource != null && _existingCoverUrl != null) {
            await _resourceService.deleteFileFromStorage(_existingCoverUrl!).catchError((_) => null);
          }
        }
      }

      // 3. Save to Database
      final newItem = Resource(
        id: existingId ?? 0,
        title: title,
        description: description,
        type: widget.type,
        category: category,
        fileUrl: finalFileUrl,
        thumbnailUrl: finalCoverUrl,
        price: price,
        isActive: active,
        createdAt: createdAt,
      );

      if (existingId == null) {
        await _resourceService.createResource(newItem);
      } else {
        await _resourceService.updateResource(existingId, newItem.toJson());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(existingId == null ? 'Resource Created' : 'Resource Updated')),
        );
        Navigator.pop(context, true);
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'AdminResourceForm save failed');
      if (mounted) {
        ErrorUtils.showError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.resource == null ? 'Add Resource' : 'Edit Resource',
            style: TextStyle(fontSize: context.sp(20))), // FIXED
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(context, "GENERAL INFORMATION"),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(fontSize: context.sp(14)), // FIXED
                  prefixIcon:
                      Icon(Icons.title_rounded, size: context.sp(20)), // FIXED
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(fontSize: context.sp(14)), // FIXED
                  prefixIcon: Icon(Icons.description_outlined,
                      size: context.sp(20)), // FIXED
                ),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: 'Category (Optional)',
                  labelStyle: TextStyle(fontSize: context.sp(14)), // FIXED
                  prefixIcon: Icon(Icons.category_outlined,
                      size: context.sp(20)), // FIXED
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionHeader(context, "PRICING"),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Price (0 for Free)',
                  labelStyle: TextStyle(fontSize: context.sp(14)), // FIXED
                  prefixIcon: Icon(Icons.currency_rupee_rounded,
                      size: context.sp(20)), // FIXED
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final p = double.tryParse(v);
                  if (p == null) return 'Invalid Number';
                  if (p < 0) return 'Price cannot be negative';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionHeader(context, "COVER IMAGE"),
              const SizedBox(height: AppSpacing.sm),
              _buildPickerTile(
                context,
                title: _coverName ?? extractFilename(_existingCoverUrl),
                icon: Icons.image_outlined,
                onPressed: _pickCover,
                thumbnail: (_coverBytes != null)
                    ? Image.memory(_coverBytes!, fit: BoxFit.cover)
                    : (_existingCoverUrl != null)
                        ? FutureBuilder<String>(
                            future: SupabaseUrlHelper().getFreshSignedUrl(
                              'mock_test',
                              _existingCoverUrl!,
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.hasData &&
                                  snapshot.data!.isNotEmpty) {
                                return Image.network(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image_outlined),
                                );
                              }
                              return const Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2));
                            },
                          )
                        : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionHeader(context, "ATTACHMENT"),
              const SizedBox(height: AppSpacing.sm),
              _buildPickerTile(
                context,
                title: _fileName ?? extractFilename(_existingFileUrl),
                icon: Icons.picture_as_pdf_outlined,
                onPressed: _pickFile,
                iconColor: colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionHeader(context, "VISIBILITY"),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Visible to Users',
                    style: TextStyle(fontSize: context.sp(16))), // FIXED
                subtitle: Text('Hidden items won\'t appear in the app',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontSize: context.sp(12))), // FIXED
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving 
                      ? const SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_isSaving ? 'SAVING...' : 'SAVE RESOURCE',
                      style: TextStyle(fontSize: context.sp(16))),
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
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: colorScheme.onSurfaceVariant,
        letterSpacing: 1.2,
        fontSize: context.sp(12), // FIXED
      ),
    );
  }

  Widget _buildPickerTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onPressed,
    Widget? thumbnail,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: context.sp(44), // FIXED
          height: context.sp(44), // FIXED
          decoration: BoxDecoration(
            color: (iconColor ?? colorScheme.primary).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: thumbnail != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8), child: thumbnail)
              : Icon(icon,
                  color: iconColor ?? colorScheme.primary,
                  size: context.sp(24)), // FIXED
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600, fontSize: context.sp(14)), // FIXED
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: FilledButton.tonal(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            minimumSize: const Size(0, 36),
          ),
          child: Text("Change",
              style: TextStyle(fontSize: context.sp(12))), // FIXED
        ),
      ),
    );
  }
}
