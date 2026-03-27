import 'dart:io';

void main() async {
  final libDir = Directory('lib');
  if (!await libDir.exists()) {
    return;
  }

  // Regex to find print and debugPrint statements
  // This matches print or debugPrint followed by optional whitespace and (
  // then any characters (non-greedily) until );
  final printRegex =
      RegExp(r'\b(print|debugPrint)\s*\([\s\S]*?\);', multiLine: true);

  int modifiedFiles = 0;
  int removedCount = 0;

  await for (final entity in libDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = await entity.readAsString();

      if (printRegex.hasMatch(content)) {
        final newContent = content.replaceAllMapped(printRegex, (match) {
          removedCount++;
          // We return an empty string to remove the call.
          // Note: This might leave empty lines, which dart format can clean up later.
          return '';
        });

        if (newContent != content) {
          await entity.writeAsString(newContent);
          modifiedFiles++;
        }
      }
    }
  }
}
