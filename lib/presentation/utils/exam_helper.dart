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

    // Check Shared Preferences first
    final prefs = await SharedPreferences.getInstance();
    final bool skipDialog = prefs.getBool('skip_exam_lang_dialog') ?? false;
    final String? storedLang = prefs.getString('default_exam_lang');

    // If preference is set and valid, verify profile matches or just use stored preference?
    // User requested "from there on pop up not show them". usage of profile language is secondary if this preference exists.
    // However, to be safe, let's just use the stored lang if skipDialog is true.
    if (skipDialog && storedLang != null && ['en', 'gu'].contains(storedLang)) {
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExamScreen(
            test: test,
            examLanguage: storedLang,
          ),
        ),
      );
      return;
    }

    String? selectedLanguage;

    // 1. Pre-fetch language from Profile (Fallback logic)
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select('language')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null && data['language'] != null) {
        selectedLanguage = data['language'];
      }
    } catch (e) {}

    bool dontAskAgain = false;

    // Default to 'en' if nothing found (will be overwritten by dialog choice)
    String tempLanguage = selectedLanguage ?? 'en';

    // Helper to run setState in dialog
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false, // Force choice or cancel
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
                      )),
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
                    Navigator.pop(context); // Close dialog
                    tempLanguage = ''; // Mark as cancelled
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close and proceed
                  },
                  child: const Text("Start Exam"),
                ),
              ],
            );
          },
        );
      },
    );

    if (tempLanguage.isEmpty) {
      return;
    }

    selectedLanguage = tempLanguage;

    // Update Preferences if "Don't Ask Again"
    if (dontAskAgain) {
      await prefs.setBool('skip_exam_lang_dialog', true);
      await prefs.setString('default_exam_lang', selectedLanguage);

      // Update Profile DB as well
      try {
        await Supabase.instance.client
            .from('users')
            .update({'language': selectedLanguage}).eq('id', user.id);
      } catch (e) {}
    }

    // 4. CHECK DOWNLOAD STATUS
    // Construct filename
    final String filename = 'mock_test_${test.id}.json';
    final downloadService = DownloadService();
    final bool isDownloaded = await downloadService.isFileDownloaded(filename);

    if (isDownloaded) {
      // START EXAM IMMEDIATELY
      final path = await downloadService.getLocalPath(filename);
      if (!context.mounted) return;
      _navigateToExam(context, test, selectedLanguage ?? 'en', File(path));
    } else {
      // PROMPT DOWNLOAD
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Download Required"),
          content: const Text(
              "You need to download the test content before starting. This ensures a smooth experience."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx); // Close prompt

                if (test.contentUrl == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Error: Download URL not found.")),
                  );
                  return;
                }

                // Start Download
                await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => DownloadProgressDialog(
                    url: test.contentUrl!,
                    filename: filename,
                    displayName: test.title, // Required param
                    onComplete: (path) {
                      // Corrected param name
                      // Auto-start exam on completion
                      _navigateToExam(
                          context, test, selectedLanguage ?? 'en', File(path));
                    },
                  ),
                );
              },
              child: const Text("Download & Start"),
            ),
          ],
        ),
      );
    }
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
