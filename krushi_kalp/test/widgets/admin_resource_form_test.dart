import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krushi_kalp/domain/models/resource.dart';
import 'package:krushi_kalp/presentation/screens/admin/resources/admin_resource_form.dart';
import 'package:krushi_kalp/data/services/resource_service.dart';
import 'package:mocktail/mocktail.dart';

class MockResourceService extends Mock implements ResourceService {}

void main() {
  late MockResourceService mockResourceService;

  setUp(() {
    mockResourceService = MockResourceService();
    
    // Register fallback for mocktail
    registerFallbackValue(ResourceType.eBook);
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(Resource(
      id: 0,
      title: '',
      description: '',
      type: ResourceType.eBook,
      category: '',
      fileUrl: '',
      thumbnailUrl: '',
      price: 0,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
        ],
      ),
      home: AdminResourceForm(
        resource: Resource(
          id: 1,
          title: 'Existing',
          description: 'Desc',
          type: ResourceType.eBook,
          category: 'Cat',
          fileUrl: 'url',
          thumbnailUrl: 'thumb',
          price: 10,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),

        type: ResourceType.eBook,
        resourceService: mockResourceService,
      ),
    );
  }

  group('AdminResourceForm Widget Tests', () {
    testWidgets('shows loading indicator when saving', (WidgetTester tester) async {
      // Mock File Upload
      when(() => mockResourceService.uploadFile(
            path: any(named: 'path'),
            fileBytes: any(named: 'fileBytes'),
            bucket: any(named: 'bucket'),
          )).thenAnswer((_) async => 'success_file_path');

      // Mock DB Creation/Update
      when(() => mockResourceService.createResource(any()))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 500));
        return 1;
      });
      when(() => mockResourceService.updateResource(any(), any()))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 500));
      });

      await tester.pumpWidget(createWidgetUnderTest());

      // We need to bypass the 'attach PDF' check by manually setting the state if possible,
      // or by simulating the file picker. For this test, let's just trigger the save
      // and verify the error or the loading state if we can get past the guard.
      
      // Since _fileBytes is private, we'd need to mock FilePicker or 
      // trigger the picker and mock its response.
      // For simplicity in this verification test, I'll just verify the initial state
      // and the fact that calling _save (if accessible) or clicking a button
      // triggers the expected UI change.

      await tester.pumpWidget(createWidgetUnderTest());

      // Fill form
      await tester.enterText(find.byType(TextFormField).at(0), 'Test Title');
      await tester.enterText(find.byType(TextFormField).at(1), 'Test Description');
      await tester.enterText(find.byType(TextFormField).at(2), 'Test Category');

      // Tap Save (All CAPS in the code)
      final saveButton = find.text('SAVE RESOURCE');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pump(); // Start animation

      // Should show CircularProgressIndicator and SAVING... text
      expect(find.byType(CircularProgressIndicator), findsAtLeast(1));
      expect(find.text('SAVING...'), findsOneWidget);

      await tester.pumpAndSettle(); // Wait for finish
      
      // Should result in screen pop or success state
      // (Depending on how the logic is implemented in the screen)
    });
  });
}
