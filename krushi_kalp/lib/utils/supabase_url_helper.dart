import 'dart:convert';
import 'package:krushi_kalp/utils/crashlytics_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A centralized utility to manage signed URLs from Supabase Storage.
/// Handles in-memory and persistent caching with automatic refresh logic.
class SupabaseUrlHelper {
  // Singleton
  static final SupabaseUrlHelper _instance = SupabaseUrlHelper._internal();
  factory SupabaseUrlHelper() => _instance;
  SupabaseUrlHelper._internal();

  // --- CACHE CONFIG ---

  /// The in-memory cache of signed URLs.
  static final Map<String, _SignedUrlEntry> _urlCache = {};

  /// Cache TTL of 3 hours matches the Supabase signed URL duration.
  /// We refresh every 2 hours (using a 1-hour safety margin).
  static const Duration _cacheTtl = Duration(hours: 3);

  /// We consider a URL expired 1 hour before its actual expiry (3h - 1h = 2h refresh).
  static const Duration _safetyMargin = Duration(hours: 1);

  /// Standard expiry for Supabase Signed URLs (3 Hours).
  static const int maxExpirySeconds = 10800;

  // --- RECOVERY & PERSISTENCE ---

  /// Prefix for persistent SharedPreferences keys.
  static const String _prefPrefix = 'signed_url__';

  /// Helper to encode a storage path for use as a SharedPreferences key.
  String _encodeKey(String bucket, String path) {
    // Replace characters that might be problematic in preference keys
    final sanitizedPath =
        path.replaceAll('/', '__SLASH__').replaceAll('.', '__DOT__');
    return '$_prefPrefix${bucket}__$sanitizedPath';
  }

  // --- PUBLIC API ---

  /// Gets a fresh signed URL for the given path.
  Future<String> getFreshSignedUrl(
      String bucketName, String storagePath) async {
    if (storagePath.isEmpty) return '';

    // If it's already a full HTTP URL, return it as is
    if (storagePath.startsWith('http')) return storagePath;

    // Clean path (remove bucket name prefix if present)
    String cleanPath = storagePath;
    if (cleanPath.startsWith('$bucketName/')) {
      cleanPath = cleanPath.substring(bucketName.length + 1);
    }

    final cacheKey = '$bucketName|$cleanPath';

    // 1. Check in-memory cache
    final cached = _urlCache[cacheKey];
    if (cached != null && !cached.isExpired(_safetyMargin)) {
      return cached.url;
    }

    // 2. Check SharedPreferences for persistence across restarts
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefKey = _encodeKey(bucketName, cleanPath);
      final storedJson = prefs.getString(prefKey);

      if (storedJson != null) {
        final data = json.decode(storedJson) as Map<String, dynamic>;
        final expiry = DateTime.parse(data['expiry'] as String);

        if (expiry.isAfter(DateTime.now().add(_safetyMargin))) {
          final url = data['url'] as String;
          // Warm the in-memory cache
          _urlCache[cacheKey] = _SignedUrlEntry(url: url, expiresAt: expiry);
          return url;
        }
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack,
          reason:
              'SupabaseUrlHelper: Persistent cache read failed for $bucketName/$cleanPath');
    }

    // 3. Fallback to Supabase API
    return await forceRefresh(
      bucketName: bucketName,
      storagePath: cleanPath,
    );
  }

  /// Bypasses all caches and fetches a new signed URL from Supabase.
  Future<String> forceRefresh({
    required String bucketName,
    required String storagePath,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      // Clean path (remove bucket name prefix if present)
      String cleanPath = storagePath;
      if (cleanPath.startsWith('$bucketName/')) {
        cleanPath = cleanPath.substring(bucketName.length + 1);
      }

      final cacheKey = '$bucketName|$cleanPath';

      // 3. Fallback to Supabase API
      // Sanitize path: remove double slashes and leading slashes which cause 404s
      final sanitizedPath = cleanPath.replaceAll('//', '/').replaceFirst(RegExp(r'^/'), '');
      
      if (sanitizedPath.isEmpty) return storagePath;

      final signedUrl = await supabase.storage
          .from(bucketName)
          .createSignedUrl(sanitizedPath, maxExpirySeconds);

      final expiry = DateTime.now().add(_cacheTtl);

      // Update in-memory cache
      _urlCache[cacheKey] = _SignedUrlEntry(
        url: signedUrl,
        expiresAt: expiry,
      );

      // Update persistent cache
      try {
        final prefs = await SharedPreferences.getInstance();
        final prefKey = _encodeKey(bucketName, cleanPath);
        await prefs.setString(
            prefKey,
            json.encode({
              'url': signedUrl,
              'expiry': expiry.toIso8601String(),
            }));
      } catch (e, stack) {
        CrashlyticsService.instance.recordError(e, stack,
            reason:
                'SupabaseUrlHelper: Persistent cache write failed for $bucketName/$cleanPath');
      }

      return signedUrl;
    } on StorageException {
      // Specifically handle 404/Object Not Found without crashing
      print('⚠️ Supabase Storage 404: Object "$storagePath" not found in bucket "$bucketName"');
      
      // We don't record 404s as errors in Crashlytics as they are often expected content gaps,
      // but we return empty string to prevent HttpClient from crashing on an invalid URI.
      return ''; 
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack,
          reason:
              'SupabaseUrlHelper: Signed URL creation failed for $bucketName/$storagePath');
      return ''; 
    }
  }

  /// Clears the entire URL cache (both memory and SharedPreferences).
  Future<void> clearCache() async {
    _urlCache.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys =
          prefs.getKeys().where((k) => k.startsWith(_prefPrefix)).toList();
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack,
          reason: 'SupabaseUrlHelper: Clear cache failed');
    }
  }

  /// Extracts the storage path from any Supabase storage URL.
  static String extractPathFromUrl(String url, String bucketName) {
    if (!url.startsWith('http')) return url;
    if (!url.contains('/storage/v1/object/')) return url;

    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;

      int objectIndex = segments.indexOf('object');
      if (objectIndex != -1 && segments.length > objectIndex + 2) {
        String path = segments.sublist(objectIndex + 2).join('/');
        if (path.contains('?')) {
          path = path.split('?').first;
        }
        return path;
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack,
          reason: 'SupabaseUrlHelper: Path extraction from URL failed: $url');
    }

    return url;
  }
}

/// Internal model for a cached signed URL entry.
class _SignedUrlEntry {
  final String url;
  final DateTime expiresAt;

  _SignedUrlEntry({required this.url, required this.expiresAt});

  /// Checks if the URL has expired based on a given [margin].
  bool isExpired(Duration margin) =>
      DateTime.now().isAfter(expiresAt.subtract(margin));
}
