import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

/// Represents the current state of a download
enum DownloadStatus {
  idle,
  downloading,
  completed,
  error,
  cancelled,
}

/// Progress information for a download
class DownloadProgress {
  final int bytesReceived;
  final int totalBytes;
  final double percentage;
  final DownloadStatus status;
  final String? errorMessage;

  DownloadProgress({
    required this.bytesReceived,
    required this.totalBytes,
    required this.percentage,
    required this.status,
    this.errorMessage,
  });

  bool get isComplete => status == DownloadStatus.completed;
  bool get isDownloading => status == DownloadStatus.downloading;
  bool get hasError => status == DownloadStatus.error;
}

class DownloadService {
  // Singleton
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  // ── Internal helpers ───────────────────────────────────────────────────────

  /// Returns the private, per-user storage directory.
  /// [userId] is MANDATORY — throws [ArgumentError] if null/empty to prevent
  /// silent fallback to a shared directory accessible by other accounts.
  Future<Directory> _userDir(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError(
          'userId must not be empty — refusing to use shared directory');
    }
    final root = await getApplicationDocumentsDirectory();
    final safeId = userId.replaceAll(RegExp(r'[^\w-]'), '_');
    final dir = Directory('${root.path}/user_$safeId');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Returns the absolute path for [filename] inside the user's directory.
  /// Sanitises filename to prevent directory-traversal attacks.
  Future<String> getLocalPath(String filename, {String? userId}) async {
    if (userId == null || userId.isEmpty) {
      throw ArgumentError(
          'userId is required — always pass the authenticated user ID');
    }
    final sanitized = filename.replaceAll(RegExp(r'[^\w\s\.-]'), '_');
    final dir = await _userDir(userId);
    return '${dir.path}/$sanitized';
  }

  // ── Ownership Manifest ─────────────────────────────────────────────────────

  /// The manifest is a JSON file stored inside the user's directory.
  /// Format: { "filename": "userId", ... }
  /// It records that THIS userId downloaded each file. On open, we verify
  /// the requesting user is the owner.
  Future<File> _manifestFile(String userId) async {
    final dir = await _userDir(userId);
    return File('${dir.path}/_manifest.json');
  }

  Future<Map<String, String>> _readManifest(String userId) async {
    try {
      final file = await _manifestFile(userId);
      if (!await file.exists()) return {};
      final raw = await file.readAsString();
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as String));
    } catch (e) {
      debugPrint('DownloadService: Error reading manifest: $e');
      return {};
    }
  }

  Future<void> _writeManifest(
      String userId, Map<String, String> manifest) async {
    try {
      final file = await _manifestFile(userId);
      await file.writeAsString(json.encode(manifest));
    } catch (e) {
      debugPrint('DownloadService: Error writing manifest: $e');
    }
  }

  /// Records that [userId] owns [filename].
  Future<void> _registerOwnership(String userId, String filename) async {
    final manifest = await _readManifest(userId);
    manifest[filename] = userId;
    await _writeManifest(userId, manifest);
  }

  /// Returns true only if [userId] is the recorded owner of [filename].
  /// Returns false if the file doesn't appear in the manifest (unregistered
  /// legacy file) — callers should treat this as a security failure.
  Future<bool> verifyOwnership(String filename,
      {required String userId}) async {
    if (userId.isEmpty) return false;
    final sanitized = filename.replaceAll(RegExp(r'[^\w\s\.-]'), '_');
    final manifest = await _readManifest(userId);
    final owner = manifest[sanitized];
    if (owner == null) {
      // Legacy file with no manifest entry — default deny
      debugPrint(
          'DownloadService: No manifest entry for $sanitized — access denied');
      return false;
    }
    final allowed = owner == userId;
    if (!allowed) {
      debugPrint(
          'DownloadService: Ownership mismatch for $sanitized (owner=$owner, requester=$userId)');
    }
    return allowed;
  }

  /// Migrates files that were downloaded before the per-user directory system
  /// was enforced. Old downloads lived in the root documents directory; new
  /// ones live in user_{id}/. This method scans the root, finds any
  /// resource_*.pdf or mock_test_*.json files, moves them into the user
  /// directory, and registers ownership in the manifest.
  ///
  /// **Safe to call on every login** — skips files already in the user dir.
  Future<void> migrateOldDownloads(String userId) async {
    if (userId.isEmpty) return;
    try {
      final root = await getApplicationDocumentsDirectory();
      final userDir = await _userDir(userId);

      // Patterns that match downloaded content files
      final pattern = RegExp(r'^(resource_\d+\.pdf|mock_test_\d+\.json)$');

      final rootEntities = root.listSync(followLinks: false);
      int migrated = 0;

      for (final entity in rootEntities) {
        if (entity is! File) continue;
        final basename = entity.path.split(Platform.pathSeparator).last;
        if (!pattern.hasMatch(basename)) continue;

        final dest = File('${userDir.path}/$basename');
        if (await dest.exists()) {
          // Already migrated — delete the stale root copy
          await entity.delete();
          debugPrint('DownloadService: Removed stale root copy: $basename');
          continue;
        }

        // Move: copy then delete original
        await entity.copy(dest.path);
        await entity.delete();
        await _registerOwnership(userId, basename);
        migrated++;
        debugPrint('DownloadService: Migrated $basename → user dir');
      }

      if (migrated > 0) {
        debugPrint(
            'DownloadService: Migration complete — moved $migrated file(s) for $userId');
      }
    } catch (e) {
      debugPrint('DownloadService: Migration error: $e');
    }
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Checks if a file exists locally for [userId].
  Future<bool> isFileDownloaded(String filename, {String? userId}) async {
    try {
      if (userId == null || userId.isEmpty) return false;
      final path = await getLocalPath(filename, userId: userId);
      return File(path).exists();
    } catch (e) {
      debugPrint('Error checking file existence: $e');
      return false;
    }
  }

  /// Downloads a file with progress tracking via Stream.
  /// Registers ownership in the manifest on success.
  Stream<DownloadProgress> downloadFileWithProgress(String url, String filename,
      {String? userId}) async* {
    if (userId == null || userId.isEmpty) {
      yield DownloadProgress(
        bytesReceived: 0,
        totalBytes: 0,
        percentage: 0,
        status: DownloadStatus.error,
        errorMessage: 'Authentication required to download files',
      );
      return;
    }

    try {
      final path = await getLocalPath(filename, userId: userId);
      final file = File(path);

      if (await file.exists()) {
        debugPrint('File already exists: $path');
        // Re-register ownership in case manifest was lost
        await _registerOwnership(userId, filename);
        yield DownloadProgress(
          bytesReceived: 0,
          totalBytes: 0,
          percentage: 100.0,
          status: DownloadStatus.completed,
        );
        return;
      }

      debugPrint('Starting download: $url -> $path');
      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        yield DownloadProgress(
          bytesReceived: 0,
          totalBytes: 0,
          percentage: 0.0,
          status: DownloadStatus.error,
          errorMessage: 'HTTP ${response.statusCode}',
        );
        return;
      }

      final contentLength = response.contentLength ?? 0;
      var receivedBytes = 0;
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        final percentage =
            contentLength > 0 ? (receivedBytes / contentLength * 100) : 0.0;
        yield DownloadProgress(
          bytesReceived: receivedBytes,
          totalBytes: contentLength,
          percentage: percentage,
          status: DownloadStatus.downloading,
        );
      }

      await sink.close();
      debugPrint('Download complete: $path');

      // Register ownership after successful download
      await _registerOwnership(userId, filename);

      yield DownloadProgress(
        bytesReceived: receivedBytes,
        totalBytes: contentLength,
        percentage: 100.0,
        status: DownloadStatus.completed,
      );
    } catch (e) {
      debugPrint('Download error: $e');
      yield DownloadProgress(
        bytesReceived: 0,
        totalBytes: 0,
        percentage: 0.0,
        status: DownloadStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Downloads a file from [url] and saves it to the user's directory.
  /// Registers ownership on success.
  Future<String> downloadFile(String url, String filename,
      {Function(double)? onProgress, String? userId}) async {
    if (userId == null || userId.isEmpty) {
      throw ArgumentError('userId is required to download files');
    }
    try {
      final path = await getLocalPath(filename, userId: userId);
      final file = File(path);

      if (await file.exists()) {
        debugPrint('File already exists: $path');
        await _registerOwnership(userId, filename);
        return path;
      }

      debugPrint('Starting download: $url -> $path');
      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception('Download failed with status: ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      var receivedBytes = 0;
      final sink = file.openWrite();

      await response.stream.listen(
        (chunk) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          if (contentLength > 0 && onProgress != null) {
            onProgress(receivedBytes / contentLength);
          }
        },
        onDone: () async {
          await sink.close();
        },
        onError: (e) {
          sink.close();
          throw e;
        },
        cancelOnError: true,
      ).asFuture();

      debugPrint('Download complete: $path');
      await _registerOwnership(userId, filename);
      return path;
    } catch (e) {
      debugPrint('Download error: $e');
      rethrow;
    }
  }

  /// Deletes a file and removes its entry from the ownership manifest.
  Future<void> deleteFile(String filename, {String? userId}) async {
    if (userId == null || userId.isEmpty) {
      throw ArgumentError('userId is required to delete files');
    }
    try {
      final path = await getLocalPath(filename, userId: userId);
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        debugPrint('File deleted: $path');
      }
      // Remove from manifest
      final manifest = await _readManifest(userId);
      final sanitized = filename.replaceAll(RegExp(r'[^\w\s\.-]'), '_');
      manifest.remove(sanitized);
      await _writeManifest(userId, manifest);
    } catch (e) {
      debugPrint('Error deleting file: $e');
      rethrow;
    }
  }

  /// Calculates the total size (in bytes) of all files in the user's directory.
  Future<int> getTotalStorageUsed(String userId) async {
    if (userId.isEmpty) return 0;
    try {
      final dir = await _userDir(userId);
      int totalSize = 0;
      if (await dir.exists()) {
        await for (final entity
            in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }
      return totalSize;
    } catch (e) {
      debugPrint('Error calculating storage size: $e');
      return 0;
    }
  }

  /// Wipes all files in the user's directory and resets the manifest.
  Future<void> clearAllDownloads(String userId) async {
    if (userId.isEmpty) return;
    try {
      final dir = await _userDir(userId);
      if (await dir.exists()) {
        final entities = dir.listSync();
        for (final entity in entities) {
          await entity.delete(recursive: true);
        }
      }
      debugPrint('Storage cleared for user: $userId');
    } catch (e) {
      debugPrint('Error clearing storage: $e');
      rethrow;
    }
  }
}
