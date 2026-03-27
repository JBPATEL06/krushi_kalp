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
import '../../core/theme/app_spacing.dart'; // FIXED: Add import for AppSpacing
import '../../core/theme/app_radius.dart'; // FIXED: Add import for AppRadius

import 'package:krushi_kalp/presentation/screens/chat_screen.dart';

import '../widgets/common/network_error_state.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/app_config_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/error_utils.dart';
import '../../utils/crashlytics_service.dart';

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
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      _profileStream = AuthService.instance.streamUserProfile(user.id);
    }
  }

  Future<void> _ensureProfile(User user) async {
    try {
      await AuthService.instance.ensureProfileExists(user);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'profile_screen');
      // Profile creation errors are handled non-critically
    }
  }

  Future<void> _updateLanguage(String newLang) async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
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
        title: Text('Profile',
            style: TextStyle(fontSize: context.sp(20))), // FIXED
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, size: context.sp(24)), // FIXED
            tooltip: 'Edit Profile',
            onPressed: () async {
              final data = await AuthService.instance.getUserProfile(user!.id);
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
            icon: Icon(Icons.home, size: context.sp(28)), // FIXED
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
                  : 'Something went wrong.',
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
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md, // FIXED: AppSpacing.md
                AppSpacing.md, // FIXED: AppSpacing.md
                AppSpacing.md, // FIXED: AppSpacing.md
                AppSpacing.md + MediaQuery.of(context).padding.bottom, // FIXED
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: context.w(50), // FIXED
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? Icon(Icons.person, size: context.sp(50)) // FIXED
                        : null,
                  ),
                  SizedBox(height: AppSpacing.md), // FIXED: AppSpacing.md
                  Text(name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontSize: context.sp(24))), // FIXED
                  Text(
                    email,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.7), // FIXED
                        fontSize: context.sp(16)), // FIXED
                  ),
                  SizedBox(height: AppSpacing.xl), // FIXED: AppSpacing.xl

                  // Language Toggle
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm), // FIXED
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppRadius.lg), // FIXED
                      border: Border.all(
                          color: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.language,
                                color: theme.colorScheme.primary,
                                size: context.sp(24)), // FIXED
                            SizedBox(width: AppSpacing.sm), // FIXED
                            Text(
                              'Language',
                              style: TextStyle(
                                fontSize: context.sp(16), // FIXED
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
                                    style: TextStyle(
                                        fontSize: context.sp(14)))), // FIXED
                            DropdownMenuItem(
                                value: 'gu',
                                child: Text('Gujarati',
                                    style: TextStyle(
                                        fontSize: context.sp(14)))), // FIXED
                          ],
                          onChanged: (val) {
                            if (val != null) _updateLanguage(val);
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg), // FIXED

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

                  SizedBox(height: AppSpacing.lg), // FIXED

                  // About & Support Section
                  const Divider(),
                  Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                          horizontal: AppSpacing.xs), // FIXED
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text("About App",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: context.sp(14))), // FIXED
                      )),
                  _buildProfileOption(
                    context,
                    icon: Icons.info_outline,
                    title: 'About Krushi Kalp',
                    onTap: () => Navigator.pushNamed(context, '/about'),
                  ),
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

                  SizedBox(height: AppSpacing.xl), // FIXED
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
                      icon: Icon(Icons.logout, size: context.sp(20)), // FIXED
                      label: Text('Logout',
                          style: TextStyle(fontSize: context.sp(14))), // FIXED
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error),
                        padding: EdgeInsets.all(AppSpacing.md), // FIXED
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.md), // FIXED
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.md), // FIXED
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => _confirmDeleteAccount(context),
                      icon: Icon(Icons.delete_forever,
                          size: context.sp(20)), // FIXED
                      label: Text('Delete Account',
                          style: TextStyle(fontSize: context.sp(14))), // FIXED
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.6), // FIXED
                        padding: EdgeInsets.all(AppSpacing.md), // FIXED
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg), // FIXED
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
      leading: Icon(icon,
          color: theme.colorScheme.primary, size: context.sp(24)), // FIXED
      title: Text(title, style: TextStyle(fontSize: context.sp(16))), // FIXED
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(fontSize: context.sp(13))) // FIXED
          : null,
      trailing: Icon(Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant,
          size: context.sp(24)), // FIXED
      onTap: onTap,
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final theme = Theme.of(context);
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
            style:
                TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Show loading
        if (!context.mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );

        await ChatService.instance.sendMessage(
            "I need to delete account. Please process my request.");

        if (context.mounted) {
          Navigator.pop(context); // Pop loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deletion request sent to admin support.'),
              backgroundColor:
                  theme.colorScheme.primary, // Using primary for success
            ),
          );
        }
      } catch (e, stack) {
        CrashlyticsService.instance.recordError(e, stack, reason: 'profile_screen');
        if (context.mounted) {
          Navigator.pop(context); // Pop loading
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: context.sp(20), // FIXED
                    ),
              ),
              SizedBox(height: AppSpacing.lg), // FIXED
              ListTile(
                leading: Icon(Icons.email,
                    color: theme.colorScheme.primary,
                    size: context.sp(24)), // FIXED
                title: Text("Email Support",
                    style: TextStyle(fontSize: context.sp(16))), // FIXED
                onTap: () {
                  Navigator.pop(context);
                  final email = AppConfigService.email;
                  _launchUrl("mailto:$email");
                },
              ),
              ListTile(
                leading: Icon(Icons.send,
                    color: theme.colorScheme.tertiary,
                    size: context.sp(24)), // FIXED
                title: Text("Telegram",
                    style: TextStyle(fontSize: context.sp(16))), // FIXED
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
