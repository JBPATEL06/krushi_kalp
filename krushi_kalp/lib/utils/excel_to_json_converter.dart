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
    var excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return [];

    // Use the first sheet
    var table = excel.tables[excel.tables.keys.first]!;
    // Need at least header + 1 row (or just 1 row if no header, but let's assume standard excel with header)
    if (table.rows.length < 2) return [];

    List<Map<String, dynamic>> questions = [];

    // Skip header row (index 0), start from 1
    for (int i = 1; i < table.rows.length; i++) {
      var row = table.rows[i];

      // Ensure row has minimum data (ID + Question + at least 1 option + Answer) => 4 cols minimal
      // If your file has fewer columns, we might need to adjust logic, but 4 is safe minimum.
      if (row.length < 4) continue;

      // 1. ID (Col 0)
      var idVal = row[0]?.value?.toString() ?? '';
      // Try parse int, or use hash code if alphanumeric
      int id = int.tryParse(idVal) ?? idVal.hashCode; // CHANGED

      // 2. Question Text (Col 1)
      String text = row[1]?.value?.toString() ?? ''; // CHANGED
      if (text.isEmpty) continue;

      // 3. Extract Potential Options & Answer
      // Collect valid strings from Col 2 onwards
      List<String> rawValues = []; // CHANGED
      for (int k = 2; k < row.length; k++) {
        var val = row[k]?.value?.toString().trim();
        if (val != null && val.isNotEmpty) {
          rawValues.add(val);
        }
      }

      if (rawValues.length < 2) {
        continue; // Need at least 1 option + 1 answer key
      }

      // Assume the LAST non-empty cell is the Correct Answer key
      String answerKey = rawValues.last; // CHANGED
      // All previous derived values are Options
      List<String> options =
          rawValues.sublist(0, rawValues.length - 1); // CHANGED

      String correctAnswerStr = ''; // CHANGED

      // Logic to find Correct Answer Text from 'answerKey'
      // A) Does it match the text of an option?
      int textMatch = options.indexWhere((opt) =>
          opt.trim().toLowerCase() ==
          answerKey.trim().toLowerCase()); // CHANGED
      if (textMatch != -1) {
        correctAnswerStr = options[textMatch]; // CHANGED
      } else {
        // B) Is it a number (1, 2, 3...)?
        int? numIndex = int.tryParse(answerKey); // CHANGED
        if (numIndex != null && numIndex > 0 && numIndex <= options.length) {
          correctAnswerStr = options[numIndex - 1]; // CHANGED
        } else {
          // C) Is it a letter (A, B, C...)?
          if (answerKey.length == 1) {
            int charCode = answerKey.toUpperCase().codeUnitAt(0); // CHANGED
            // 'A' is 65. So A->0, B->1
            int derived = charCode - 65; // CHANGED
            if (derived >= 0 && derived < options.length) {
              correctAnswerStr = options[derived]; // CHANGED
            }
          }
        }
      }

      // Fallback: If still empty, use the answerKey itself as the string
      if (correctAnswerStr.isEmpty) {
        correctAnswerStr = answerKey; // CHANGED
      }

      // Build tableConvert format JSON
      Map<String, dynamic> qMap = {
        'No.': id, // CHANGED
        'Question': text, // CHANGED
      };

      // Add options Option A, Option B, etc.
      for (int optIdx = 0; optIdx < options.length; optIdx++) {
        String label = String.fromCharCode(65 + optIdx); // A, B, C...
        qMap['Option $label'] = options[optIdx]; // CHANGED
      }

      qMap['Correct Answer'] = correctAnswerStr; // CHANGED

      questions.add(qMap); // CHANGED
    }

    return questions;
  }
}
