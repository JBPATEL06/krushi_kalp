import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// A centralized utility to manage signed URLs from Supabase Storage.
/// Handles caching and automatic refresh before expiry.
class SupabaseUrlHelper {
  // --- CACHE ---
  static final Map<String, _SignedUrlEntry> _urlCache = {};

  /// Default TTL for signed URLs. Supabase typically defaults to 1 hour,
  /// and maxes out at 2 hours for many configurations. We cache for 1 hour
  /// to ensure we stay safe and refresh before the hard limit.
  static const Duration defaultTtl = Duration(hours: 1);

  /// Gets a fresh signed URL for the given path.
  /// If a valid (non-expired) URL exists in cache, it's returned immediately.
  static Future<String> getFreshSignedUrl({
    required String bucketName,
    required String storagePath,
    Duration ttl = defaultTtl,
  }) async {
    if (storagePath.isEmpty) return '';

    // If it's already a full HTTP URL, return it as is
    if (storagePath.startsWith('http')) return storagePath;

    // Clean path (remove bucket name prefix if present)
    String cleanPath = storagePath;
    if (storagePath.startsWith('$bucketName/')) {
      cleanPath = storagePath.replaceAll('$bucketName/', '');
    }

    final cacheKey = '$bucketName|$cleanPath';
    final cached = _urlCache[cacheKey];

    if (cached != null && !cached.isExpired) {
      return cached.url;
    }

    return await forceRefresh(
      bucketName: bucketName,
      storagePath: cleanPath,
      ttl: ttl,
    );
  }

  /// Bypasses cache and fetches a new signed URL from Supabase.
  static Future<String> forceRefresh({
    required String bucketName,
    required String storagePath,
    Duration ttl = defaultTtl,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      // Clean path
      String cleanPath = storagePath;
      if (storagePath.startsWith('$bucketName/')) {
        cleanPath = storagePath.replaceAll('$bucketName/', '');
      }

      final cacheKey = '$bucketName|$cleanPath';

      debugPrint('SupabaseUrlHelper: Fetching fresh signed URL for $cacheKey');

      final signedUrl = await supabase.storage
          .from(bucketName)
          .createSignedUrl(cleanPath, ttl.inSeconds);

      _urlCache[cacheKey] = _SignedUrlEntry(
        url: signedUrl,
        expiresAt: DateTime.now().add(ttl),
      );

      return signedUrl;
    } catch (e) {
      debugPrint('SupabaseUrlHelper: Error signing URL: $e');
      // If signing fails, return the original path as fallback
      return storagePath;
    }
  }

  /// Clears the entire URL cache. Call this on logout.
  static void clearCache() {
    _urlCache.clear();
  }

  /// Helper to extract path from any Supabase storage URL (signed or public)
  static String extractPathFromUrl(String url, String bucketName) {
    // If it doesn't start with http, it's already a path
    if (!url.startsWith('http')) return url;

    // Check for the standard Supabase storage segment
    if (!url.contains('/storage/v1/object/')) return url;

    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;

      // URL Format: .../storage/v1/object/[public/sign]/[bucket]/[...path]
      int objectIndex = segments.indexOf('object');
      if (objectIndex != -1 && segments.length > objectIndex + 2) {
        // The segment after 'object' is usually 'public' or 'sign'
        // The segment after that is the bucket name
        // Everything after that is the file path
        String path = segments.sublist(objectIndex + 2).join('/');

        // Remove query parameters (like signature/tokens)
        if (path.contains('?')) {
          path = path.split('?').first;
        }
        return path;
      }
    } catch (e) {
      debugPrint('SupabaseUrlHelper: Error extracting path: $e');
    }

    return url;
  }
}

class _SignedUrlEntry {
  final String url;
  final DateTime expiresAt;

  _SignedUrlEntry({required this.url, required this.expiresAt});

  // We consider it expired 5 minutes BEFORE the actual expiry for safety
  bool get isExpired =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 5)));
}
