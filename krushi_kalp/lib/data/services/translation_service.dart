import 'package:translator/translator.dart';
import '../../domain/models/question.dart';
import '../../utils/crashlytics_service.dart';

class TranslationService {
  static final _translator = GoogleTranslator();

  // Cache to prevent re-translating same questions
  // Key: LanguageCode_QuestionTextHash, Value: Translated Question
  static final Map<String, Question> _cache = {};

  /// Translates a single Question to a target language
  static Future<Question> translateQuestion(Question q, {String to = 'gu'}) async {
    // Return from cache if available
    final cacheKey = '${to}_${q.text.hashCode}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      // 1. Translate Question Text
      final textTranslation = await _translator.translate(q.text, to: to);

      // 2. Translate Options (in parallel)
      final optionsFutures =
          q.options.map((opt) => _translator.translate(opt, to: to)).toList();

      final optionsTranslations = await Future.wait(optionsFutures);

      // 3. Find original correct index to map to translated option
      final int originalCorrectIndex = q.options.indexWhere((opt) =>
          opt.trim().toLowerCase() ==
          q.correctAnswer.trim().toLowerCase());

      // 4. Create new Question object
      final translatedOptions =
          optionsTranslations.map((t) => t.text).toList();
      final translatedQ = Question(
        id: q.id, // Keep original ID
        text: textTranslation.text,
        options: translatedOptions,
        correctAnswer: originalCorrectIndex != -1
            ? translatedOptions[originalCorrectIndex]
            : q.correctAnswer,
      );

      // Save to cache
      _cache[cacheKey] = translatedQ;
      return translatedQ;
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'translation_service');
      // Fallback: Return original question if translation fails
      return q;
    }
  }

  /// Translates a batch of questions
  static Future<List<Question>> translateBatch(List<Question> questions, {String to = 'gu'}) async {
    const chunkSize = 5; // Translate 5 at a time
    final results = <Question>[];

    for (int i = 0; i < questions.length; i += chunkSize) {
      final chunk =
          questions.sublist(i, (i + chunkSize).clamp(0, questions.length));
      final translated =
          await Future.wait(chunk.map((q) => translateQuestion(q, to: to)));
      results.addAll(translated);

      // Small delay to avoid rate-limiting
      if (i + chunkSize < questions.length) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
    return results;
  }
}
