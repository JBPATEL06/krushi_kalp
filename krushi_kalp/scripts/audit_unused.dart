import 'dart:io';

void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('Lib directory not found.');
    return;
  }

  print('--- Unused Files & Dead Code Audit ---');

  final allFiles = libDir
      .listSync(recursive: true)
      .where((e) => e is File && e.path.endsWith('.dart'))
      .map((e) => e.path.replaceAll('\\', '/'))
      .toList();

  final Map<String, int> importCounts = {};
  for (var file in allFiles) {
    importCounts[file] = 0;
  }

  // Count imports
  for (var file in allFiles) {
    final content = File(file).readAsStringSync();
    final importRegex =
        RegExp(r"import\s+['" '"' r"]([^'" '"' r"]+)['" + '"' + r"]");
    final matches = importRegex.allMatches(content);

    for (var match in matches) {
      var importPath = match.group(1)!;
      if (importPath.startsWith('package:')) {
        // Handle package imports to local files if applicable
        // E.g. package:krushi_kalp/domain/models/item.dart -> lib/domain/models/item.dart
        if (importPath.contains('krushi_kalp/')) {
          final localPath = 'lib/${importPath.split('krushi_kalp/').last}';
          if (importCounts.containsKey(localPath)) {
            importCounts[localPath] = importCounts[localPath]! + 1;
          }
        }
      } else if (!importPath.startsWith('dart:') && !importPath.contains(':')) {
        // Relative import
        final currentDir = File(file).parent.path.replaceAll('\\', '/');
        final absoluteImportPath = _resolveRelativePath(currentDir, importPath);
        if (importCounts.containsKey(absoluteImportPath)) {
          importCounts[absoluteImportPath] =
              importCounts[absoluteImportPath]! + 1;
        }
      }
    }
  }

  int unusedFiles = 0;
  for (var file in allFiles) {
    // Exclude main.dart and any other entry points if they exist
    if (file.endsWith('main.dart') || file.contains('/generated/')) continue;

    if (importCounts[file] == 0) {
      print('[UNUSED FILE] $file');
      unusedFiles++;
    }
  }

  print('---------------------------------------');
  print('Total unused files found: $unusedFiles');
}

String _resolveRelativePath(String currentDir, String relativePath) {
  var parts = currentDir.split('/');
  var relParts = relativePath.split('/');

  for (var part in relParts) {
    if (part == '.') continue;
    if (part == '..') {
      if (parts.isNotEmpty) parts.removeLast();
    } else {
      parts.add(part);
    }
  }
  return parts.join('/');
}
