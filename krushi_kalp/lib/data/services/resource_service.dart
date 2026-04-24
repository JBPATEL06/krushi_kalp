import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/resource.dart';
import '../../utils/supabase_url_helper.dart';
import 'auth_service.dart';
import 'cart_service.dart';
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

  /// Fetches a precise page of resources for infinite scrolling.
  Future<List<Resource>> fetchPaginatedResources({
    required ResourceType type,
    required int offset,
    required int limit,
    String? category,
    bool isAdmin = false,
  }) async {
    try {
      final typeStr = _typeToString(type);
      var query = _client.from('resources').select().eq('type', typeStr);

      if (!isAdmin) {
        query = query.eq('is_active', true);
      }

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final resources =
          await compute(_parseResources, response as List<dynamic>);
      return await _signResources(resources);
    } catch (e, stack) {
      CrashlyticsService.instance
          .recordError(e, stack, reason: 'resource_service: fetchPaginatedResources');
      return [];
    }
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
    try {
      final response = await _client
          .from('access')
          .select('item_id')
          .eq('user_id', userId)
          .eq('item_type', 'resource');

      if (response.isEmpty) return [];

      final resourceIds = (response as List).map((e) => e['item_id'] as int).toList();

      final resourcesRes = await _client
          .from('resources')
          .select()
          .inFilter('id', resourceIds);

      final List<Resource> resources = (resourcesRes as List).map((json) => Resource.fromJson(json)).toList();
      return await _signResources(resources);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'resource_service: fetchPurchasedResources');
      return [];
    }
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

  /// Handles free resource claims via secure RPC.
  Future<void> claimResource({
    required int resourceId,
    required String userId,
  }) async {
    try {
      // 1. Double check ownership locally first for UX speed
      final isOwned = await CartService.instance.checkOwnership(
        userId: userId,
        resourceId: resourceId,
      );

      if (isOwned) return;

      // 2. Call secure RPC to grant access (it handles price/active validation)
      final response = await _client.rpc('process_item_claim', params: {
        'p_item_id': resourceId,
        'p_item_type': 'resource',
      });

      if (response == null || response['success'] != true) {
        throw Exception(response?['message'] ?? 'Claim failed');
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'resource_service: claimResource');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Initializes a direct purchase for a single resource using the payment/access schema.
  Future<String> createDirectOrder({
    required int resourceId,
    required double price,
    required String userId,
  }) async {
    try {
      // 1. Ownership Check
      final isOwned = await CartService.instance.checkOwnership(
        userId: userId,
        resourceId: resourceId,
      );
      if (isOwned) throw Exception("You already own this item.");

      // 2. Fetch User Profile for Snapshot
      final userProfile = await AuthService.instance.getUserProfile(userId);
      final userSnapshot = {
        'email': userProfile?['email'] ?? 'unknown',
        'username': userProfile?['username'] ?? 'User',
      };

      // 3. Create entry in 'payment' table
      final newPayment = await _client
          .from('payment')
          .insert({
            'user_id': userId,
            'user_snapshot': userSnapshot,
            'status': 'PENDING',
            'amount': price,
            'gateway': 'razorpay',
            'created_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select('id')
          .single();

      final paymentId = newPayment['id'];

      // 4. Store resource link in metadata for the RPC to process later
      await _client.from('payment').update({
        'metadata': {
          'item_type': 'resource',
          'item_id': resourceId,
          'price_at_purchase': price,
        }
      }).eq('id', paymentId);

      return paymentId;
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'resource_service: createDirectOrder');
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
