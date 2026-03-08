import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../data/services/resource_service.dart';
import '../../../../data/services/admin_notification_service.dart';
import '../../../../domain/models/resource.dart';
import '../../../utils/ui_helpers.dart';
import 'package:krushi_kalp/core/theme/app_spacing.dart';
import '../../../../utils/supabase_url_helper.dart';

class AdminResourceForm extends StatefulWidget {
  final ResourceType type;
  final Resource? resource;

  const AdminResourceForm({super.key, required this.type, this.resource});

  @override
  State<AdminResourceForm> createState() => _AdminResourceFormState();
}

class _AdminResourceFormState extends State<AdminResourceForm> {
  final _formKey = GlobalKey<FormState>();
  final _resourceService = ResourceService.instance;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  late TextEditingController _priceController;

  bool _isActive = true;
  bool _isLoading = false;

  String? _fileName;
  Uint8List? _fileBytes;
  String? _existingFileUrl;

  String? _coverName;
  Uint8List? _coverBytes;
  String? _existingCoverUrl;

  @override
  void initState() {
    super.initState();
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
    } catch (e) {
      debugPrint('Error picking file: $e');
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
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.resource == null && _fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please attach a PDF file')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? fileUrl = _existingFileUrl;
      String? coverUrl = _existingCoverUrl;

      final typeStr = widget.type == ResourceType.eBook
          ? 'ebook'
          : widget.type == ResourceType.currentAffair
              ? 'current_affair'
              : widget.type == ResourceType.studyMaterial
                  ? 'study_material'
                  : 'pyq';

      if (_fileBytes != null) {
        final cleanName = _fileName!.replaceAll(' ', '_');
        final path =
            'Resources/$typeStr/file/${DateTime.now().millisecondsSinceEpoch}_$cleanName';
        fileUrl = await _resourceService.uploadFile(
            path: path, fileBytes: _fileBytes!);

        // Cleanup old file if editing
        if (widget.resource != null && _existingFileUrl != null) {
          await _resourceService.deleteFileFromStorage(_existingFileUrl!);
        }
      }

      if (_coverBytes != null) {
        final cleanCover = _coverName!.replaceAll(' ', '_');
        final path =
            'Resources/$typeStr/cover/${DateTime.now().millisecondsSinceEpoch}_$cleanCover';
        coverUrl = await _resourceService.uploadFile(
            path: path, fileBytes: _coverBytes!);

        // Cleanup old cover if editing
        if (widget.resource != null && _existingCoverUrl != null) {
          await _resourceService.deleteFileFromStorage(_existingCoverUrl!);
        }
      }

      final newItem = Resource(
        id: widget.resource?.id ?? 0,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: widget.type,
        category: _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        fileUrl: fileUrl,
        thumbnailUrl: coverUrl,
        price: double.tryParse(_priceController.text) ?? 0.0,
        isActive: _isActive,
        createdAt: widget.resource?.createdAt ?? DateTime.now(),
      );

      if (widget.resource == null) {
        await _resourceService.createResource(newItem);
        if (_isActive) {
          try {
            final notificationService = AdminNotificationService();
            await notificationService.sendBroadcast(
              title: "New Study Material Added!",
              body: "Check out the newly added resource: ${newItem.title}",
            );
          } catch (e) {
            debugPrint('Error sending automatic notification: $e');
          }
        }
      } else {
        await _resourceService.updateResource(newItem.id, newItem.toJson());
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Saved successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error saving: $e')));
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
        title: Text(widget.resource == null ? 'Add Resource' : 'Edit Resource'),
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
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category (Optional)',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionHeader(context, "PRICING"),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (0 for Free)',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final price = double.tryParse(v);
                  if (price == null) return 'Invalid Number';
                  if (price < 0) return 'Price cannot be negative';
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
                            future: SupabaseUrlHelper.getFreshSignedUrl(
                              bucketName: 'mock_test',
                              storagePath: _existingCoverUrl!,
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
                title: const Text('Visible to Users'),
                subtitle: Text('Hidden items won\'t appear in the app',
                    style: theme.textTheme.bodySmall),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _save,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: const Text('SAVE RESOURCE'),
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
        ),
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
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: (iconColor ?? colorScheme.primary).withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: thumbnail != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8), child: thumbnail)
              : Icon(icon, color: iconColor ?? colorScheme.primary),
        ),
        title: Text(
          title,
          style:
              theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: FilledButton.tonal(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            minimumSize: const Size(0, 36),
          ),
          child: const Text("Change"),
        ),
      ),
    );
  }
}
