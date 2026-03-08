import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/home_banner.dart';

class BannerService {
  // Singleton
  static final BannerService _instance = BannerService._internal();
  factory BannerService() => _instance;
  BannerService._internal();

  static BannerService get instance => _instance;

  final _supabase = Supabase.instance.client;
  final _bucket = 'banners';
  final _table = 'banner';

  // ─────────────────────────────────────────
  // USER: Fetch active banners (ordered by priority desc)
  // ─────────────────────────────────────────
  Future<List<HomeBanner>> fetchActiveBanners() async {
    try {
      final response = await _supabase
          .from(_table)
          .select()
          .eq('is_active', true)
          .order('priority', ascending: false);

      return (response as List)
          .map((json) => HomeBanner.fromJson(json))
          .toList();
    } catch (e) {
      
      return [];
    }
  }

  // ─────────────────────────────────────────
  // ADMIN: Real-time stream of ALL banners
  // ─────────────────────────────────────────
  Stream<List<HomeBanner>> streamAllBanners() {
    return _supabase
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('priority', ascending: false)
        .map((data) => data.map((json) => HomeBanner.fromJson(json)).toList());
  }

  // ─────────────────────────────────────────
  // ADMIN: Upload a new banner image
  // ─────────────────────────────────────────
  Future<void> uploadBanner(
    Uint8List fileBytes,
    String fileName, {
    String title = 'New Banner',
    int priority = 0,
  }) async {
    try {
      final path = 'banners/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      // 1. Upload image to bucket
      await _supabase.storage.from(_bucket).uploadBinary(
            path,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // 2. Get public URL
      final imageUrl = _supabase.storage.from(_bucket).getPublicUrl(path);

      // 3. Insert record
      await _supabase.from(_table).insert({
        'title': title,
        'image_url': imageUrl,
        'action_type': 'none',
        'action_value': '',
        'is_active': true,
        'priority': priority,
      });

      
    } catch (e) {
      
      rethrow;
    }
  }

  // ─────────────────────────────────────────
  // ADMIN: Replace image of an existing banner
  // ─────────────────────────────────────────
  Future<void> replaceBannerImage(
    int bannerId,
    String oldImageUrl,
    Uint8List newFileBytes,
    String newFileName,
  ) async {
    try {
      final newPath =
          'banners/${DateTime.now().millisecondsSinceEpoch}_$newFileName';

      // 1. Upload new image
      await _supabase.storage.from(_bucket).uploadBinary(
            newPath,
            newFileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // 2. Get new public URL
      final newImageUrl = _supabase.storage.from(_bucket).getPublicUrl(newPath);

      // 3. Update DB record
      await _supabase
          .from(_table)
          .update({'image_url': newImageUrl}).eq('id', bannerId);

      // 4. Delete old image from storage (best effort)
      _deleteStorageFile(oldImageUrl);

      
    } catch (e) {
      
      rethrow;
    }
  }

  // ─────────────────────────────────────────
  // ADMIN: Update banner metadata (title, priority, active)
  // ─────────────────────────────────────────
  Future<void> updateBannerMeta(
    int bannerId, {
    String? title,
    int? priority,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (priority != null) updates['priority'] = priority;
    if (isActive != null) updates['is_active'] = isActive;

    if (updates.isEmpty) return;

    try {
      await _supabase.from(_table).update(updates).eq('id', bannerId);
    } catch (e) {
      
      rethrow;
    }
  }

  // ─────────────────────────────────────────
  // ADMIN: Delete a banner
  // ─────────────────────────────────────────
  Future<void> deleteBanner(int id, String imageUrl) async {
    try {
      // 1. Delete DB record
      await _supabase.from(_table).delete().eq('id', id);

      // 2. Delete storage file (best effort)
      _deleteStorageFile(imageUrl);

      
    } catch (e) {
      
      rethrow;
    }
  }

  // ─────────────────────────────────────────
  // Private: Extract and delete storage file
  // ─────────────────────────────────────────
  void _deleteStorageFile(String imageUrl) {
    try {
      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf(_bucket);
      if (bucketIndex != -1 && bucketIndex < segments.length - 1) {
        final storagePath = segments.sublist(bucketIndex + 1).join('/');
        _supabase.storage.from(_bucket).remove([storagePath]);
      }
    } catch (e) {
      
    }
  }
}
