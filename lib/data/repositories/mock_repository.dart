import '../../domain/models/mock_test.dart';
import '../../domain/models/question.dart';

class MockRepository {
  // Simulate submitting feedback
  Future<void> submitFeedback(dynamic feedback) async {
    // In a real app, this would send data to a backend
    // ignore: avoid_print
    print('Submitting Feedback: $feedback');
    await Future.delayed(const Duration(seconds: 1)); // Mimic network delay
  }

  List<MockTest> getMockTests() {
    return [
      MockTest(
        id: 1,
        title: 'Complete Flutter Bootcamp',
        description:
            'Learn Flutter from scratch with this comprehensive bootcamp.',
        category: 'Mobile Development',
        filePath: 'assets/tests/flutter_bootcamp.json',
        price: 99.99,
        durationMinutes: 120,
        totalQuestions: 50,
        totalMarks: 100,
        negativeMarking: true,
        negativeMarksPerQ: 0.25,
        language: 'English',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      MockTest(
        id: 2,
        title: 'Dart Masterclass',
        description: 'Deep dive into Dart programming language.',
        category: 'Programming Languages',
        filePath: 'assets/tests/dart_masterclass.json',
        price: 49.99,
        durationMinutes: 90,
        totalQuestions: 30,
        totalMarks: 60,
        negativeMarking: false,
        negativeMarksPerQ: 0.0,
        language: 'English',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      MockTest(
        id: 3,
        title: 'Clean Architecture',
        description: 'Master Clean Architecture patterns in Flutter.',
        category: 'Software Architecture',
        filePath: 'assets/tests/clean_arch.json',
        price: 79.99,
        durationMinutes: 150,
        totalQuestions: 40,
        totalMarks: 80,
        negativeMarking: true,
        negativeMarksPerQ: 0.5,
        language: 'Spanish',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      MockTest(
        id: 4,
        title: 'Advanced State Management',
        description: 'Explore Riverpod, Bloc, and Provider in depth.',
        category: 'State Management',
        filePath: 'assets/tests/state_mgmt.json',
        price: 59.99,
        durationMinutes: 60,
        totalQuestions: 35,
        totalMarks: 70,
        negativeMarking: true,
        negativeMarksPerQ: 0.25,
        language: 'English',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      MockTest(
        id: 5,
        title: 'Python for Data Science',
        description: 'Data Science basics using Python.',
        category: 'Data Science',
        filePath: 'assets/tests/python_ds.json',
        price: 89.99,
        durationMinutes: 180,
        totalQuestions: 75,
        totalMarks: 150,
        negativeMarking: false,
        negativeMarksPerQ: 0.0,
        language: 'English',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ];
  }

  List<Question> getQuestions(int testId) {
    // Return dummy questions
    return [
      Question(
        id: 1,
        text: 'What is Flutter?',
        options: [
          'A bird',
          'A UI Toolkit by Google',
          'A web framework',
          'A database',
        ],
        correctOptionIndex: 1,
      ),
      Question(
        id: 2,
        text: 'Which language is used by Flutter?',
        options: ['Java', 'Kotlin', 'Dart', 'Swift'],
        correctOptionIndex: 2,
      ),
      Question(
        id: 3,
        text: 'What is a Widget?',
        options: [
          'A small app',
          'A building block of UI',
          'A database table',
          'A function',
        ],
        correctOptionIndex: 1,
      ),
      Question(
        id: 4,
        text: 'StatefulWidget is immutable.',
        options: ['True', 'False'],
        correctOptionIndex: 1, // False
      ),
      Question(
        id: 5,
        text: 'How do you create a stateless widget?',
        options: [
          'Extend StatefulWidget',
          'Extend StatelessWidget',
          'Implement Widget',
          'None of the above',
        ],
        correctOptionIndex: 1,
      ),
    ];
  }
}
