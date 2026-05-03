import 'package:excel/excel.dart';

/// A utility class to convert Excel files into JSON-compatible Lists.
class ExcelToJsonConverter {
  /// Converts Excel bytes to a JSON List based on specific Question format.
  /// Format:
  /// Col 0: Question No (ID)
  /// Col 1: Question Text
  /// Col 2 onwards: Options
  /// Last Column: Correct Answer (Text, Index 1-N, or Letter A-Z)
  static List<Map<String, dynamic>> convert(List<int> bytes) {
    try {
      var excel = Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) return [];

      // Use the first sheet
      var table = excel.tables[excel.tables.keys.first];
      if (table == null || table.rows.length < 2) return [];

      List<Map<String, dynamic>> questions = [];

      // Skip header row (index 0), start from 1
      for (int i = 1; i < table.rows.length; i++) {
        var row = table.rows[i];

        // Ensure row has minimum data (ID + Question + at least 1 option + Answer) => 4 cols minimal
        if (row.length < 4) continue;

        // 1. ID (Col 0)
        var idVal = row[0]?.value?.toString() ?? '';
        int id = int.tryParse(idVal) ?? idVal.hashCode;

        // 2. Question Text (Col 1)
        String text = row[1]?.value?.toString() ?? '';
        if (text.trim().isEmpty) continue;

        // 3. Extract Potential Options & Answer
        List<String> rawValues = [];
        for (int k = 2; k < row.length; k++) {
          var val = row[k]?.value?.toString().trim();
          if (val != null && val.isNotEmpty) {
            rawValues.add(val);
          }
        }

        if (rawValues.length < 2) continue;

        // Assume the LAST non-empty cell is the Correct Answer key
        String answerKey = rawValues.last;
        // All previous derived values are Options
        List<String> options = rawValues.sublist(0, rawValues.length - 1);

        String correctAnswerStr = '';

        // Logic to find Correct Answer Text from 'answerKey'
        int textMatch = options.indexWhere((opt) =>
            opt.trim().toLowerCase() == answerKey.trim().toLowerCase());
            
        if (textMatch != -1) {
          correctAnswerStr = options[textMatch];
        } else {
          int? numIndex = int.tryParse(answerKey);
          if (numIndex != null && numIndex > 0 && numIndex <= options.length) {
            correctAnswerStr = options[numIndex - 1];
          } else if (answerKey.length == 1) {
            int charCode = answerKey.toUpperCase().codeUnitAt(0);
            int derived = charCode - 65; // A=65
            if (derived >= 0 && derived < options.length) {
              correctAnswerStr = options[derived];
            }
          }
        }

        if (correctAnswerStr.isEmpty) {
          correctAnswerStr = answerKey;
        }

        // Build result map
        Map<String, dynamic> qMap = {
          'No.': id,
          'Question': text,
        };

        for (int optIdx = 0; optIdx < options.length; optIdx++) {
          String label = String.fromCharCode(65 + optIdx);
          qMap['Option $label'] = options[optIdx];
        }

        qMap['Correct Answer'] = correctAnswerStr;
        questions.add(qMap);
      }

      return questions;
    } catch (e) {
      print('ExcelToJsonConverter: Parsing failed: $e');
      return [];
    }
  }
}
