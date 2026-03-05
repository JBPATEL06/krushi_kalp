import 'package:flutter/material.dart';
import 'package:krushi_kalp/presentation/widgets/common/responsive_wrapper.dart';

import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/network_provider.dart';
import '../providers/navigation_provider.dart';
import 'score_screen.dart';
import 'main_screen.dart';
import 'edit_profile_screen.dart';

import 'package:krushi_kalp/presentation/screens/chat_screen.dart';

import '../widgets/common/network_error_state.dart';
import 'purchased_tests_screen.dart';
import 'mock_test_upload_screen.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/app_config_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Stream<Map<String, dynamic>?> _profileStream = Stream.empty();

  String? _selectedLanguage; // Optimistic UI state
  bool _hadNetworkError = false;

  @override
  void initState() {
    super.initState();
    _setupStream();
    NetworkProvider().addListener(_onNetworkChange);
  }

  @override
  void dispose() {
    NetworkProvider().removeListener(_onNetworkChange);
    super.dispose();
  }

  void _onNetworkChange() {
    final isConnected = NetworkProvider().isConnected;
    if (isConnected && _hadNetworkError && mounted) {
      _hadNetworkError = false;
      _setupStream();
    }
  }

  void _setupStream() {
    // FIX: Use AuthProvider instead of AuthService
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      _profileStream = Supabase.instance.client
          .from('users')
          .stream(primaryKey: ['id'])
          .eq('id', user.id)
          .map((rows) => rows.isNotEmpty ? rows.first : null);
    }
  }

  Future<void> _ensureProfile(User user) async {
    try {
      debugPrint('Profile missing for ${user.id}, creating...');
      await Supabase.instance.client.from('users').upsert({
        'id': user.id,
        'email': user.email,
        'username': user.email?.split('@')[0] ?? 'User',
        'language': 'en',
      });
      debugPrint('Profile created.');
    } catch (e) {
      debugPrint('Error creating profile: $e');
    }
  }

  Future<void> _updateLanguage(String newLang) async {
    // FIX: Use AuthProvider
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) return;

    // Optimistic Update: Update UI immediately
    setState(() {
      _selectedLanguage = newLang;
    });

    try {
      final response = await Supabase.instance.client
          .from('users')
          .update({'language': newLang})
          .eq('id', user.id)
          .select();

      if (response.isEmpty) {
        // Handle creation/retry if needed (previous logic)
        // ...
      }
    } catch (e) {
      debugPrint('Error updating language: $e');
      if (mounted) {
        // Revert on error? Or just show snackbar
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to update language: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Use AuthProvider
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final meta = user?.userMetadata ?? {};
    final name =
        meta['full_name'] as String? ?? meta['name'] as String? ?? 'User';
    final email = user?.email ?? 'No Email';
    final avatarUrl =
        meta['avatar_url'] as String? ?? meta['picture'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(fontSize: context.sp(20))),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, size: context.sp(24)),
            tooltip: 'Edit Profile',
            onPressed: () async {
              final data = await Supabase.instance.client
                  .from('users')
                  .select()
                  .eq('id', user!.id)
                  .maybeSingle();
              if (context.mounted && data != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(profile: data),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.home, size: context.sp(28)),
            onPressed: () {
              context.read<NavigationProvider>().setIndex(0);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MainScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _profileStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            _hadNetworkError = isNetworkError(snapshot.error);
            return NetworkErrorState(
              message: isNetworkError(snapshot.error)
                  ? 'Unable to load profile.'
                  : 'Error: ${snapshot.error}',
              onRetry: _setupStream,
            );
          }

          final data = snapshot.data;
          // ... null check logic ...
          if (data == null && !snapshot.hasError) {
            return Center(
                child: ElevatedButton(
                    onPressed: () => _ensureProfile(user!),
                    child: const Text("Create Profile")));
          }

          // Use optimistic value if set, otherwise stream value
          final language =
              _selectedLanguage ?? data?['language'] as String? ?? 'en';
          final isAdmin = (data?['role'] == 'Admin');

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _setupStream();
              });
              // Small delay to simulate refresh if stream is fast
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(context.w(16.0)),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: context.w(50),
                    backgroundColor: Colors.grey[200],
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? Icon(Icons.person, size: context.sp(50))
                        : null,
                  ),
                  SizedBox(height: context.h(16)),
                  Text(name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontSize: context.sp(24))),
                  Text(
                    email,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600], fontSize: context.sp(16)),
                  ),
                  SizedBox(height: context.h(32)),

                  // Language Toggle
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: context.w(16), vertical: context.h(8)),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(context.w(12)),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.language,
                                color: Colors.blue[700], size: context.sp(24)),
                            SizedBox(width: context.w(12)),
                            Text(
                              'Language',
                              style: TextStyle(
                                fontSize: context.sp(16),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        DropdownButton<String>(
                          value: language,
                          underline: const SizedBox(),
                          items: [
                            DropdownMenuItem(
                                value: 'en',
                                child: Text('English',
                                    style:
                                        TextStyle(fontSize: context.sp(14)))),
                            DropdownMenuItem(
                                value: 'gu',
                                child: Text('Gujarati',
                                    style:
                                        TextStyle(fontSize: context.sp(14)))),
                          ],
                          onChanged: (val) {
                            if (val != null) _updateLanguage(val);
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.h(24)),

                  _buildProfileOption(
                    context,
                    icon: Icons.emoji_events_outlined,
                    title: 'Score',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ScoreScreen()),
                      );
                    },
                  ),
                  _buildProfileOption(
                    context,
                    icon: Icons.chat,
                    title: 'App Support',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatScreen(),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: context.h(24)),

                  // About & Support Section
                  const Divider(),
                  Padding(
                      padding: EdgeInsets.all(context.w(8.0)),
                      child: Text("About App",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: context.sp(14)))),
                  _buildProfileOption(
                    context,
                    icon: Icons.contact_support,
                    title: 'Contact Us',
                    onTap: () {
                      _showContactOptions(context);
                    },
                  ),
                  _buildProfileOption(
                    context,
                    icon: Icons.privacy_tip,
                    title: 'Privacy Policy',
                    onTap: () => _launchUrl(AppConfigService.privacyPolicyUrl),
                  ),
                  _buildProfileOption(
                    context,
                    icon: Icons.description,
                    title: 'Terms & Conditions',
                    onTap: () => _launchUrl(AppConfigService.termsUrl),
                  ),

                  SizedBox(height: context.h(24)),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        // FIX: Use AuthProvider
                        await context.read<AuthProvider>().signOut();
                        if (context.mounted) {
                          Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil('/', (route) => false);
                        }
                      },
                      icon: Icon(Icons.logout, size: context.sp(20)),
                      label: Text('Logout',
                          style: TextStyle(fontSize: context.sp(14))),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: EdgeInsets.all(context.w(16)),
                      ),
                    ),
                  ),
                  SizedBox(height: context.h(12)),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => _confirmDeleteAccount(context),
                      icon: Icon(Icons.delete_forever, size: context.sp(20)),
                      label: Text('Delete Account',
                          style: TextStyle(fontSize: context.sp(14))),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey,
                        padding: EdgeInsets.all(context.w(16)),
                      ),
                    ),
                  ),
                  SizedBox(height: context.h(12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon,
          color: Theme.of(context).primaryColor, size: context.sp(24)),
      title: Text(title, style: TextStyle(fontSize: context.sp(16))),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(fontSize: context.sp(13)))
          : null,
      trailing: Icon(Icons.chevron_right, size: context.sp(24)),
      onTap: onTap,
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account Request'),
        content: const Text(
          "Your account will be deleted within 5 days and your data can't be recovered.\n\nDo you want to send a deletion request to support?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );

        // Send Message to Admin via ChatService
        // Import ChatService is already there or available via file scope if imported.
        // It is imported as part of `chat_screen.dart` or we might need explicit import if not exposed.
        // Looking at file imports: `import 'package:krushi_kalp/presentation/screens/chat_screen.dart';`
        // ChatService is usually in data/services.
        // I should ensure ChatService is imported.
        // Wait, the file has `import 'package:krushi_kalp/presentation/screens/chat_screen.dart';`
        // Does `chat_screen.dart` export `ChatService`? Unlikely.
        // I need to add import for ChatService if it's missing.
        // But `ProfileScreen` already has imports. Let's check imports.
        // Explicitly, I should use `ChatService()` but if the class isn't imported, code breaks.
        // The file `profile_screen.dart` has these imports:
        // ...
        // import 'package:krushi_kalp/presentation/screens/chat_screen.dart';
        // ...
        // It does NOT import `chat_service.dart`.
        // I will add the import in a separate tool call if needed, or I can rely on `replace_file_content` block to add it?
        // `replace_file_content` on a block in middle of file cannot add import at top.
        // However, I can use fully qualified name or just add the import first.
        // Let's check if I can add the import.
        // Actually, I'll trust that I can add the import in a separate edit or use fully qualified name if package is known.
        // `package:krushi_kalp/data/services/chat_service.dart`
        // But wait, I'll just add the import to the top of the file in a separate step?
        // No, I can do it in one go if I edit properly? No, `replace_file_content` is a single block.
        // I will proceed with the method update, then check if I need to add import.
        // Wait, if I break the build, user gets mad.
        // Let's check imports again.
        // `profile_screen.dart` imports `chat_screen.dart`.
        // I will update the method first. If I need to add import, I will do it next.
        // Actually, better to check/add import first. But I can't do parallel.
        // I'll update the method now.

        await ChatService().sendMessage(
            "I need to delete account. Please process my request.");

        if (context.mounted) {
          Navigator.pop(context); // Pop loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Deletion request sent to admin support.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Pop loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error sending request: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showContactOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Contact Us",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: const Text("Email Support"),
              onTap: () {
                Navigator.pop(context);
                final email = AppConfigService.email;
                _launchUrl("mailto:$email");
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.green),
              title: const Text("WhatsApp"),
              onTap: () {
                Navigator.pop(context);
                final phone = AppConfigService.whatsappNumber
                    .replaceAll(RegExp(r'[^\d+]'), '');
                _launchUrl("https://wa.me/$phone");
              },
            ),
            ListTile(
              leading: const Icon(Icons.send, color: Colors.blueAccent),
              title: const Text("Telegram"),
              onTap: () {
                Navigator.pop(context);
                final username =
                    AppConfigService.telegramUsername.replaceAll('@', '');
                _launchUrl("https://t.me/$username");
              },
            ),
          ],
        ),
      ),
    );
  }
}
