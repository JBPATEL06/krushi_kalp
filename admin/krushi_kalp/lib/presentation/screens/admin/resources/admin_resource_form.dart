import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../data/services/resource_service.dart';
import '../../../../data/services/admin_notification_service.dart';
import '../../../../domain/models/resource.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../utils/ui_helpers.dart';

class AdminResourceForm extends StatefulWidget {
  final ResourceType type;
  final Resource? resource;

  const AdminResourceForm({super.key, required this.type, this.resource});

  @override
  State<AdminResourceForm> createState() => _AdminResourceFormState();
}

class _AdminResourceFormState extends State<AdminResourceForm> {
  final _formKey = GlobalKey<FormState>();
  final _resourceService = ResourceService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController; // New category field
  late TextEditingController _priceController;

  bool _isActive = true;
  bool _isLoading = false;

  // File handling
  String? _fileName;
  Uint8List? _fileBytes;
  String? _existingFileUrl;

  // Cover Image handling
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

    // Validate File Requirement:
    // If it's a new entry, we MUST have a file (for current affairs/material).
    // Unless it's just a metadata entry, but usually a "Resource" implies a file.
    if (widget.resource == null && _fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please attach a PDF file')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? fileUrl = _existingFileUrl;
      String? coverUrl = _existingCoverUrl;

      // Upload File if new
      if (_fileBytes != null) {
        final cleanName = _fileName!.replaceAll(' ', '_'); // Sanitize
        final path =
            'files/${DateTime.now().millisecondsSinceEpoch}_$cleanName';
        fileUrl = await _resourceService.uploadFile(
            path: path, fileBytes: _fileBytes!);
      }

      // Upload Cover if new
      if (_coverBytes != null) {
        final cleanCover = _coverName!.replaceAll(' ', '_'); // Sanitize
        final path =
            'covers/${DateTime.now().millisecondsSinceEpoch}_$cleanCover';
        coverUrl = await _resourceService.uploadFile(
            path: path, fileBytes: _coverBytes!);
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

        // --- Automatically send broadcast notification if resource is Active ---
        if (_isActive) {
          try {
            final notificationService = AdminNotificationService();
            await notificationService.sendBroadcast(
              title: "New Study Material Added!",
              body: "Check out the newly added resource: ${newItem.title}",
            );
          } catch (e) {
            debugPrint('Error sending automatic notification: $e');
            // We do not want to fail the resource creation if the notification fails
          }
        }
        // -----------------------------------------------------------------------
      } else {
        await _resourceService.updateResource(newItem.id, newItem.toJson());
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showExtendedFields = widget.type == ResourceType.studyMaterial ||
        widget.type == ResourceType.eBook ||
        widget.type == ResourceType.pyq ||
        widget.type == ResourceType.currentAffair; // Added Current Affairs

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.resource == null ? 'Add Resource' : 'Edit Resource'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryController,
              decoration:
                  const InputDecoration(labelText: 'Category (Optional)'),
            ),

            // Study Material / eBook / PYQ Specific Fields
            if (showExtendedFields) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration:
                    const InputDecoration(labelText: 'Price (0 for Free)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final price = double.tryParse(v);
                  if (price == null) return 'Invalid Number';
                  if (price < 0) return 'Price cannot be negative';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Cover Image',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: (_coverBytes != null)
                    ? Image.memory(_coverBytes!,
                        width: 50, height: 50, fit: BoxFit.cover)
                    : (_existingCoverUrl != null)
                        ? Image.network(_existingCoverUrl!,
                            width: 50, height: 50, fit: BoxFit.cover)
                        : const Icon(Icons.image, size: 40),
                title: Text(_coverName ?? extractFilename(_existingCoverUrl)),
                trailing: TextButton(
                    onPressed: _pickCover, child: const Text('Pick Image')),
              ),
            ],

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            // Common File Upload
            const Text('Attachment (PDF)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  const Icon(Icons.picture_as_pdf, color: Colors.deepOrange),
              title: Text(_fileName ?? extractFilename(_existingFileUrl)),
              trailing: TextButton(
                  onPressed: _pickFile, child: const Text('Pick PDF')),
            ),

            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Is Active'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),

            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Resource'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
