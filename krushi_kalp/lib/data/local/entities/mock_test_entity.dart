import 'package:isar/isar.dart';
import 'package:krushi_kalp/domain/models/mock_test.dart';

part 'mock_test_entity.g.dart';

@collection
class MockTestEntity {
  Id id = Isar.autoIncrement;

  late int testId;
  late String title;
  late String description;
  late String category;
  late String filePath;
  late double price;
  int? durationMinutes;
  late int totalQuestions;
  late int totalMarks;
  late bool negativeMarking;
  late double negativeMarksPerQ;
  late String language;

  String? coverImagePath;
  String? signedUrl;
  String? contentUrl;
  String? discount;
  double? mrp;
  late DateTime createdAt;

  // Convert from Domain Model
  static MockTestEntity fromMockTest(MockTest test) {
    return MockTestEntity()
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
      id: testId,
      title: title,
      description: description,
      category: category,
      filePath: filePath,
      price: price,
      durationMinutes: durationMinutes,
      totalQuestions: totalQuestions,
      totalMarks: totalMarks,
      negativeMarking: negativeMarking,
      negativeMarksPerQ: negativeMarksPerQ,
      language: language,
      coverImagePath: coverImagePath,
      signedUrl: signedUrl,
      contentUrl: contentUrl,
      discount: discount,
      mrp: mrp,
      createdAt: createdAt,
    );
  }
}
