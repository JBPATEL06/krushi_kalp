import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:krushi_kalp_admin/presentation/providers/admin_provider.dart';
import 'package:krushi_kalp_admin/core/theme/app_colors.dart';
import 'admin_home_screen.dart';
import 'admin_analysis_screen.dart';
// import 'admin_chat_list_screen.dart'; // Removed
import 'admin_user_list_screen.dart';
import 'admin_notification_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  final List<Widget> _screens = [
    const AdminHomeScreen(), // Dashboard (0)
    const AdminAnalysisScreen(), // Analytics (1)
    const AdminUserListScreen(), // Users (2)
    const AdminNotificationScreen(), // Alerts (3)
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (provider.navIndex != 0) {
              provider.setNavIndex(0);
              return;
            }
            debugPrint(
                "Back pressed on Admin Dashboard - Ignoring to prevent crash");
          },
          child: Scaffold(
            body: IndexedStack(
              index: provider.navIndex,
              children: _screens,
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: NavigationBar(
                height: 70,
                backgroundColor: AppColors.surface,
                elevation: 0,
                selectedIndex: provider.navIndex,
                onDestinationSelected: provider.setNavIndex,
                indicatorColor: AppColors.primary.withValues(alpha: 0.1),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon:
                        Icon(Icons.dashboard_rounded, color: AppColors.primary),
                    label: 'Dashboard',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.analytics_outlined),
                    selectedIcon:
                        Icon(Icons.analytics_rounded, color: AppColors.primary),
                    label: 'Analytics',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.people_outline_rounded),
                    selectedIcon:
                        Icon(Icons.people_rounded, color: AppColors.primary),
                    label: 'Users',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.notifications_active_outlined),
                    selectedIcon: Icon(Icons.notifications_active_rounded,
                        color: AppColors.primary),
                    label: 'Alerts',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
