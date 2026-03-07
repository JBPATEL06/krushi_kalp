import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/resource.dart';

class ResourceService {
  // --- SINGLETON ---
  ResourceService._();
  static final ResourceService instance = ResourceService._();

  final SupabaseClient _client = Supabase.instance.client;

  // --- SIGNED URL CACHE ---
  final Map<String, _SignedUrlEntry> _urlCache = {};

  Future<String?> _getSignedUrlCached(String path, String bucket,
      {int ttlSeconds = 60 * 60 * 22}) async {
    final cached = _urlCache[path];
    if (cached != null && !cached.isExpired) return cached.url;

    try {
      final url = await _client.storage
          .from(bucket)
          .createSignedUrl(path, 60 * 60 * 24);
      _urlCache[path] = _SignedUrlEntry(
          url, DateTime.now().add(Duration(seconds: ttlSeconds)));
      return url;
    } catch (e) {
      return null;
    }
  }

  Future<List<Resource>> fetchResources({
    required ResourceType type,
    String? category,
    bool isAdmin = false,
  }) async {
    final typeStr = _typeToString(type);

    var query = _client.from('resources').select().eq('type', typeStr);

    if (!isAdmin) {
      query = query.eq('is_active', true);
    }

    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }

    final response = await query.order('created_at', ascending: false);
    final resources = await compute(_parseResources, response as List<dynamic>);
    return await _signResources(resources);
  }

  // Get a single resource
  Future<Resource?> getResourceById(int id) async {
    final response =
        await _client.from('resources').select().eq('id', id).maybeSingle();

    if (response == null) return null;
    return Resource.fromJson(response);
  }

  // Fetch purchased resources for a user
  Future<List<Resource>> fetchPurchasedResources(String userId) async {
    // 1. Get completed orders for user
    final response = await _client
        .from('orders')
        .select('order_id')
        .eq('user_id', userId)
        .inFilter('status', ['SUCCESS', 'COMPLETED']);

    if (response.isEmpty) return [];

    final orderIds = (response as List).map((e) => e['order_id']).toList();

    // 2. Get items for these orders that are resources
    final itemsRes = await _client
        .from('order_items')
        .select('resource_id, resources(*)') // Select resource_id explicitly
        .inFilter('order_id', orderIds)
        .not('resource_id', 'is', null);

    final resources = <Resource>[];
    final seenIds = <int>{};
    for (var item in itemsRes as List) {
      if (item['resources'] != null) {
        final r = Resource.fromJson(item['resources']);
        if (!seenIds.contains(r.id)) {
          resources.add(r);
          seenIds.add(r.id);
        }
      }
    }
    return await _signResources(resources);
  }

  // Helper to sign URLs
  Future<List<Resource>> _signResources(List<Resource> resources) async {
    return await Future.wait(resources.map((r) async {
      String? signedFile;
      String? signedThumb;
      const bucket = 'mock_test'; // Same bucket used for resources

      if (r.fileUrl != null && r.fileUrl!.isNotEmpty) {
        if (!r.fileUrl!.startsWith('http')) {
          final path = r.fileUrl!.replaceAll('$bucket/', '');
          signedFile = await _getSignedUrlCached(path, bucket);
        } else {
          signedFile = r.fileUrl;
        }
      }

      if (r.thumbnailUrl != null && r.thumbnailUrl!.isNotEmpty) {
        if (!r.thumbnailUrl!.startsWith('http')) {
          final path = r.thumbnailUrl!.replaceAll('$bucket/', '');
          signedThumb = await _getSignedUrlCached(path, bucket);
        } else {
          signedThumb = r.thumbnailUrl;
        }
      }

      return Resource(
        id: r.id,
        title: r.title,
        description: r.description,
        type: r.type,
        category: r.category,
        fileUrl: signedFile ?? r.fileUrl,
        thumbnailUrl: signedThumb ?? r.thumbnailUrl,
        price: r.price,
        mrp: r.mrp,
        discount: r.discount,
        isActive: r.isActive,
        createdAt: r.createdAt,
      );
    }));
  }

  // Admin: Create Resource
  Future<void> createResource(Resource resource) async {
    try {
      await _client.from('resources').insert(resource.toJson());
    } catch (e) {
      throw Exception('Failed to create resource: $e');
    }
  }

  // Admin: Update Resource
  Future<void> updateResource(int id, Map<String, dynamic> updates) async {
    try {
      await _client.from('resources').update(updates).eq('id', id);
    } catch (e) {
      throw Exception('Failed to update resource: $e');
    }
  }

  // Admin: Delete Resource
  Future<void> deleteResource(int id) async {
    try {
      // 1. Fetch resource details to get file paths
      final resource = await getResourceById(id);

      if (resource != null) {
        // 2. Delete files from storage (best effort)
        if (resource.fileUrl != null) {
          await deleteFileFromStorage(resource.fileUrl!);
        }
        if (resource.thumbnailUrl != null) {
          await deleteFileFromStorage(resource.thumbnailUrl!);
        }
      }

      // 3. Delete database row
      await _client.from('resources').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete resource: $e');
    }
  }

  /// Public helper to delete a file from Supabase storage given its URL or path
  Future<void> deleteFileFromStorage(String fileUrlOrPath) async {
    try {
      const bucket = 'mock_test';
      String path = fileUrlOrPath;

      // Extract relative path from URL
      if (fileUrlOrPath.contains('/storage/v1/object/')) {
        final uri = Uri.parse(fileUrlOrPath);
        final segments = uri.pathSegments;

        // Find bucket index (works for /public/[bucket] or /sign/[bucket])
        final bucketIndex = segments.indexOf(bucket);
        if (bucketIndex != -1 && bucketIndex < segments.length - 1) {
          path = segments.sublist(bucketIndex + 1).join('/');
          // Remove query parameters if any
          if (path.contains('?')) {
            path = path.split('?').first;
          }
        }
      } else if (fileUrlOrPath.startsWith('$bucket/')) {
        path = fileUrlOrPath.replaceAll('$bucket/', '');
      }

      // Supabase remove expects a list of paths relative to the bucket
      await _client.storage.from(bucket).remove([path]);
      debugPrint('ResourceService: Deleted storage file: $path');
    } catch (e) {
      debugPrint(
          'ResourceService: Failed to delete storage file ($fileUrlOrPath): $e');
    }
  }

  // Upload File (PDF/Image)
  Future<String?> uploadFile({
    required String path,
    required Uint8List fileBytes,
    String bucket = 'mock_test', // Default bucket changed to existing one
  }) async {
    try {
      await _client.storage.from(bucket).uploadBinary(
            path,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );
      // Use Signed URL for private buckets (valid for 1 year)
      final signedUrl = await _client.storage
          .from(bucket)
          .createSignedUrl(path, 60 * 60 * 24 * 365);
      return signedUrl;
    } catch (e) {
      // debugPrint('Error uploading file: $e');
      throw Exception('Upload failed: $e');
    }
  }

  // Claim Resource
  Future<void> claimResource({
    required int resourceId,
    required String userId,
  }) async {
    try {
      debugPrint(
          'ResourceService: Attempting to claim free resource $resourceId for user $userId');

      // 1. Check if already purchased/claimed
      final existingOrder = await _client
          .from('order_items')
          .select('order_id, orders!inner(user_id, status)')
          .eq('resource_id', resourceId)
          .eq('orders.user_id', userId)
          .eq('orders.status', 'SUCCESS')
          .maybeSingle();

      if (existingOrder != null) {
        debugPrint(
            'ResourceService: Resource $resourceId already claimed by user $userId. Order: ${existingOrder['order_id']}');
        return;
      }

      // 2. Create Order
      final timestamp = DateTime.now().toUtc().toIso8601String();
      final newOrder = await _client
          .from('orders')
          .insert({
            'user_id': userId,
            'status': 'SUCCESS',
            'total_amount': 0.0,
            'payment_gateway_id': 'FREE_CLAIM',
            'created_at': timestamp,
          })
          .select('order_id')
          .single();

      final orderId = newOrder['order_id'];
      debugPrint('ResourceService: Created FREE order: $orderId');

      // 3. Add Item
      await _client.from('order_items').insert({
        'order_id': orderId,
        'resource_id': resourceId,
        'price_at_purchase': 0.0,
        'created_at': timestamp,
      });

      debugPrint(
          'ResourceService: Successfully claimed resource $resourceId for user $userId');
    } catch (e) {
      debugPrint('Error claiming free resource: $e');
      throw Exception('Failed to claim resource: $e');
    }
  }

  // Create Direct Order
  Future<String> createDirectOrder({
    required int resourceId,
    required double price,
    required String userId,
  }) async {
    try {
      final newOrder = await _client
          .from('orders')
          .insert({
            'user_id': userId,
            'status': 'DIRECT_CHECKOUT',
            'total_amount': price,
          })
          .select('order_id')
          .single();

      final orderId = newOrder['order_id'];

      await _client.from('order_items').insert({
        'order_id': orderId,
        'resource_id': resourceId,
        'price_at_purchase': price,
      });

      return orderId;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  String _typeToString(ResourceType type) {
    switch (type) {
      case ResourceType.currentAffair:
        return 'current_affair';
      case ResourceType.studyMaterial:
        return 'study_material';
      case ResourceType.eBook:
        return 'ebook';
      case ResourceType.pyq:
        return 'pyq';
    }
  }
}

List<Resource> _parseResources(List<dynamic> jsonList) {
  return jsonList.map((json) => Resource.fromJson(json)).toList();
}

class _SignedUrlEntry {
  final String url;
  final DateTime expiresAt;

  _SignedUrlEntry(this.url, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
