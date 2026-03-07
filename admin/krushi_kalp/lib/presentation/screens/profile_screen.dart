import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/network_provider.dart';
import 'score_screen.dart';
import 'package:krushi_kalp_admin/presentation/screens/chat_screen.dart';
import '../widgets/common/network_error_state.dart';
import 'purchased_tests_screen.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/app_config_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Stream<Map<String, dynamic>?> _profileStream = Stream.empty();
  String? _selectedLanguage;
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
      _profileStream = Supabase.instance.client
          .from('users')
          .stream(primaryKey: ['id'])
          .eq('id', user.id)
          .map((rows) => rows.isNotEmpty ? rows.first : null);
    }
  }

  Future<void> _ensureProfile(User user) async {
    try {
      await Supabase.instance.client.from('users').upsert({
        'id': user.id,
        'email': user.email,
        'username': user.email?.split('@')[0] ?? 'User',
        'language': 'en',
      });
    } catch (e) {
      debugPrint('Error creating profile: $e');
    }
  }

  Future<void> _updateLanguage(String newLang) async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) return;

    setState(() {
      _selectedLanguage = newLang;
    });

    try {
      await Supabase.instance.client
          .from('users')
          .update({'language': newLang}).eq('id', user.id);
    } catch (e) {
      debugPrint('Error updating language: $e');
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update language: $e'),
            backgroundColor: colorScheme.error,
          ),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final meta = user?.userMetadata ?? {};
    final name =
        meta['full_name'] as String? ?? meta['name'] as String? ?? 'User';
    final email = user?.email ?? 'No Email';
    final avatarUrl =
        meta['avatar_url'] as String? ?? meta['picture'] as String?;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        shape: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
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
          if (data == null && !snapshot.hasError && user != null) {
            return Center(
              child: ElevatedButton(
                onPressed: () => _ensureProfile(user),
                child: const Text("Create Profile"),
              ),
            );
          }

          final language =
              _selectedLanguage ?? data?['language'] as String? ?? 'en';

          return RefreshIndicator(
            onRefresh: () async {
              _setupStream();
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: colorScheme.surfaceVariant,
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? Icon(Icons.person_rounded,
                            size: 50, color: colorScheme.onSurfaceVariant)
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    email,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Language Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                          color: colorScheme.secondary.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.language_rounded,
                                color: colorScheme.secondary, size: 24),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              'Language',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ],
                        ),
                        DropdownButton<String>(
                          value: language,
                          underline: const SizedBox(),
                          dropdownColor: colorScheme.surface,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'en', child: Text('English')),
                            DropdownMenuItem(
                                value: 'gu', child: Text('Gujarati')),
                          ],
                          onChanged: (val) {
                            if (val != null) _updateLanguage(val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  _buildProfileOption(
                    context,
                    icon: Icons.history_rounded,
                    title: 'Mock Tests',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const PurchasedTestsScreen()),
                      );
                    },
                  ),
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
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'App Support',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ChatScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.xl),
                  Divider(color: colorScheme.outline.withOpacity(0.1)),
                  const SizedBox(height: AppSpacing.md),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: Text(
                        "About App",
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  _buildProfileOption(
                    context,
                    icon: Icons.contact_support_rounded,
                    title: 'Contact Us',
                    onTap: () => _showContactOptions(context),
                  ),
                  _buildProfileOption(
                    context,
                    icon: Icons.privacy_tip_rounded,
                    title: 'Privacy Policy',
                    onTap: () => _launchUrl(AppConfigService.privacyPolicyUrl),
                  ),
                  _buildProfileOption(
                    context,
                    icon: Icons.description_rounded,
                    title: 'Terms & Conditions',
                    onTap: () => _launchUrl(AppConfigService.termsUrl),
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await context.read<AuthProvider>().signOut();
                        if (context.mounted) {
                          Navigator.of(context)
                              .pushNamedAndRemoveUntil('/', (route) => false);
                        }
                      },
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: const Text('Logout'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.error),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => _confirmDeleteAccount(context),
                      icon: const Icon(Icons.delete_forever_rounded, size: 20),
                      label: const Text('Delete Account'),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            colorScheme.onSurfaceVariant.withOpacity(0.6),
                        padding: const EdgeInsets.all(AppSpacing.md),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
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
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, color: colorScheme.primary, size: 22),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant))
          : null,
      trailing: Icon(Icons.chevron_right_rounded,
          color: colorScheme.onSurfaceVariant, size: 20),
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
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
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );

        await ChatService().sendMessage(
            "I need to delete account. Please process my request.");

        if (context.mounted) {
          Navigator.pop(context); // Pop loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Deletion request sent to admin support.'),
              backgroundColor: colorScheme.tertiary,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Pop loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error sending request: $e'),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _showContactOptions(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              "Contact Us",
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xl),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.email_rounded, color: Colors.blue),
              ),
              title: const Text("Email Support"),
              onTap: () {
                Navigator.pop(context);
                final email = AppConfigService.email;
                _launchUrl("mailto:$email");
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_rounded, color: Colors.green),
              ),
              title: const Text("WhatsApp"),
              onTap: () {
                Navigator.pop(context);
                final phone = AppConfigService.whatsappNumber
                    .replaceAll(RegExp(r'[^\d+]'), '');
                _launchUrl("https://wa.me/$phone");
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.lightBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.lightBlue),
              ),
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
