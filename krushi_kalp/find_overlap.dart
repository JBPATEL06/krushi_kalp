import 'dart:io';

void main() {
  final dir = Directory('lib/presentation/screens');
  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  List<String> riskyScreens = [];

  for (final file in files) {
    String content = file.readAsStringSync();

    // Check if it's a UI screen (has Scaffold)
    if (content.contains('Scaffold(')) {
      // Check if it lacks SafeArea and missing dynamic bottom padding like MediaQuery
      bool hasSafeArea = content.contains('SafeArea(');
      bool hasDynamicPadding =
          content.contains('MediaQuery.of(context).padding.bottom') ||
              content.contains('viewInsets.bottom');
      bool hasBottomNav = content.contains('bottomNavigationBar:');

      if (!hasSafeArea && !hasDynamicPadding && !hasBottomNav) {
        // High risk: Scaffold without safe area, dynamic bottom padding, or bottom nav bar
        riskyScreens.add(file.path.replaceAll('\\\\', '/'));
      }
    }
  }

  final out = File('overlap_report.md');
  StringBuffer sb = StringBuffer();
  sb.writeln("### Screens at Risk of Bottom Navigation Bar Overlap");
  sb.writeln(
      "Total potentially affected screens: " + riskyScreens.length.toString());
  sb.writeln();

  for (var screen in riskyScreens) {
    sb.writeln("- " + screen);
  }

  out.writeAsStringSync(sb.toString());
}
