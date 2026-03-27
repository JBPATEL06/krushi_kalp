import 'dart:io';

void main() {
  final presentationDir = Directory('lib/presentation');
  if (!presentationDir.existsSync()) {
    return;
  }

  int issuesFound = 0;

  final dartFiles = presentationDir
      .listSync(recursive: true)
      .where((file) => file is File && file.path.endsWith('.dart'));

  // Regex for raw numeric values in patterns
  final rawNum = r'[0-9]+(\.[0-9]+)?';
  final patternRegex = RegExp(
    '('
            'width\\s*:\\s*$rawNum|height\\s*:\\s*$rawNum|'
            'SizedBox\\s*\\(\\s*(width|height)\\s*:\\s*$rawNum|'
            'fontSize\\s*:\\s*$rawNum|'
            'EdgeInsets\\.(all|only|symmetric)\\s*\\(|'
            'BorderRadius\\.circular\\s*\\(\\s*$rawNum'
            ')',
    caseSensitive: false,
  );

  // Exact number extractor for EdgeInsets check
  final numRegex = RegExp(rawNum);

  for (final entity in dartFiles) {
    final file = entity as File;
    final lines = file.readAsLinesSync();

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty || line.startsWith('//')) continue;

      if (patternRegex.hasMatch(line)) {
        // Exclude safe lines
        if (line.contains('context.h(') ||
            line.contains('context.w(') ||
            line.contains('context.sp(') ||
            line.contains('AppSpacing.') ||
            line.contains('AppRadius.') ||
            line.contains('AppTypography.') ||
            line.contains('radius:') || // Likely a token or parameter name
            (line.contains('SizedBox(height: 2)') &&
                !line.contains('width:')) || // Hairlines are allowed
            (line.contains('elevation:') &&
                !line.contains('width:') &&
                !line.contains('height:'))) {
          continue;
        }

        // Special check for EdgeInsets to ensure it's not just using a variable/token
        if (line.contains('EdgeInsets.')) {
          // If it has a raw number, flag it
          if (!numRegex.hasMatch(line)) continue;
        }

        issuesFound++;
      }
    }
  }
  print('Issues found: $issuesFound');
}
