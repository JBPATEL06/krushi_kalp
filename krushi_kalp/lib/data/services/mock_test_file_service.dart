import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/mock_test_file.dart';
import '../../utils/supabase_url_helper.dart';
import '../../utils/crashlytics_service.dart';

/// Service class for interacting with the 'mock_test_files' table in Supabase.
class MockTestFileService {
  // --- SINGLETON ---
  MockTestFileService._();
  static final MockTestFileService instance = MockTestFileService._();

  final SupabaseClient _client = Supabase.instance.client;

  /// Fetches supplementary files for a mock test.
  Future<List<MockTestFile>> fetchMockTestFiles(int testId) async {
    try {
      final response = await _client
          .from('mock_test_files')
          .select()
          .eq('test_id', testId)
          .order('file_order', ascending: true);

      final files = (response as List<dynamic>)
          .map((json) => MockTestFile.fromJson(json))
          .toList();

      return await _signMockTestFiles(files);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'mock_test_file_service: fetchMockTestFiles');
      return [];
    }
  }

  /// Adds a supplementary/quiz file to a mock test.
  Future<int> addMockTestFile({
    required int testId,
    required String storagePath,
    required String displayName,
    int? fileSizeBytes,
    int fileOrder = 0,
    String fileType = 'supplementary_pdf',
  }) async {
    try {
      final sanitizedPath = SupabaseUrlHelper.extractPathFromUrl(storagePath, 'mock_test');
      final response = await _client.from('mock_test_files').insert({
        'test_id': testId,
        'storage_path': sanitizedPath,
        'display_name': displayName,
        'file_order': fileOrder,
        'file_size_bytes': fileSizeBytes,
        'file_type': fileType,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select('id').single();

      return response['id'] as int;
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'mock_test_file_service: addMockTestFile');
      throw Exception('Failed to add mock test file: $e');
    }
  }

  /// Deletes a supplementary file.
  Future<void> deleteMockTestFile(int fileId, String storagePath) async {
    try {
      await _client.from('mock_test_files').delete().eq('id', fileId);
      try {
        await deleteFileFromStorage(storagePath);
      } catch (_) {}
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'mock_test_file_service: deleteMockTestFile');
      throw Exception('Failed to delete mock test supplementary file: $e');
    }
  }

  /// Renames a supplementary file.
  Future<void> renameMockTestFile(int fileId, String newDisplayName) async {
    try {
      await _client.from('mock_test_files').update({
        'display_name': newDisplayName,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', fileId);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'mock_test_file_service: renameMockTestFile');
      throw Exception('Failed to rename mock test supplementary file: $e');
    }
  }

  /// Reorders supplementary files.
  Future<void> reorderMockTestFiles(List<Map<String, dynamic>> fileOrders) async {
    try {
      for (final item in fileOrders) {
        final id = item['id'];
        final order = item['file_order'];
        await _client.from('mock_test_files').update({
          'file_order': order,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', id);
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'mock_test_file_service: reorderMockTestFiles');
      throw Exception('Failed to reorder mock test supplementary files: $e');
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
      CrashlyticsService.instance.recordError(e, stack, reason: 'mock_test_file_service: Failed to delete file: $fileUrlOrPath');
    }
  }

  /// Helper to convert supplementary storage paths into fresh signed URLs.
  Future<List<MockTestFile>> _signMockTestFiles(List<MockTestFile> files) async {
    return await Future.wait(files.map((f) async {
      String? signedPath;
      const bucket = 'mock_test';
      if (f.storagePath.isNotEmpty) {
        final path = SupabaseUrlHelper.extractPathFromUrl(f.storagePath, bucket);
        if (!path.startsWith('http')) {
          try {
            signedPath = await SupabaseUrlHelper().getFreshSignedUrl(bucket, path);
          } catch (e) {
            debugPrint('Failed to load signed URL for mock test file: $e');
          }
        } else {
          signedPath = path;
        }
      }
      return f.copyWith(storagePath: signedPath ?? f.storagePath);
    }));
  }
}
