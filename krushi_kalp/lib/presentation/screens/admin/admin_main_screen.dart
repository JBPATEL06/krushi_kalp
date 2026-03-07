import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:krushi_kalp/presentation/providers/admin_provider.dart';
import 'package:krushi_kalp/presentation/providers/auth_provider.dart';
import 'package:krushi_kalp/core/theme/app_spacing.dart';
import 'package:krushi_kalp/core/theme/app_radius.dart';
import 'admin_home_screen.dart';
import 'admin_analysis_screen.dart';
import 'admin_user_list_screen.dart';
import 'admin_notification_screen.dart';
import 'manage_app/manage_app_screen.dart';
import '../login_screen.dart';
import 'admin_chat_list_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
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

    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        return LayoutBuilder(builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 1024;
          final isTablet =
              constraints.maxWidth > 700 && constraints.maxWidth <= 1024;

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              if (provider.navIndex != 0) {
                provider.setNavIndex(0);
                return;
              }
            },
            child: Scaffold(
              backgroundColor: colorScheme.background,
              appBar: AppBar(
                leading: isLargeScreen ? const SizedBox.shrink() : null,
                title: Text(_getAppBarTitle(provider.navIndex)),
                actions: [
                  _buildRoleBadge(context),
                  const SizedBox(width: AppSpacing.md),
                ],
              ),
              drawer: isLargeScreen ? null : _buildDrawer(context, provider),
              body: Row(
                children: [
                  if (isLargeScreen || isTablet)
                    Container(
                      width: isLargeScreen ? 280 : 80,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        border: Border(
                          right: BorderSide(color: colorScheme.outlineVariant),
                        ),
                      ),
                      child: _buildDrawer(context, provider,
                          isPersistent: true, isRail: isTablet),
                    ),
                  Expanded(
                    child: IndexedStack(
                      index: provider.navIndex,
                      children: _buildScreens(),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
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
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.admin_panel_settings_rounded,
              size: 14, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            'ADMIN',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AdminProvider provider,
      {bool isPersistent = false, bool isRail = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isRail) {
      return _buildRail(context, provider);
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
                radius: 28,
                backgroundColor: colorScheme.primary,
                child: const Icon(Icons.agriculture_rounded,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Krushi Kalp',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Admin Panel',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
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
                currentIndex: provider.navIndex,
                onTap: () => _onTabSelected(
                    index: 0, provider: provider, isPersistent: isPersistent),
              ),
              _buildDrawerItem(
                context,
                index: 1,
                icon: Icons.analytics_outlined,
                selectedIcon: Icons.analytics_rounded,
                label: 'Analytics',
                currentIndex: provider.navIndex,
                onTap: () => _onTabSelected(
                    index: 1, provider: provider, isPersistent: isPersistent),
              ),
              _buildDrawerItem(
                context,
                index: 2,
                icon: Icons.people_outline_rounded,
                selectedIcon: Icons.people_rounded,
                label: 'Users',
                currentIndex: provider.navIndex,
                onTap: () => _onTabSelected(
                    index: 2, provider: provider, isPersistent: isPersistent),
              ),
              _buildDrawerItem(
                context,
                index: 3,
                icon: Icons.forum_outlined,
                selectedIcon: Icons.forum_rounded,
                label: 'Inbox',
                currentIndex: provider.navIndex,
                onTap: () => _onTabSelected(
                    index: 3, provider: provider, isPersistent: isPersistent),
              ),
              _buildDrawerItem(
                context,
                index: 4,
                icon: Icons.notifications_active_outlined,
                selectedIcon: Icons.notifications_active_rounded,
                label: 'Alerts',
                currentIndex: provider.navIndex,
                onTap: () => _onTabSelected(
                    index: 4, provider: provider, isPersistent: isPersistent),
              ),
              _buildDrawerItem(
                context,
                index: 5,
                icon: Icons.settings_applications_outlined,
                selectedIcon: Icons.settings_applications_rounded,
                label: 'Manage App',
                currentIndex: provider.navIndex,
                onTap: () => _onTabSelected(
                    index: 5, provider: provider, isPersistent: isPersistent),
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
                    await context.read<AuthProvider>().signOut();
                    if (mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );

    if (isPersistent) {
      return drawerContent;
    }
    return Drawer(child: drawerContent);
  }

  Widget _buildRail(BuildContext context, AdminProvider provider) {
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
                  currentIndex: provider.navIndex,
                  onTap: () => provider.setNavIndex(0)),
              _buildRailItem(context,
                  icon: Icons.analytics_rounded,
                  index: 1,
                  currentIndex: provider.navIndex,
                  onTap: () => provider.setNavIndex(1)),
              _buildRailItem(context,
                  icon: Icons.people_rounded,
                  index: 2,
                  currentIndex: provider.navIndex,
                  onTap: () => provider.setNavIndex(2)),
              _buildRailItem(context,
                  icon: Icons.forum_rounded,
                  index: 3,
                  currentIndex: provider.navIndex,
                  onTap: () => provider.setNavIndex(3)),
              _buildRailItem(context,
                  icon: Icons.notifications_active_rounded,
                  index: 4,
                  currentIndex: provider.navIndex,
                  onTap: () => provider.setNavIndex(4)),
              _buildRailItem(context,
                  icon: Icons.settings_applications_rounded,
                  index: 5,
                  currentIndex: provider.navIndex,
                  onTap: () => provider.setNavIndex(5)),
            ],
          ),
        ),
        IconButton(
          onPressed: () async {
            // Sign out logic repeated or extracted
            await context.read<AuthProvider>().signOut();
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            }
          },
          icon: Icon(Icons.logout_rounded, color: colorScheme.error),
        ),
        const SizedBox(height: AppSpacing.lg),
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
              isSelected ? colorScheme.primary.withOpacity(0.1) : null,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
    );
  }

  void _onTabSelected(
      {required int index,
      required AdminProvider provider,
      bool isPersistent = false}) {
    if (!_initializedScreens[index]) {
      setState(() {
        _initializedScreens[index] = true;
      });
    }
    provider.setNavIndex(index);
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
        selectedTileColor: colorScheme.primary.withOpacity(0.08),
        visualDensity: const VisualDensity(vertical: -1),
      ),
    );
  }
}
