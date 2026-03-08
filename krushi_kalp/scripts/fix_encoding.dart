import 'dart:io';

void main() async {
  final Map<String, String> replacements = {
    'â‚¹': '₹',
    'âœ“': '✓',
    'âœ—': '✗',
    'â€”': '—',
    'â€“': '–',
    'â€¢': '•',
    'â”┌': '┌',
    'â”€': '─',
    'â”‚': '│',
    'â””': '└',
    'â”˜': '┘',
    'â”¬': '┬',
    'â”´': '┴',
    'â”¼': '┼',
  };

  final dir = Directory('lib');
  int fixedFiles = 0;
  int totalReplacements = 0;

  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      String content = await entity.readAsString();
      String original = content;

      replacements.forEach((corrupted, correct) {
        if (content.contains(corrupted)) {
          final count = corrupted.allMatches(content).length;
          content = content.replaceAll(corrupted, correct);
          totalReplacements += count;
        }
      });

      if (content != original) {
        await entity.writeAsString(content);
        fixedFiles++;
        print('Fixed: ${entity.path}');
      }
    }
  }

  print('\nDone!');
  print('Fixed files: $fixedFiles');
  print('Total replacements: $totalReplacements');
}
