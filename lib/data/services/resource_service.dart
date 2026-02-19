import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/resource.dart';

class ResourceService {
  final SupabaseClient _client = Supabase.instance.client;

  // Fetch resources by type (and optional category)
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
    return (response as List).map((e) => Resource.fromJson(e)).toList();
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
    for (var item in itemsRes as List) {
      if (item['resources'] != null) {
        resources.add(Resource.fromJson(item['resources']));
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
        // Assume if it starts with http, it's already a full URL (or public)
        if (!r.fileUrl!.startsWith('http')) {
          try {
            final path = r.fileUrl!.replaceAll('$bucket/', '');
            signedFile = await _client.storage
                .from(bucket)
                .createSignedUrl(path, 60 * 60 * 24);
          } catch (_) {}
        } else {
          signedFile = r.fileUrl;
        }
      }

      if (r.thumbnailUrl != null && r.thumbnailUrl!.isNotEmpty) {
        if (!r.thumbnailUrl!.startsWith('http')) {
          try {
            final path = r.thumbnailUrl!.replaceAll('$bucket/', '');
            signedThumb = await _client.storage
                .from(bucket)
                .createSignedUrl(path, 60 * 60 * 24);
          } catch (_) {}
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
    await _client.from('resources').insert(resource.toJson());
  }

  // Admin: Update Resource
  Future<void> updateResource(int id, Map<String, dynamic> updates) async {
    await _client.from('resources').update(updates).eq('id', id);
  }

  // Admin: Delete Resource
  Future<void> deleteResource(int id) async {
    await _client.from('resources').delete().eq('id', id);
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
      // 1. Check if already purchased/claimed
      // We can skip this check if UI handles it, but good for safety.
      // Simplify: Just insert. RLS or logic should handle duplicates if needed.

      // 2. Create Order
      final newOrder = await _client
          .from('orders')
          .insert({
            'user_id': userId,
            'status': 'SUCCESS',
            'total_amount': 0,
            'payment_gateway_id': 'FREE_CLAIM',
            'created_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select('order_id')
          .single();

      final orderId = newOrder['order_id'];

      // 3. Add Item
      await _client.from('order_items').insert({
        'order_id': orderId,
        'resource_id': resourceId,
        'price_at_purchase': 0,
      });
    } catch (e) {
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
