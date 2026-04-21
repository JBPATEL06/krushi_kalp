import 'package:flutter/material.dart';
import 'package:krushi_kalp/presentation/widgets/common/responsive_wrapper.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_notifier.dart';
import '../providers/navigation_notifier.dart';
import 'score_screen.dart';
import 'main_screen.dart';
import 'edit_profile_screen.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

import 'package:krushi_kalp/presentation/screens/chat_screen.dart';

import '../widgets/common/network_error_state.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/app_config_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/error_utils.dart';
import '../../utils/crashlytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<Map<String, dynamic>?>? _profileFuture;
  String? _selectedLanguage;
  String _pdfTheme = 'light';

  @override
  void initState() {
    super.initState();
    _loadPdfTheme();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadPdfTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _pdfTheme = prefs.getString('pdf_theme') ?? 'light';
        });
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'ProfileScreen: _loadPdfTheme');
    }
  }

  Future<void> _updatePdfTheme(String newTheme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pdf_theme', newTheme);
      if (mounted) {
        setState(() {
          _pdfTheme = newTheme;
        });
      }
    } catch (e, stack) {
       CrashlyticsService.instance.recordError(e, stack, reason: 'ProfileScreen: _updatePdfTheme');
    }
  }

  Future<void> _loadProfile() async {
    final user = ref.read(authNotifierProvider).user;
    if (user != null) {
      setState(() {
        _profileFuture = AuthService.instance.getUserProfile(user.id);
      });
    }
  }

  Future<void> _ensureProfile(User user) async {
    try {
      await AuthService.instance.ensureProfileExists(user);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'profile_screen');
    }
  }

  Future<void> _updateLanguage(String newLang) async {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;

    setState(() {
      _selectedLanguage = newLang;
    });

    try {
      await AuthService.instance.updateProfile(user.id, {'language': newLang});
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'profile_screen');
      if (mounted) {
        ErrorUtils.showError(context, e);
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
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'profile_screen');
      if (mounted) {
        ErrorUtils.showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authNotifierProvider).user;
    final meta = user?.userMetadata ?? {};
    final name = meta['full_name'] as String? ?? meta['name'] as String? ?? 'User';
    final email = user?.email ?? 'No Email';
    final avatarUrl = meta['avatar_url'] as String? ?? meta['picture'] as String?;
    
    // Check if Google is already linked
    final providers = user?.appMetadata?['providers'] as List? ?? [];
    final isGoogleLinked = providers.contains('google');

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(fontSize: context.sp(20))),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, size: context.sp(24)),
            tooltip: 'Edit Profile',
            onPressed: () async {
              if (user == null) return;
              final data = await AuthService.instance.getUserProfile(user.id);
              if (mounted && data != null) {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(profile: data),
                ),
              );
              if (result == true && mounted) {
                ref.read(authNotifierProvider.notifier).refreshProfile();
              }
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.home, size: context.sp(28)),
            onPressed: () {
              ref.read(navigationProvider.notifier).setIndex(0);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MainScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return NetworkErrorState(
              message: 'Unable to load profile.',
              onRetry: _loadProfile,
            );
          }

          final data = snapshot.data;
          if (data == null && !snapshot.hasError && user != null) {
            return Center(
              child: ElevatedButton(
                onPressed: () => _ensureProfile(user),
                child: const Text("Create Profile"),
              ),
            );
          }

          final language = _selectedLanguage ?? data?['language'] as String? ?? 'en';

          return RefreshIndicator(
            onRefresh: _loadProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: context.w(50),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null ? Icon(Icons.person, size: context.sp(50)) : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    data?['username'] as String? ?? name,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontSize: context.sp(24)),
                  ),
                  Text(
                    email,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: context.sp(16),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Language Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.language, color: theme.colorScheme.primary, size: context.sp(24)),
                            const SizedBox(width: AppSpacing.sm),
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
                            DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(fontSize: context.sp(14)))),
                            DropdownMenuItem(value: 'gu', child: Text('Gujarati', style: TextStyle(fontSize: context.sp(14)))),
                          ],
                          onChanged: (val) {
                            if (val != null) _updateLanguage(val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // PDF Theme Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.picture_as_pdf, color: theme.colorScheme.primary, size: context.sp(24)),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'PDF Default Theme',
                              style: TextStyle(
                                fontSize: context.sp(16),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        DropdownButton<String>(
                          value: _pdfTheme, // 'light' or 'dark'
                          underline: const SizedBox(),
                          items: [
                            DropdownMenuItem(value: 'light', child: Text('Light', style: TextStyle(fontSize: context.sp(14)))),
                            DropdownMenuItem(value: 'dark', child: Text('Dark', style: TextStyle(fontSize: context.sp(14)))),
                          ],
                          onChanged: (val) {
                            if (val != null) _updatePdfTheme(val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  _buildProfileOption(
                    context,
                    icon: Icons.emoji_events_outlined,
                    title: 'Score',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ScoreScreen()),
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
                        MaterialPageRoute(builder: (context) => const ChatScreen()),
                      );
                    },
                  ),
                  
                  // Link Google Account
                  if (!isGoogleLinked)
                    _buildProfileOption(
                      context,
                      icon: Icons.link,
                      title: 'Link Google Account',
                      subtitle: 'Add Google login for easier access',
                      onTap: () async {
                        try {
                          await ref.read(authNotifierProvider.notifier).linkGoogle();
                          // Refresh the local profile and state to reflect the link
                          await _loadProfile();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Google account linked successfully!')),
                            );
                          }
                        } catch (e) {
                           if (mounted) ErrorUtils.showError(context, e);
                        }
                      },
                    ),

                  const SizedBox(height: AppSpacing.lg),

                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("About App", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.sp(14))),
                    ),
                  ),
                  _buildProfileOption(
                    context,
                    icon: Icons.info_outline,
                    title: 'About Krushi Kalp',
                    onTap: () => context.push('/about'),
                  ),
                  _buildProfileOption(
                    context,
                    icon: Icons.contact_support,
                    title: 'Contact Us',
                    onTap: () => _showContactOptions(context),
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

                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(authNotifierProvider.notifier).signOut();
                      },
                      icon: Icon(Icons.logout, size: context.sp(20)),
                      label: Text('Logout', style: TextStyle(fontSize: context.sp(14))),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => _confirmDeleteAccount(context),
                      icon: Icon(Icons.delete_forever, size: context.sp(20)),
                      label: Text('Delete Account', style: TextStyle(fontSize: context.sp(14))),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        padding: const EdgeInsets.all(AppSpacing.md),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
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
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary, size: context.sp(24)),
      title: Text(title, style: TextStyle(fontSize: context.sp(16))),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: context.sp(13))) : null,
      trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant, size: context.sp(24)),
      onTap: onTap,
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          "Your account and all associated data will be permanently deleted within 5 days of your request.\n\nA deletion form will open. Please submit it to confirm your request.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            child: const Text('Request Deletion'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Step 1: Notify admin via chat
        try {
          await ChatService.instance.sendMessage(
            'I want to delete my account. Please process my deletion request.',
          );
        } catch (_) {
          // Non-critical — form is the primary channel
        }

        // Step 2: Open the official Google Form (Play Store compliant)
        const deletionFormUrl = 'https://forms.gle/pkSXTMxaytKqwYYa6';
        final uri = Uri.parse(deletionFormUrl);
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          throw 'Could not open the deletion form. Please contact support.';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Request submitted. Please complete the form that just opened. Your account will be deleted within 5 days.',
              ),
              backgroundColor: theme.colorScheme.primary,
              duration: const Duration(seconds: 6),
            ),
          );
        }
      } catch (e, stack) {
        CrashlyticsService.instance.recordError(e, stack, reason: 'profile_screen_delete_account');
        if (mounted) {
          ErrorUtils.showError(context, e);
        }
      }
    }
  }

  void _showContactOptions(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Contact Us",
              style: theme.textTheme.titleLarge?.copyWith(fontSize: context.sp(20)),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: Icon(Icons.email, color: theme.colorScheme.primary, size: context.sp(24)),
              title: Text("Email Support", style: TextStyle(fontSize: context.sp(16))),
              onTap: () {
                Navigator.pop(context);
                final email = AppConfigService.email;
                _launchUrl("mailto:$email");
              },
            ),
            ListTile(
              leading: Icon(Icons.send, color: theme.colorScheme.tertiary, size: context.sp(24)),
              title: Text("Telegram", style: TextStyle(fontSize: context.sp(16))),
              onTap: () {
                Navigator.pop(context);
                final username = AppConfigService.telegramUsername.replaceAll('@', '');
                _launchUrl("https://t.me/$username");
              },
            ),
          ],
        ),
      ),
    );
  }
}
