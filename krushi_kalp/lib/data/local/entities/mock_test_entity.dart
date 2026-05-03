import 'package:isar_community/isar.dart';
import 'package:krushi_kalp/domain/models/mock_test.dart';

part 'mock_test_entity.g.dart';

@collection
class MockTestEntity {
  @Index(unique: true, replace: true)
  Id id = Isar.autoIncrement; // Will be overwritten by testId in fromMockTest

  int? testId;
  String? title;
  String? description;
  String? category;
  String? filePath;
  double? price;
  int? durationMinutes;
  int? totalQuestions;
  int? totalMarks;
  bool? negativeMarking;
  double? negativeMarksPerQ;
  String? language;

  String? coverImagePath;
  String? signedUrl;
  String? contentUrl;
  String? discount;
  double? mrp;
  DateTime? createdAt;

  // Convert from Domain Model
  static MockTestEntity fromMockTest(MockTest test) {
    return MockTestEntity()
      ..id = test.id
      ..testId = test.id
      ..title = test.title
      ..description = test.description
      ..category = test.category
      ..filePath = test.filePath
      ..price = test.price
      ..durationMinutes = test.durationMinutes
      ..totalQuestions = test.totalQuestions
      ..totalMarks = test.totalMarks
      ..negativeMarking = test.negativeMarking
      ..negativeMarksPerQ = test.negativeMarksPerQ
      ..language = test.language
      ..coverImagePath = test.coverImagePath
      ..signedUrl = test.signedUrl
      ..contentUrl = test.contentUrl
      ..discount = test.discount
      ..mrp = test.mrp
      ..createdAt = test.createdAt;
  }

  // Convert to Domain Model
  MockTest toMockTest() {
    return MockTest(
      id: testId ?? 0,
      title: title ?? '',
      description: description ?? '',
      category: category ?? '',
      filePath: filePath ?? '',
      price: price ?? 0.0,
      durationMinutes: durationMinutes,
      totalQuestions: totalQuestions ?? 0,
      totalMarks: totalMarks ?? 0,
      negativeMarking: negativeMarking ?? false,
      negativeMarksPerQ: negativeMarksPerQ ?? 0.0,
      language: language ?? 'English',
      coverImagePath: coverImagePath,
      signedUrl: signedUrl,
      contentUrl: contentUrl,
      discount: discount,
      mrp: mrp,
      createdAt: createdAt ?? DateTime.now(),
    );
  }
}
