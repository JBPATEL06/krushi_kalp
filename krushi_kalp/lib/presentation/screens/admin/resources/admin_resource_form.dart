import 'package:file_picker/file_picker.dart';
import 'package:krushi_kalp/utils/responsive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../data/services/resource_service.dart';
import '../../../../domain/models/resource.dart';
import '../../../utils/ui_helpers.dart';
import 'package:krushi_kalp/core/theme/app_spacing.dart';
import '../../../../utils/supabase_url_helper.dart';
import '../../../../data/services/upload_queue_service.dart';
import '../../../../utils/error_utils.dart';
import '../../../../utils/crashlytics_service.dart';
import '../../../utils/picker_lifecycle_mixin.dart';

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

class _AdminResourceFormState extends State<AdminResourceForm> with PickerLifecycleMixin {
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();
  late final ResourceService _resourceService;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  late TextEditingController _priceController;

  bool _isActive = false;

  String? _fileName;
  Uint8List? _fileBytes;
  String? _filePath;
  String? _existingFileUrl;

  String? _coverName;
  Uint8List? _coverBytes;
  String? _coverPath;
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
    final result = await safePickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      final platformFile = result.files.first;
      setState(() {
        _fileBytes = null; // always null on Android (withData: false)
        _filePath = platformFile.path;
        _fileName = platformFile.name;
      });
    }
  }

  Future<void> _pickCover() async {
    final result = await safePickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
    if (result != null && result.files.isNotEmpty) {
      final platformFile = result.files.first;
      if (platformFile.size > 50 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cover image must be under 50MB')),
          );
        }
        return;
      }
      setState(() {
        _coverBytes = null; // always null on Android (withData: false)
        _coverPath = platformFile.path;
        _coverName = platformFile.name;
      });
    }
  }

  /// Handles the saving logic with proper awaits and loading states.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.resource == null && _filePath == null) {
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

      final typeStrRaw = widget.type == ResourceType.eBook
          ? 'ebook'
          : widget.type == ResourceType.currentAffair
              ? 'current_affair'
              : widget.type == ResourceType.studyMaterial
                  ? 'study_material'
                  : 'pyq';

      // 1. Save to Database First to get ID / Confirm record
      final metadata = Resource(
        id: existingId ?? 0,
        title: title,
        description: description,
        type: widget.type,
        category: category,
        fileUrl: _existingFileUrl ?? '',
        thumbnailUrl: _existingCoverUrl ?? '',
        price: price,
        isActive: active,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

      final int resourceId;
      if (existingId == null) {
        resourceId = await _resourceService.createResource(metadata);
      } else {
        await _resourceService.updateResource(existingId, metadata.toJson());
        resourceId = existingId;
      }

      // 2. Start Background Uploads (Non-blocking)

      if (_filePath != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final cleanName = _fileName!.replaceAll(RegExp(r'[^\w\.-]'), '_');
        final path = 'Resources/$typeStrRaw/file/${timestamp}_$cleanName';

        UploadQueueService().enqueue(QueuedUploadRequest(
          taskId: 'resource_file_$resourceId',
          fileName: 'File: $title',
          itemName: 'Resource PDF',
          bucketName: 'mock_test',
          storagePath: path,
          fileBytes: _fileBytes,
          filePath: _filePath,
          fileType: 'resource_pdf',
          dbUpdate: {
            'table': 'resources',
            'idColumn': 'id',
            'idValue': resourceId,
            'updateColumn': 'file_url',
          },
          onProgress: (p) {},
          onComplete: (completedPath) async {
            if (existingId != null && _existingFileUrl != null) {
              await _resourceService.deleteFileFromStorage(_existingFileUrl!).catchError((_) => null);
            }
          },
          onError: (err) {},
        ));
      }

      if (_coverPath != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final cleanCover = _coverName!.replaceAll(RegExp(r'[^\w\.-]'), '_');
        final path = 'Resources/$typeStrRaw/cover/${timestamp}_$cleanCover';

        UploadQueueService().enqueue(QueuedUploadRequest(
          taskId: 'resource_cover_$resourceId',
          fileName: 'Cover: $title',
          itemName: 'Resource Thumbnail',
          bucketName: 'mock_test',
          storagePath: path,
          fileBytes: _coverBytes,
          filePath: _coverPath,
          fileType: 'resource_cover',
          dbUpdate: {
            'table': 'resources',
            'idColumn': 'id',
            'idValue': resourceId,
            'updateColumn': 'thumbnail_url',
          },
          onProgress: (p) {},
          onComplete: (completedPath) async {
            if (existingId != null && _existingCoverUrl != null) {
              await _resourceService.deleteFileFromStorage(_existingCoverUrl!).catchError((_) => null);
            }
          },
          onError: (err) {},
        ));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resource saved. You can safely leave the app in the background; files will continue uploading.'),
            duration: Duration(seconds: 4),
          ),
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
                subtitle: "Max size: 1MB",
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
                                  snapshot.data!.startsWith('http')) {
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
    String? subtitle,
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
        subtitle: subtitle != null 
            ? Text(subtitle, style: theme.textTheme.labelSmall)
            : null,
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
