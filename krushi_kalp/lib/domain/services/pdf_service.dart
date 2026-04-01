import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../../domain/models/question.dart';
import '../../utils/crashlytics_service.dart';

class PdfService {
  // Maintaining a public constructor for existing usage
  PdfService();
  
  static final PdfService instance = PdfService();

  /// Main method to generate a professional exam result PDF.
  Future<File> generateExamResultPdf({
    required String testId,
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
      author: 'Krushi Kalp',
      title: 'Exam Result - $testTitle',
      subject: 'Mock Test Result Analysis',
      keywords: 'krushi kalp, agriculture, mock test, result',
    );

    // Load Font based on language
    final font = await _loadFont(languageCode);

    // Define Colors
    const PdfColor primaryBlue = PdfColor.fromInt(0xFF3399FF);
    const PdfColor darkNavy = PdfColor.fromInt(0xFF13192B);
    const PdfColor lightGreen = PdfColor.fromInt(0xFFE8F5E9);
    const PdfColor green = PdfColor.fromInt(0xFF4CAF50);
    const PdfColor lightRed = PdfColor.fromInt(0xFFFFEBEE);
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
        'summary': 'પરિણામ સારાંશ',
        'score': 'કુલ સ્કોર',
        'pass': 'પાસ',
        'fail': 'નાપાસ',
        'passed_msg': 'તમે પરીક્ષા પાસ કરી છે!',
        'failed_msg': 'તમે નાપાસ થયા છો. પ્રયત્ન ચાલુ રાખો!',
        'right': 'સાચા',
        'wrong': 'ખોટા',
        'analysis': 'વિગતવાર વિશ્લેષણ',
        'question': 'પ્રશ્ન',
        'correct': 'સાચો',
        'selected': 'પસંદ કરેલ',
        'skipped': 'છોડી દીધેલ',
      }
    };

    final t = labels[languageCode] ?? labels['en']!;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        theme: pw.ThemeData.withFont(
            base: font,
            bold: font, 
            italic: font
            ),
        header: (pw.Context context) => _buildHeader(testTitle, userName, primaryBlue, white),
        footer: (pw.Context context) => _buildFooter(context, greyText),
        build: (pw.Context context) => [
          _buildSummarySection(
            score: score,
            totalMarks: totalMarks,
            correct: correctAnswers,
            wrong: wrongAnswers,
            skipped: skippedAnswers,
            primaryColor: primaryBlue,
            darkNavy: darkNavy,
            labels: t,
          ),
          if (questions != null) ...[
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              child: pw.Text(
                t['analysis']!,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: darkNavy,
                ),
              ),
            ),
            ...questions.asMap().entries.map((entry) {
              final index = entry.key;
              final q = entry.value;
              final selectedIdx = selectedAnswers?[index];
              return _buildQuestionItem(
                index + 1,
                q,
                selectedIdx,
                lightGreen,
                green,
                lightRed,
                red,
                labels: t,
              );
            }),
          ]
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/result_${testId}.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _buildHeader(String title, String user, PdfColor bg, PdfColor text) {
    return pw.Container(
      height: 100,
      padding: const pw.EdgeInsets.symmetric(horizontal: 30),
      decoration: pw.BoxDecoration(color: bg),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'KRUSHI KALP',
                style: pw.TextStyle(
                  color: text,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              pw.Text(
                title.toUpperCase(),
                style: pw.TextStyle(color: text, fontSize: 12),
              ),
            ],
          ),
          pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                user,
                style: pw.TextStyle(
                  color: text,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: pw.TextStyle(color: text, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context, PdfColor grey) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by Krushi Kalp App',
            style: pw.TextStyle(color: grey, fontSize: 8),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(color: grey, fontSize: 8),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummarySection({
    required double score,
    required double totalMarks,
    required int correct,
    required int wrong,
    required int skipped,
    required PdfColor primaryColor,
    required PdfColor darkNavy,
    required Map<String, String> labels,
  }) {
    final percentage = (score / totalMarks) * 100;
    final isPassed = percentage >= 40;

    return pw.Container(
      padding: const pw.EdgeInsets.all(30),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // Score Circle Representation
              pw.Container(
                width: 120,
                height: 120,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  border: pw.Border.all(color: primaryColor, width: 4),
                ),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      '${score.toInt()}',
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        color: darkNavy,
                      ),
                    ),
                    pw.Text(
                      '/${totalMarks.toInt()}',
                      style: pw.TextStyle(fontSize: 14, color: primaryColor),
                    ),
                  ],
                ),
              ),
              // Pass/Fail Badge
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: pw.BoxDecoration(
                      color: isPassed ? PdfColors.green : PdfColors.red,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
                    ),
                    child: pw.Text(
                      isPassed ? labels['pass']! : labels['fail']!,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    isPassed ? labels['passed_msg']! : labels['failed_msg']!,
                    style: pw.TextStyle(fontSize: 14, color: darkNavy),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 30),
          // Stats Row
          pw.Row(
            children: [
              _buildStatCard(labels['right']!, '$correct', PdfColors.green),
              pw.SizedBox(width: 15),
              _buildStatCard(labels['wrong']!, '$wrong', PdfColors.red),
              pw.SizedBox(width: 15),
              _buildStatCard(labels['skipped']!, '$skipped', PdfColors.orange),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStatCard(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(15),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color.luminance > 0.5 ? PdfColors.grey300 : color, width: 1),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
            pw.Text(
              label,
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildQuestionItem(
    int number,
    Question q,
    int? selectedIdx,
    PdfColor lightG,
    PdfColor darkG,
    PdfColor lightR,
    PdfColor darkR, {
    required Map<String, String> labels,
  }) {
    final String? selectedText = selectedIdx != null && selectedIdx < q.options.length 
        ? q.options[selectedIdx] 
        : null;
        
    final isCorrect = selectedText?.trim().toLowerCase() == q.correctAnswer.trim().toLowerCase();
    final isSkipped = selectedIdx == null;

    final cardBg = isSkipped
        ? PdfColors.grey100
        : (isCorrect ? lightG : lightR);

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(horizontal: 30, vertical: 8),
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: cardBg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '$number. ',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Expanded(
                child: pw.Text(
                  q.text,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '${labels['correct']}: ${q.correctAnswer}',
                      style: pw.TextStyle(color: darkG, fontSize: 10),
                    ),
                    if (!isSkipped)
                      pw.Text(
                        '${labels['selected']}: ${selectedText ?? ''}',
                        style: pw.TextStyle(
                          color: isCorrect ? darkG : darkR,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      )
                    else
                      pw.Text(
                        labels['skipped']!,
                        style: pw.TextStyle(color: PdfColors.orange, fontSize: 10),
                      ),
                  ],
                ),
              ),
              if (isSkipped)
                _buildStatusIcon(PdfColors.orange)
              else if (isCorrect)
                _buildStatusIcon(darkG)
              else
                _buildStatusIcon(darkR),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStatusIcon(PdfColor color) {
    return pw.Container(
      width: 12,
      height: 12,
      decoration: pw.BoxDecoration(
        color: color,
        shape: pw.BoxShape.circle,
      ),
    );
  }

  /// Loads the required font based on language.
  Future<pw.Font> _loadFont(String languageCode) async {
    // For English, use standard PDF fonts for better rendering and performance
    if (languageCode == 'en') {
      return pw.Font.helvetica();
    }

    try {
      // 1. Try Bundled Asset (Fastest & Offline)
      try {
        final fontData =
            await rootBundle.load("assets/fonts/NotoSansGujarati-Regular.ttf");
        return pw.Font.ttf(fontData);
      } catch (e, stack) {
        // Log if asset loading fails, will fall back to cache/download
        CrashlyticsService.instance.recordError(e, stack, reason: 'PdfService: Bundled font asset load failed');
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/NotoSansGujarati.ttf");

      // 2. Use Cache if available
      if (await file.exists()) {
        try {
          return pw.Font.ttf(
              await file.readAsBytes().then((b) => b.buffer.asByteData()));
        } catch (e, stack) {
          CrashlyticsService.instance.recordError(e, stack, reason: 'pdf_service');
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
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'PdfService: All font loading strategies failed');
    }
    // Fallback
    return pw.Font.helvetica();
  }

  Future<Uint8List> condenseStream(Stream<List<int>> stream) async {
    final List<int> allBytes = [];
    await for (final List<int> chunk in stream) {
      allBytes.addAll(chunk);
    }
    return Uint8List.fromList(allBytes);
  }

  String getSecurePassword(String userId, String testTitle) {
    // Deterministic password based on user and test
    return "${userId.substring(0, 4)}@${testTitle.length}";
  }
}
