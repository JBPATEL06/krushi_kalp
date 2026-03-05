import 'package:translator/translator.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/question.dart';

class TranslationService {
  static final _translator = GoogleTranslator();

  // Cache to prevent re-translating same questions
  // Key: Question ID (or index if no ID), Value: Translated Question
  static final Map<String, Question> _cache = {};

  /// Translates a single Question to Gujarati
  static Future<Question> translateQuestion(Question q) async {
    // Return from cache if available
    // We use the question text hash or a unique ID if available as key
    final cacheKey = q.text.hashCode.toString();
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      // 1. Translate Question Text
      final textTranslation = await _translator.translate(q.text, to: 'gu');

      // 2. Translate Options (in parallel)
      final optionsFutures =
          q.options.map((opt) => _translator.translate(opt, to: 'gu')).toList();

      final optionsTranslations = await Future.wait(optionsFutures);

      // 3. Create new Question object
      final translatedQ = Question(
        id: q.id, // Keep original ID
        text: textTranslation.text,
        options: optionsTranslations.map((t) => t.text).toList(),
        correctOptionIndex: q.correctOptionIndex,
      );

      // Save to cache
      _cache[cacheKey] = translatedQ;
      return translatedQ;
    } catch (e) {
      debugPrint('Translation Error: $e');
      // Fallback: Return original question if translation fails
      return q;
    }
  }

  /// Translates a batch of questions (Fire and Forget or Wait)
  static Future<List<Question>> translateBatch(List<Question> questions) async {
    final futures = questions.map((q) => translateQuestion(q));
    return Future.wait(futures);
  }
}
