import 'package:flutter/material.dart';
import 'package:krushi_kalp/utils/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_notifier.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // REMOVED (unused)
import '../login_screen.dart';
import 'manage_app/manage_app_screen.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';

class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(fontSize: context.sp(14))), // FIXED
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            child: Text('Logout',
                style: TextStyle(fontSize: context.sp(14))), // FIXED
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await ref.read(authProvider.notifier).signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Admin Profile',
            style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: context.sp(20))), // FIXED
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.xxl,
            AppSpacing.xxl,
            AppSpacing.xxl + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildUserInfo(context, ref),
              SizedBox(height: AppSpacing.xxxl),
              SizedBox(
                width: double.infinity,
                height: context.h(56), // FIXED
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ManageAppScreen()),
                    );
                  },
                  icon: Icon(Icons.settings, size: context.sp(20)), // FIXED
                  label: Text('MANAGE APP',
                      style: TextStyle(fontSize: context.sp(14))), // FIXED
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        colorScheme.primaryContainer.withValues(alpha: 0.5),
                    foregroundColor: colorScheme.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: context.h(56), // FIXED
                child: ElevatedButton.icon(
                  onPressed: () => _logout(context, ref),
                  icon: Icon(Icons.logout, size: context.sp(20)), // FIXED
                  label: Text('LOGOUT',
                      style: TextStyle(fontSize: context.sp(14))), // FIXED
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        colorScheme.errorContainer.withValues(alpha: 0.5),
                    foregroundColor: colorScheme.error,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final metadata = user?.userMetadata;
    final name = metadata?['full_name'] ?? metadata?['name'] ?? 'Administrator';
    final email = user?.email ?? 'admin@krushikalp.com';
    final photoUrl = metadata?['avatar_url'] ?? metadata?['picture'];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        CircleAvatar(
          radius: context.sp(50), // FIXED
          backgroundColor: colorScheme.primaryContainer,
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null
              ? Icon(Icons.admin_panel_settings,
                  size: context.sp(50),
                  color: colorScheme.onPrimaryContainer) // FIXED
              : null,
        ),
        SizedBox(height: AppSpacing.xl),
        Text(
          name,
          style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold, fontSize: context.sp(24)), // FIXED
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          email,
          style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: context.sp(14)), // FIXED
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
