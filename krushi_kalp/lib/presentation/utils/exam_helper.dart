import 'dart:io'; // NEW
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/download_service.dart'; // NEW
import '../../domain/models/mock_test.dart';
import '../screens/exam_screen.dart';
import '../widgets/common/download_progress_dialog.dart'; // NEW

class ExamHelper {
  static Future<void> startExam(BuildContext context, MockTest test) async {
    final user = AuthService().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to start the exam")),
      );
      return;
    }

    final String filename = 'mock_test_${test.id}.json';
    final downloadService = DownloadService();
    final bool isDownloaded =
        await downloadService.isFileDownloaded(filename, userId: user.id);

    if (!isDownloaded) {
      // ── File not on device: download first, then ask language ──
      if (test.contentUrl == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error: Download URL not found.")),
          );
        }
        return;
      }

      if (!context.mounted) return;
      // Capture outer context before entering dialog builder
      final outerContext = context;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => DownloadProgressDialog(
          url: test.contentUrl!,
          filename: filename,
          displayName: test.title,
          userId: user.id,
          onComplete: (path) async {
            // Use outer context — dialog ctx is stale after dialog pops itself
            if (!outerContext.mounted) return;
            final lang = await _askLanguage(outerContext, user.id);
            if (lang == null) return; // user cancelled
            if (!outerContext.mounted) return;
            _navigateToExam(outerContext, test, lang, File(path));
          },
        ),
      );
      return;
    }

    // ── File already on device: ask language, then start ──
    if (!context.mounted) return;
    final lang = await _askLanguage(context, user.id);
    if (lang == null) return; // user cancelled

    final path = await downloadService.getLocalPath(filename, userId: user.id);
    if (!context.mounted) return;
    _navigateToExam(context, test, lang, File(path));
  }

  /// Shows the language selection dialog.
  /// Returns the chosen language code ('en' or 'gu'), or null if cancelled.
  static Future<String?> _askLanguage(
      BuildContext context, String userId) async {
    // Check SharedPreferences for saved preference
    final prefs = await SharedPreferences.getInstance();
    final bool skipDialog = prefs.getBool('skip_exam_lang_dialog') ?? false;
    final String? storedLang = prefs.getString('default_exam_lang');

    if (skipDialog && storedLang != null && ['en', 'gu'].contains(storedLang)) {
      return storedLang;
    }

    // Pre-fetch language from profile as default
    String tempLanguage = 'en';
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select('language')
          .eq('id', userId)
          .maybeSingle();
      if (data != null && data['language'] != null) {
        tempLanguage = data['language'];
      }
    } catch (_) {}

    if (!context.mounted) return null;

    bool dontAskAgain = false;
    String? selectedLanguage;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Select Exam Language"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8)),
                    child: const Text(
                      "The exam content will be translated based on your selection.",
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    title: const Text("English"),
                    leading: Radio<String>(
                      value: 'en',
                      groupValue: tempLanguage,
                      onChanged: (val) => setState(() => tempLanguage = val!),
                    ),
                  ),
                  ListTile(
                    title: const Text("Gujarati"),
                    leading: Radio<String>(
                      value: 'gu',
                      groupValue: tempLanguage,
                      onChanged: (val) => setState(() => tempLanguage = val!),
                    ),
                  ),
                  const Divider(),
                  CheckboxListTile(
                    title: const Text("Don't ask me again"),
                    subtitle: const Text("Updates your profile preference"),
                    value: dontAskAgain,
                    onChanged: (val) =>
                        setState(() => dontAskAgain = val ?? false),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                        context); // cancelled — selectedLanguage stays null
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    selectedLanguage = tempLanguage;
                    Navigator.pop(context);
                  },
                  child: const Text("Start Exam"),
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedLanguage != null && dontAskAgain) {
      await prefs.setBool('skip_exam_lang_dialog', true);
      await prefs.setString('default_exam_lang', selectedLanguage!);
      try {
        await Supabase.instance.client
            .from('users')
            .update({'language': selectedLanguage}).eq('id', userId);
      } catch (_) {}
    }

    return selectedLanguage;
  }

  static void _navigateToExam(
      BuildContext context, MockTest test, String language, File localFile) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ExamScreen(
          test: test,
          examLanguage: language,
          localFile: localFile,
        ),
      ),
    );
  }
}
