import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/resource.dart';
import '../../utils/supabase_url_helper.dart';
import 'test_service.dart';
import 'admin_notification_service.dart';
import '../../utils/crashlytics_service.dart';

/// Service class for interacting with the 'resources' table in Supabase.
class ResourceService {
  // --- SINGLETON ---
  ResourceService._();
  static final ResourceService instance = ResourceService._();

  final SupabaseClient _client = Supabase.instance.client;

  /// Fetches a list of resources filtered by type and optionally category.
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

  /// Fetches a single resource by its ID.
  Future<Resource?> getResourceById(int id) async {
    final response =
        await _client.from('resources').select().eq('id', id).maybeSingle();

    if (response == null) return null;
    final resource = Resource.fromJson(response);
    final signed = await _signResources([resource]);
    return signed.first;
  }

  /// Fetches all resources purchased or claimed by a specific user.
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
        .select('resource_id, resources(*)')
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

  /// Helper to convert storage paths into signed URLs with 1-year expiry.
  /// Uses [SupabaseUrlHelper] for caching and performance.
  Future<List<Resource>> _signResources(List<Resource> resources) async {
    return await Future.wait(resources.map((r) async {
      String? signedFile;
      String? signedThumb;
      const bucket = 'mock_test'; // Centralized bucket for resources and tests

      if (r.fileUrl != null && r.fileUrl!.isNotEmpty) {
        final path = SupabaseUrlHelper.extractPathFromUrl(r.fileUrl!, bucket);
        if (!path.startsWith('http')) {
          try {
            signedFile =
                await SupabaseUrlHelper().getFreshSignedUrl(bucket, path);
          } catch (e) {
            debugPrint('Failed to load signed URL for resource file: $e');
          }
        } else {
          signedFile = path;
        }
      }

      if (r.thumbnailUrl != null && r.thumbnailUrl!.isNotEmpty) {
        final path =
            SupabaseUrlHelper.extractPathFromUrl(r.thumbnailUrl!, bucket);
        if (!path.startsWith('http')) {
          try {
            signedThumb =
                await SupabaseUrlHelper().getFreshSignedUrl(bucket, path);
          } catch (e) {
            debugPrint('Failed to load signed URL for resource thumbnail: $e');
          }
        } else {
          signedThumb = path;
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
        isActive: r.isActive,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

    }));
  }

  // --- ADMIN OPERATIONS ---

  /// Creates a new resource record. Sanitizes URLs to storage paths before insertion.
  /// Returns the newly created resource ID.
  Future<int> createResource(Resource resource) async {
    try {
      final payload = resource.toJson();
      payload.remove('id');

      // Ensure we store sanitized paths, not ephemeral signed URLs
      if (payload['file_url'] != null) {
        payload['file_url'] = SupabaseUrlHelper.extractPathFromUrl(
            payload['file_url'], 'mock_test');
      }
      if (payload['thumbnail_url'] != null) {
        payload['thumbnail_url'] = SupabaseUrlHelper.extractPathFromUrl(
            payload['thumbnail_url'], 'mock_test');
      }

      final response =
          await _client.from('resources').insert(payload).select('id').single();
      final int newId = response['id'];

      // Send broadcast notification for new content
      try {
        await AdminNotificationService().sendBroadcast(
          title: '📖 New Resource Published!',
          body:
              'New ${resource.type.name}: ${resource.title} is now available.',
        );
      } catch (notiErr, stack) {
        CrashlyticsService.instance.recordError(notiErr, stack, reason: 'Broadcast failed after creating resource: ${resource.title}');
      }
      return newId;
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'resource_service');
      throw Exception('Failed to create resource: $e');
    }
  }

  /// Updates an existing resource record.
  Future<void> updateResource(int id, Map<String, dynamic> updates) async {
    try {
      final payload = Map<String, dynamic>.from(updates);
      payload.remove('id');

      if (payload['file_url'] != null) {
        payload['file_url'] = SupabaseUrlHelper.extractPathFromUrl(
            payload['file_url'] as String, 'mock_test');
      }
      if (payload['thumbnail_url'] != null) {
        payload['thumbnail_url'] = SupabaseUrlHelper.extractPathFromUrl(
            payload['thumbnail_url'] as String, 'mock_test');
      }

      await _client.from('resources').update(payload).eq('id', id);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'resource_service');
      throw Exception('Failed to update resource: $e');
    }
  }

  /// Deletes a resource and its associated files from storage.
  Future<void> deleteResource(int id) async {
    try {
      final resource = await getResourceById(id);

      if (resource != null) {
        if (resource.fileUrl != null) {
          await deleteFileFromStorage(resource.fileUrl!);
        }
        if (resource.thumbnailUrl != null) {
          await deleteFileFromStorage(resource.thumbnailUrl!);
        }
      }

      await _client.from('resources').delete().eq('id', id);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'resource_service');
      throw Exception('Failed to delete resource: $e');
    }
  }

  /// Deletes a file from Supabase Storage.
  Future<void> deleteFileFromStorage(String fileUrlOrPath) async {
    try {
      const bucket = 'mock_test';
      String path = SupabaseUrlHelper.extractPathFromUrl(fileUrlOrPath, bucket);

      if (path.startsWith('$bucket/')) {
        path = path.replaceAll('$bucket/', '');
      }

      await _client.storage.from(bucket).remove([path]);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'Failed to delete file from storage: $fileUrlOrPath');
    }
  }

  /// Uploads a binary file to Supabase Storage.
  Future<String?> uploadFile({
    required String path,
    required Uint8List fileBytes,
    String bucket = 'mock_test',
  }) async {
    try {
      await _client.storage.from(bucket).uploadBinary(
            path,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );
      return path;
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'resource_service');
      throw Exception('Upload failed: $e');
    }
  }

  // --- SHOP FLOW ---

  /// Handles free resource claims by creating a $0 order.
  Future<void> claimResource({
    required int resourceId,
    required String userId,
  }) async {
    try {
      final existingOrder = await _client
          .from('order_items')
          .select('order_id, orders!inner(user_id, status)')
          .eq('resource_id', resourceId)
          .eq('orders.user_id', userId)
          .eq('orders.status', 'SUCCESS')
          .maybeSingle();

      if (existingOrder != null) return;

      final timestamp = DateTime.now().toUtc().toIso8601String();
      final newOrder = await _client
          .from('orders')
          .insert({
            'user_id': userId,
            'status': 'DIRECT_CHECKOUT',
            'total_amount': 0.0,
            'payment_gateway_id': 'FREE_CLAIM',
            'created_at': timestamp,
          })
          .select('order_id')
          .single();

      final String orderId = newOrder['order_id'];

      await _client.from('order_items').insert({
        'order_id': orderId,
        'resource_id': resourceId,
        'price_at_purchase': 0.0,
        'created_at': timestamp,
      });

      // Finalize the order securely via RPC
      await TestService.instance.checkout(
        orderId: orderId,
        paymentId: 'FREE_CLAIM',
        amount: 0.0,
        userId: userId,
        paymentGateway: 'FREE_CLAIM',
      );
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'resource_service');
      throw Exception('Failed to claim resource: $e');
    }
  }

  /// Initializes a direct purchase for a single resource.
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
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'resource_service');
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
