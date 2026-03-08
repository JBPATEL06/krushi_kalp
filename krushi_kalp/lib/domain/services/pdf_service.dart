import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:convert';
import '../models/question.dart';

class PdfService {
  /// Generates a deterministic password for the PDF file based on the user ID and result ID.
  /// This allows the app to open it later without storing the password explicitly.
  String getSecurePassword(String userId, String testTitle) {
    // Combine inputs and a secret salt
    final String raw = '${userId}_${testTitle}_SECRET_SALT_2026';
    final bytes = utf8.encode(raw);
    final digest = sha256.convert(bytes);
    // Take first 8 chars of hex for simplicity, or more
    return digest.toString().substring(0, 8);
  }

  Future<File> generateExamResultPdf({
    required String testTitle,
    required double score,
    required double totalMarks,
    required int correctAnswers,
    required int wrongAnswers,
    required int skippedAnswers,
    required String userId,
    required String userName,
    List<Question>? questions,
    Map<int, int>? selectedAnswers,
    String languageCode = 'en',
  }) async {
    final pdf = pw.Document(
      version: PdfVersion.pdf_1_5,
      compress: true,
    );

    // Apply encryption to the underlying PdfDocument
    // FIXME: Encryption disabled temporarily due to API mismatch
    // Apply encryption to the underlying PdfDocument
    // Encryption disabled due to package version mismatch
    // pdf.document.encryption = PdfEncryptionRc4(
    //   userPassword: getSecurePassword(userId, testTitle),
    //   ownerPassword: getSecurePassword(userId, testTitle),
    // );

    // Load Font for Gujarati Support
    final font = await _loadFont();

    // Define Colors
    const PdfColor primaryBlue = PdfColor.fromInt(0xFF3399FF);
    const PdfColor darkNavy = PdfColor.fromInt(0xFF13192B);
    const PdfColor lightGreen = PdfColor.fromInt(0xFFE8F5E9); // Green[50]
    const PdfColor green = PdfColor.fromInt(0xFF4CAF50);
    const PdfColor lightRed = PdfColor.fromInt(0xFFFFEBEE); // Red[50]
    const PdfColor red = PdfColor.fromInt(0xFFF44336);
    const PdfColor white = PdfColors.white;
    const PdfColor greyText = PdfColor.fromInt(0xFF616161);

    // Labels Map
    final Map<String, Map<String, String>> labels = {
      'en': {
        'summary': 'RESULTS SUMMARY',
        'score': 'TOTAL SCORE',
        'pass': 'PASS',
        'fail': 'FAIL',
        'passed_msg': 'You passed the test!',
        'failed_msg': 'You failed. Keep Practicing!',
        'right': 'RIGHT',
        'wrong': 'WRONG',
        'analysis': 'Detailed Analysis',
        'question': 'Question',
        'correct': 'Correct',
        'selected': 'Selected',
        'skipped': 'Skipped',
      },
      'gu': {
        'summary': 'àªªàª°àª¿àª£àª¾àª® àª¸àª¾àª°àª¾àª‚àª¶',
        'score': 'àª•à«àª² àª¸à«àª•à«‹àª°',
        'pass': 'àªªàª¾àª¸',
        'fail': 'àª¨àª¾àªªàª¾àª¸',
        'passed_msg': 'àª¤àª®à«‡ àªªàª°à«€àª•à«àª·àª¾ àªªàª¾àª¸ àª•àª°à«€ àª›à«‡!',
        'failed_msg': 'àª¤àª®à«‡ àª¨àª¾àªªàª¾àª¸ àª¥àª¯àª¾ àª›à«‹. àªªà«àª°àª¯àª¤à«àª¨ àªšàª¾àª²à« àª°àª¾àª–à«‹!',
        'right': 'àª¸àª¾àªšàª¾',
        'wrong': 'àª–à«‹àªŸàª¾',
        'analysis': 'àªµàª¿àª—àª¤àªµàª¾àª° àªµàª¿àª¶à«àª²à«‡àª·àª£',
        'question': 'àªªà«àª°àª¶à«àª¨',
        'correct': 'àª¸àª¾àªšà«‹',
        'selected': 'àªªàª¸àª‚àª¦ àª•àª°à«‡àª²',
        'skipped': 'àª›à«‹àª¡à«€ àª¦à«€àª§à«‡àª²',
      }
    };

    final t = labels[languageCode] ?? labels['en']!;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        theme: pw.ThemeData.withFont(
            base: font,
            bold: font, // Use same font for bold to ensure Gujarati renders
            italic: font // Use same font for italic
            ),
        build: (pw.Context context) {
          return [
            // --- HEADER & SCORE CARD ---
            pw.Container(
              padding: const pw.EdgeInsets.all(24),
              color: white,
              child: pw.Column(
                children: [
                  pw.Center(
                    child: pw.Text(
                      t['summary']!,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: darkNavy,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('$userName | $testTitle',
                      style: const pw.TextStyle(
                          fontSize: 12, color: PdfColors.grey)),
                  pw.SizedBox(height: 20),

                  // Blue Score Card
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 32, horizontal: 24),
                    decoration: pw.BoxDecoration(
                      color: primaryBlue,
                      borderRadius: pw.BorderRadius.circular(24),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          t['score']!,
                          style: pw.TextStyle(
                            color: white,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 1.2,
                            fontSize: 12,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Container(
                          width: 60,
                          height: 60,
                          decoration: const pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            color: PdfColors.white,
                          ),
                          child: pw.Center(
                            child: pw.Text(
                              ((score / totalMarks) * 100) >= 40
                                  ? t['pass']!
                                  : t['fail']!,
                              style: pw.TextStyle(
                                color: primaryBlue,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          '${((score / totalMarks) * 100).toStringAsFixed(0)}%',
                          style: pw.TextStyle(
                            fontSize: 50,
                            fontWeight: pw.FontWeight.bold,
                            color: white,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          ((score / totalMarks) * 100) >= 40
                              ? t['passed_msg']!
                              : t['failed_msg']!,
                          style: const pw.TextStyle(
                            color: white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- STATS GRID ---
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 24),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: _buildStatCardPdf(
                      label: t['right']!,
                      value: '$correctAnswers',
                      color: green,
                      bgColor: lightGreen,
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: _buildStatCardPdf(
                      label: t['wrong']!,
                      value: '$wrongAnswers',
                      color: red,
                      bgColor: lightRed,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 30),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 24),
              child: pw.Text(t['analysis']!,
                  style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: darkNavy)),
            ),
            pw.SizedBox(height: 15),

            // --- QUESTIONS LIST ---
            if (questions != null && selectedAnswers != null)
              ...List.generate(questions.length, (index) {
                final q = questions[index];
                final selectedOption = selectedAnswers[index];
                // CHANGED: Use string-based comparison instead of index
                final bool isCorrect = selectedOption != null &&
                    q.options[selectedOption].trim().toLowerCase() ==
                        q.correctAnswer.trim().toLowerCase(); // CHANGED
                final isSkipped = selectedOption == null;

                return pw.Container(
                  margin:
                      const pw.EdgeInsets.only(bottom: 16, left: 24, right: 24),
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: white,
                    borderRadius: pw.BorderRadius.circular(12),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Header: Icon + Question No
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 24,
                            height: 24,
                            decoration: pw.BoxDecoration(
                              color: isSkipped
                                  ? PdfColors.grey400
                                  : (isCorrect ? green : red),
                              shape: pw.BoxShape.circle,
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                isSkipped ? '-' : (isCorrect ? 'C' : 'W'),
                                style: pw.TextStyle(
                                    color: white,
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 10),
                          pw.Text(
                            '${t['question']} ${index + 1}',
                            style: pw.TextStyle(
                              color: greyText,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(q.text,
                          style: pw.TextStyle(
                              font: font, // Force use of Gujarati font
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: darkNavy)),
                      pw.SizedBox(height: 12),

                      // Options
                      ...List.generate(q.options.length, (optIndex) {
                        final isSelected = selectedOption == optIndex;
                        // CHANGED: Use string-based comparison instead of index
                        final isRealAnswer =
                            q.options[optIndex].trim().toLowerCase() ==
                                q.correctAnswer.trim().toLowerCase(); // CHANGED

                        PdfColor boxColor = white;
                        PdfColor borderColor = PdfColors.grey300;
                        PdfColor textColor = darkNavy;
                        double width = 0.5;

                        if (isRealAnswer) {
                          borderColor = green;
                          boxColor = lightGreen;
                          width = 1;
                        } else if (isSelected && !isRealAnswer) {
                          borderColor = red;
                          boxColor = lightRed;
                          width = 1;
                        }

                        return pw.Container(
                          margin: const pw.EdgeInsets.only(bottom: 6),
                          padding: const pw.EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          decoration: pw.BoxDecoration(
                            color: boxColor,
                            border:
                                pw.Border.all(color: borderColor, width: width),
                            borderRadius: pw.BorderRadius.circular(8),
                          ),
                          child: pw.Row(children: [
                            pw.Expanded(
                                child: pw.Text(q.options[optIndex],
                                    style: pw.TextStyle(
                                        color: textColor, fontSize: 10))),
                            if (isRealAnswer)
                              pw.Text(" (${t['correct']})",
                                  style:
                                      pw.TextStyle(color: green, fontSize: 8)),
                            if (isSelected && !isRealAnswer)
                              pw.Text(" (${t['selected']})",
                                  style: pw.TextStyle(color: red, fontSize: 8)),
                          ]),
                        );
                      }),
                      if (isSkipped)
                        pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 4),
                            child: pw.Text(t['skipped']!,
                                style: pw.TextStyle(
                                    color: PdfColors.orange,
                                    fontStyle: pw.FontStyle.italic,
                                    fontSize: 10))),
                    ],
                  ),
                );
              }),
            pw.SizedBox(height: 30),
            pw.Center(
                child: pw.Text("End of Report",
                    style: const pw.TextStyle(
                        color: PdfColors.grey, fontSize: 10))),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
        "${output.path}/result_${DateTime.now().millisecondsSinceEpoch}.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _buildStatCardPdf({
    required String label,
    required String value,
    required PdfColor color,
    required PdfColor bgColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 20),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(16),
        border: pw.Border.all(color: color, width: 0.5),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Container(
                  width: 8,
                  height: 8,
                  decoration: pw.BoxDecoration(
                      color: color, shape: pw.BoxShape.circle)),
              pw.SizedBox(width: 8),
              pw.Text(
                label,
                style: pw.TextStyle(
                  color: color,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF13192B),
            ),
          ),
        ],
      ),
    );
  }

  /// Loads the required font.
  Future<pw.Font> _loadFont() async {
    try {
      // 1. Try Bundled Asset (Fastest & Offline)
      // This is now "provided by default" in pubspec.yaml
      try {
        final fontData =
            await rootBundle.load("assets/fonts/NotoSansGujarati-Regular.ttf");
        return pw.Font.ttf(fontData);
      } catch (e) {}

      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/NotoSansGujarati.ttf");

      // 2. Use Cache if available
      if (await file.exists()) {
        try {
          return pw.Font.ttf(
              await file.readAsBytes().then((b) => b.buffer.asByteData()));
        } catch (e) {
          await file.delete();
        }
      }

      // 3. Download from JSDelivr (Reliable Source)
      final url = Uri.parse(
          "https://cdn.jsdelivr.net/npm/@expo-google-fonts/noto-sans-gujarati@0.2.3/NotoSansGujarati_400Regular.ttf");

      final client = HttpClient()
        ..badCertificateCallback = (cert, host, port) => true;

      final request = await client.getUrl(url);
      final response = await request.close();

      if (response.statusCode == 200) {
        final bytes = await condenseStream(response);
        await file.writeAsBytes(bytes);
        return pw.Font.ttf(bytes.buffer.asByteData());
      }
    } catch (e) {}
    // Fallback
    return pw.Font.courier();
  }

  Future<Uint8List> condenseStream(Stream<List<int>> stream) async {
    final List<int> bytes = [];
    await for (final chunk in stream) {
      bytes.addAll(chunk);
    }
    return Uint8List.fromList(bytes);
  }
}
