import 'package:flutter/material.dart';
import '../../../../data/services/admin_service.dart';
import '../../../../data/services/resource_service.dart';
import '../../../../domain/models/resource.dart';
import '../../../../core/theme/app_colors.dart';
import 'dart:io';
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/foundation.dart'; // For consolidateHttpClientResponseBytes
import 'package:path_provider/path_provider.dart';
import '../../pdf_viewer_screen.dart';
import 'admin_resource_form.dart';

class AdminResourceList extends StatefulWidget {
  final ResourceType type;

  const AdminResourceList({super.key, required this.type});

  @override
  State<AdminResourceList> createState() => _AdminResourceListState();
}

class _AdminResourceListState extends State<AdminResourceList> {
  final ResourceService _resourceService = ResourceService();
  late Future<List<Resource>> _futureResources;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _futureResources =
        _resourceService.fetchResources(type: widget.type, isAdmin: true);
  }

  Future<void> _refresh() async {
    setState(() {
      _loadData();
    });
  }

  Future<void> _deleteResource(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
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
        await _resourceService.deleteResource(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Item deleted successfully')));
          _refresh();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _navigateToForm([Resource? resource]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminResourceForm(
          type: widget.type,
          resource: resource,
        ),
      ),
    );

    if (result == true) {
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Resource>>(
          future: _futureResources,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No items found. Add one!'));
            }

            final items = snapshot.data!;
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    onTap: () => _showItemStats(item),
                    leading: item.thumbnailUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item.thumbnailUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image_not_supported),
                            ),
                          )
                        : const Icon(Icons.insert_drive_file,
                            size: 40, color: AppColors.neutral400),
                    title: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.category != null)
                          Text(
                            item.category!,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        Text(
                          item.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: item.isActive ? Colors.green : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.fileUrl != null &&
                            item.fileUrl!.endsWith('.pdf'))
                          IconButton(
                            icon: const Icon(Icons.visibility,
                                color: Colors.teal),
                            tooltip: 'View PDF',
                            onPressed: () =>
                                _viewPdf(item.fileUrl!, item.title),
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _navigateToForm(item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteResource(item.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showItemStats(Resource item) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final stats = await AdminService.getResourceItemStats(item.id);

    if (context.mounted) {
      Navigator.pop(context); // Close loader
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${item.title} Stats'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatRow('Current Price', '₹${stats['price']}'),
              const Divider(),
              _buildStatRow('Total Sold', '${stats['salesCount']} Units'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blue)),
        ],
      ),
    );
  }

  Future<void> _viewPdf(String url, String title) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      // Download file to temp
      final HttpClient httpClient = HttpClient();
      final HttpClientRequest request = await httpClient.getUrl(Uri.parse(url));
      final HttpClientResponse response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Failed to download: HTTP ${response.statusCode}');
      }

      final Uint8List bytes =
          await consolidateHttpClientResponseBytes(response);

      final dir = await getTemporaryDirectory();
      final file =
          File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);

      if (mounted) {
        Navigator.pop(context); // Close loader
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewerScreen(file: file, title: title),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening PDF: $e')),
        );
      }
    }
  }
}
