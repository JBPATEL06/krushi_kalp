import 'package:flutter/material.dart';
import 'package:krushi_kalp/utils/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_state.dart';
import 'package:krushi_kalp/presentation/providers/admin_notifier.dart';
import 'package:krushi_kalp/presentation/providers/auth_notifier.dart';
import 'package:krushi_kalp/core/theme/app_spacing.dart';
import 'package:krushi_kalp/core/theme/app_radius.dart';
import 'admin_home_screen.dart';
import 'admin_analysis_screen.dart';
import 'admin_user_list_screen.dart';
import 'admin_notification_screen.dart';
import 'manage_app/manage_app_screen.dart';
import 'admin_chat_list_screen.dart';


class AdminMainScreen extends ConsumerStatefulWidget {
  const AdminMainScreen({super.key});

  @override
  ConsumerState<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends ConsumerState<AdminMainScreen> {
  final List<bool> _initializedScreens = [
    true,
    false,
    false,
    false,
    false,
    false
  ];

  List<Widget> _buildScreens() {
    return [
      const AdminHomeScreen(),
      _initializedScreens[1]
          ? const AdminAnalysisScreen()
          : const SizedBox.shrink(),
      _initializedScreens[2]
          ? const AdminUserListScreen()
          : const SizedBox.shrink(),
      _initializedScreens[3]
          ? const AdminChatListScreen()
          : const SizedBox.shrink(),
      _initializedScreens[4]
          ? const AdminNotificationScreen()
          : const SizedBox.shrink(),
      _initializedScreens[5]
          ? const ManageAppScreen()
          : const SizedBox.shrink(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final adminState = ref.watch(adminProvider);
    final authState = ref.watch(authProvider);

    // Ensure the current tab is marked as initialized
    if (!_initializedScreens[adminState.navIndex]) {
      _initializedScreens[adminState.navIndex] = true;
    }

    return LayoutBuilder(builder: (context, constraints) {
      final isLargeScreen = constraints.maxWidth > 1024;
      final isTablet =
          constraints.maxWidth > 700 && constraints.maxWidth <= 1024;

      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (adminState.navIndex != 0) {
            ref.read(adminProvider.notifier).setNavIndex(0);
            return;
          }
        },
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            leading: isLargeScreen ? const SizedBox.shrink() : null,
            title: Text(_getAppBarTitle(adminState.navIndex),
                style: TextStyle(fontSize: context.sp(20))), // FIXED
            actions: [
              _buildRoleBadge(context),
              const SizedBox(width: AppSpacing.md),
            ],
          ),
          drawer: isLargeScreen
              ? null
              : _buildDrawer(context, adminState, authState),
          body: Row(
            children: [
              if (isLargeScreen || isTablet)
                Container(
                  width: context.w(isLargeScreen ? 280 : 80), // FIXED
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(
                      right: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                  child: _buildDrawer(context, adminState, authState,
                      isPersistent: true, isRail: isTablet),
                ),
              Expanded(
                child: IndexedStack(
                  index: adminState.navIndex,
                  children: _buildScreens(),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Analytics';
      case 2:
        return 'User Management';
      case 3:
        return 'Inbox';
      case 4:
        return 'Broadcast Alerts';
      case 5:
        return 'Manage App';
      default:
        return 'Krushi Kalp';
    }
  }

  Widget _buildRoleBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.admin_panel_settings_rounded,
              size: context.sp(14), color: colorScheme.primary), // FIXED
          const SizedBox(width: 6),
          Text(
            'ADMIN',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  fontSize: context.sp(11), // FIXED
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AdminState adminState,
      AuthState authState,
      {bool isPersistent = false, bool isRail = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isRail) {
      return _buildRail(context, adminState);
    }

    Widget drawerContent = Column(
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: context.sp(28), // FIXED
                backgroundColor: colorScheme.primary,
                child: Icon(Icons.agriculture_rounded,
                    color: Colors.white, size: context.sp(32)), // FIXED
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authState.user?.userMetadata?['name'] ??
                          'Krushi Kalp',
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        fontSize: context.sp(20), // FIXED
                      ),
                    ),
                    Text(
                      authState.user?.email ?? 'Admin Panel',
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.7), // Increased opacity for readability
                          fontSize: context.sp(12)), // FIXED
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            children: [
              const SizedBox(height: AppSpacing.md),
              _buildDrawerItem(
                context,
                index: 0,
                icon: Icons.dashboard_outlined,
                selectedIcon: Icons.dashboard_rounded,
                label: 'Dashboard',
                currentIndex: adminState.navIndex,
                onTap: () => _onTabSelected(
                    index: 0,
                    isPersistent: isPersistent),
              ),
              _buildDrawerItem(
                context,
                index: 1,
                icon: Icons.analytics_outlined,
                selectedIcon: Icons.analytics_rounded,
                label: 'Analytics',
                currentIndex: adminState.navIndex,
                onTap: () => _onTabSelected(
                    index: 1,
                    isPersistent: isPersistent),
              ),
              _buildDrawerItem(
                context,
                index: 2,
                icon: Icons.people_outline_rounded,
                selectedIcon: Icons.people_rounded,
                label: 'Users',
                currentIndex: adminState.navIndex,
                onTap: () => _onTabSelected(
                    index: 2,
                    isPersistent: isPersistent),
              ),
              _buildDrawerItem(
                context,
                index: 3,
                icon: Icons.forum_outlined,
                selectedIcon: Icons.forum_rounded,
                label: 'Inbox',
                currentIndex: adminState.navIndex,
                onTap: () => _onTabSelected(
                    index: 3,
                    isPersistent: isPersistent),
              ),
              _buildDrawerItem(
                context,
                index: 4,
                icon: Icons.notifications_active_outlined,
                selectedIcon: Icons.notifications_active_rounded,
                label: 'Alerts',
                currentIndex: adminState.navIndex,
                onTap: () => _onTabSelected(
                    index: 4,
                    isPersistent: isPersistent),
              ),
              _buildDrawerItem(
                context,
                index: 5,
                icon: Icons.settings_applications_outlined,
                selectedIcon: Icons.settings_applications_rounded,
                label: 'Manage App',
                currentIndex: adminState.navIndex,
                onTap: () => _onTabSelected(
                    index: 5,
                    isPersistent: isPersistent),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Divider(),
              ),
              ListTile(
                leading: Icon(Icons.logout_rounded, color: colorScheme.error),
                title: Text('Logout',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.bold,
                    )),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel')),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                              foregroundColor: colorScheme.error),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await ref.read(authProvider.notifier).signOut();
                  }
                },
              ),
            ],
          ),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ],
    );

    if (isPersistent) {
      return drawerContent;
    }
    return Drawer(child: drawerContent);
  }

  Widget _buildRail(BuildContext context, AdminState adminState) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        const SizedBox(height: AppSpacing.xxl),
        CircleAvatar(
          radius: 20,
          backgroundColor: colorScheme.primary,
          child: const Icon(Icons.agriculture_rounded,
              color: Colors.white, size: 24),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              _buildRailItem(context,
                  icon: Icons.dashboard_rounded,
                  index: 0,
                  currentIndex: adminState.navIndex,
                  onTap: () => ref.read(adminProvider.notifier).setNavIndex(0)),
              _buildRailItem(context,
                  icon: Icons.analytics_rounded,
                  index: 1,
                  currentIndex: adminState.navIndex,
                  onTap: () => ref.read(adminProvider.notifier).setNavIndex(1)),
              _buildRailItem(context,
                  icon: Icons.people_rounded,
                  index: 2,
                  currentIndex: adminState.navIndex,
                  onTap: () => ref.read(adminProvider.notifier).setNavIndex(2)),
              _buildRailItem(context,
                  icon: Icons.forum_rounded,
                  index: 3,
                  currentIndex: adminState.navIndex,
                  onTap: () => ref.read(adminProvider.notifier).setNavIndex(3)),
              _buildRailItem(context,
                  icon: Icons.notifications_active_rounded,
                  index: 4,
                  currentIndex: adminState.navIndex,
                  onTap: () => ref.read(adminProvider.notifier).setNavIndex(4)),
              _buildRailItem(context,
                  icon: Icons.settings_applications_rounded,
                  index: 5,
                  currentIndex: adminState.navIndex,
                  onTap: () => ref.read(adminProvider.notifier).setNavIndex(5)),
            ],
          ),
        ),
        IconButton(
          onPressed: () async {
            final auth = ref.read(authProvider.notifier);
            await auth.signOut();
          },
          icon: Icon(Icons.logout_rounded, color: colorScheme.error),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ],
    );
  }

  Widget _buildRailItem(BuildContext context,
      {required IconData icon,
      required int index,
      required int currentIndex,
      required VoidCallback onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = index == currentIndex;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon,
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant),
        style: IconButton.styleFrom(
          backgroundColor:
              isSelected ? colorScheme.primary.withValues(alpha: 0.1) : null,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
    );
  }

  void _onTabSelected(
      {required int index,
      bool isPersistent = false}) {
    if (!_initializedScreens[index]) {
      setState(() {
        _initializedScreens[index] = true;
      });
    }
    ref.read(adminProvider.notifier).setNavIndex(index);
    if (!isPersistent) {
      Navigator.pop(context); // Close drawer
    }
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int currentIndex,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = index == currentIndex;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        onTap: onTap,
        selected: isSelected,
        leading: Icon(
          isSelected ? selectedIcon : icon,
          color:
              isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        title: Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        selectedTileColor: colorScheme.primary.withValues(alpha: 0.08),
        visualDensity: const VisualDensity(vertical: -1),
      ),
    );
  }
}
