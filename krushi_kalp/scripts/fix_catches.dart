/// fix_catches.dart
/// Run with: dart run scripts/fix_catches.dart
///
/// This script finds all `} catch (e) {` in lib/ (skipping scripts/),
/// upgrades them to `} catch (e, stack) {`, and inserts a
/// CrashlyticsService.instance.recordError call after the opening brace.
///
/// It also ensures the file imports crashlytics_service.dart if it doesn't yet.
library;

import 'dart:io';

void main() {
  final dir = Directory('lib');
  var filesPatched = 0;
  var catchesFixed = 0;

  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;

    var source = entity.readAsStringSync();
    if (!source.contains('} catch (e) {')) continue;

    // ── 1. Upgrade catch signature ──────────────────────────────────────────
    final upgraded = source.replaceAll('} catch (e) {', '} catch (e, stack) {');
    final count = 'catch (e) {'.allMatches(source).length;

    // ── 2. Add Crashlytics import if file uses it but doesn't import it ─────
    String withImport = upgraded;
    final hasCrashlytics = upgraded.contains('crashlytics_service.dart');
    final hasRecordError = upgraded.contains('CrashlyticsService');

    if (!hasCrashlytics && !hasRecordError) {
      // Need to figure out correct relative path from lib/ subdirectory
      final relPath = entity.path.replaceAll('\\', '/');
      final depth = relPath.split('/').length - 2; // subtract 'lib/' and filename
      final prefix = '../' * depth;
      final importLine =
          "import '${prefix}utils/crashlytics_service.dart';\n";

      // Insert after last existing import or at top
      final lastImportIdx = upgraded.lastIndexOf("import '");
      if (lastImportIdx != -1) {
        final endOfImport = upgraded.indexOf('\n', lastImportIdx) + 1;
        withImport = upgraded.substring(0, endOfImport) +
            importLine +
            upgraded.substring(endOfImport);
      }
    }

    // ── 3. Insert recordError after each `} catch (e, stack) {` ──────────────
    // We use a regex to inject a log line after the opening brace
    // but only if the block doesn't already call CrashlyticsService or recordError
    final lines = withImport.split('\n');
    final result = <String>[];
    for (var i = 0; i < lines.length; i++) {
      result.add(lines[i]);
      final trimmed = lines[i].trim();
      if (trimmed == '} catch (e, stack) {') {
        // Peek ahead: if next non-empty line doesn't already call Crashlytics
        String? nextNonEmpty;
        for (var j = i + 1; j < lines.length; j++) {
          if (lines[j].trim().isNotEmpty) {
            nextNonEmpty = lines[j].trim();
            break;
          }
        }
        final alreadyLogs = nextNonEmpty != null &&
            (nextNonEmpty.contains('CrashlyticsService') ||
                nextNonEmpty.contains('recordError') ||
                nextNonEmpty.contains('debugPrint') ||
                nextNonEmpty.contains('rethrow'));
        if (!alreadyLogs) {
          // Determine indentation
          final indent = lines[i].indexOf('}') > 0
              ? ' ' * (lines[i].indexOf('}') + 2)
              : '      ';
          result.add(
              '${indent}CrashlyticsService.instance.recordError(e, stack, reason: \'${_reasonFromFile(entity.path)}\');');
        }
      }
    }

    final finalSource = result.join('\n');
    entity.writeAsStringSync(finalSource);
    filesPatched++;
    catchesFixed += count;
    print('✅ Patched ${entity.path} ($count catches)');
  }

  print('\nDone. $filesPatched files patched, $catchesFixed catch blocks upgraded.');
}

String _reasonFromFile(String path) {
  final parts = path.replaceAll('\\', '/').split('/');
  final filename = parts.last.replaceAll('.dart', '');
  return filename;
}
