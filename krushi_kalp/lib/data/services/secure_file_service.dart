import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../../utils/crashlytics_service.dart';

class SecureFileService {
  // Singleton pattern
  static final SecureFileService _instance = SecureFileService._internal();
  factory SecureFileService() => _instance;
  SecureFileService._internal();

  /// Downloads a file from [url] and saves it to the Application Documents Directory.
  /// Resulting file is only accessible by this app (Sandboxed).
  ///
  /// Returns the [File] if successful.
  Future<File> downloadSecurely(String url, String fileName) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final secureDir = Directory('${docsDir.path}/secure_resources');

      if (!await secureDir.exists()) {
        await secureDir.create(recursive: true);
      }

      // Sanitize filename
      final cleanName = fileName.replaceAll(RegExp(r'[^\w\s\.-]'), '_');
      final file = File('${secureDir.path}/$cleanName');

      // Check if file already exists (simple cache mechanism)
      if (await file.exists()) {
        return file;
      }

      final request = await HttpClient().getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Failed to download file: HTTP ${response.statusCode}');
      }

      final bytes = await consolidateHttpClientResponseBytes(response);
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      
      rethrow;
    }
  }

  /// Checks if a file is already downloaded
  Future<bool> isFileDownloaded(String fileName) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final cleanName = fileName.replaceAll(RegExp(r'[^\w\s\.-]'), '_');
      final file = File('${docsDir.path}/secure_resources/$cleanName');
      return await file.exists();
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'secure_file_service');
      return false;
    }
  }

  Future<Directory> getSecureDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    return Directory('${docsDir.path}/secure_resources');
  }
}
