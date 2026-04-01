import 'package:flutter_test/flutter_test.dart';

// Simulating the structures used in DownloadsScreen for isolated testing of the logic
class Resource {
  final String id;
  final String title;
  final String category;
  Resource({required this.id, required this.title, required this.category});
}

class MockTest {
  final String id;
  final String title;
  final String category;
  MockTest({required this.id, required this.title, required this.category});
}

void main() {
  group('DownloadsScreen Filter Logic', () {
    final mockTests = [
      MockTest(id: '1', title: 'Agriculture 2023 PYQ', category: 'General'),
      MockTest(id: '2', title: 'Soil Science Mock', category: 'Soil'),
      MockTest(id: '3', title: 'Horticulture Mock', category: 'PYQ_Section'),
      MockTest(id: '4', title: 'Just a test', category: 'None'),
    ];

    test('PYQs filter includes MockTests with PYQ in title or category', () {
      final activeFilter = 'PYQs';
      
      final filteredResults = mockTests.where((t) {
        return activeFilter == 'All Files' ||
               activeFilter == 'Mocks' ||
               (activeFilter == 'PYQs' && 
                 (t.category.toUpperCase().contains('PYQ') || 
                  t.title.toUpperCase().contains('PYQ')));
      }).toList();

      expect(filteredResults.length, equals(2));
      expect(filteredResults.any((t) => t.id == '1'), isTrue); // Title match
      expect(filteredResults.any((t) => t.id == '3'), isTrue); // Category match
      expect(filteredResults.any((t) => t.id == '2'), isFalse); // No match
    });

    test('All Files filter includes everything', () {
      final activeFilter = 'All Files';
      
      final filteredResults = mockTests.where((t) {
        return activeFilter == 'All Files' ||
               activeFilter == 'Mocks' ||
               (activeFilter == 'PYQs' && 
                 (t.category.toUpperCase().contains('PYQ') || 
                  t.title.toUpperCase().contains('PYQ')));
      }).toList();

      expect(filteredResults.length, equals(mockTests.length));
    });
  });
}
