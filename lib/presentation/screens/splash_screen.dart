import 'dart:io';

import 'package:krushi_kalp/core/theme/app_colors.dart';

import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/app_config_service.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'admin/admin_main_screen.dart';
import 'package:provider/provider.dart';
import 'maintenance_screen.dart';
import 'package:krushi_kalp/presentation/widgets/common/responsive_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    debugPrint("Splash: Starting checks...");

    // 0. Connectivity Guard
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        debugPrint("Splash: Public Internet is Reachable");
      }
    } catch (e) {
      // ... existing error handling ...
    }

    // 0.5 Fetch App Configuration
    try {
      debugPrint("Splash: Fetching App Config...");
      await AppConfigService.fetchConfigs();
    } catch (e) {
      debugPrint("Splash: Config fetch error: $e");
    }

    // 1. Initialize services
    try {
      debugPrint("Splash: Initializing NotificationService...");
      await NotificationService().initialize();
      debugPrint("Splash: NotificationService Done.");
    } catch (e) {
      debugPrint("Splash: Init error: $e");
    }

    // 2. Wait for AuthProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Loop until auth check is complete
    int attempts = 0;
    while (!authProvider.isAuthCheckComplete && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;
    }

    debugPrint(
        "Splash: AuthProvider retrieved. isLoggedIn: ${authProvider.isLoggedIn}");

    if (!mounted) return;

    // 3. Navigation
    if (authProvider.isLoggedIn) {
      final role = authProvider.userRole;

      // MAINTENANCE CHECK
      // Admins bypass maintenance mode
      if (AppConfigService.isMaintenanceMode && role != 'Admin') {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MaintenanceScreen(
                error: AppConfigService.maintenanceMessage,
                onRetry: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SplashScreen()),
                  );
                },
              ),
            ),
          );
        }
        return;
      }

      if (role == 'Admin') {
        await NotificationService().connectAdmin();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminMainScreen()),
          );
        }
      } else {
        await NotificationService().connectUser();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('SplashScreen: Building...');
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/playstore.png',
              width: context.w(120),
              height: context.h(120),
            ),
            SizedBox(height: context.h(24)),
            Text(
              'Krushi kalp',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: context.h(48)),
            const CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
