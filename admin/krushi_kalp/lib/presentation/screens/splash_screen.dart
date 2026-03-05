import 'package:krushi_kalp_admin/core/theme/app_colors.dart';

import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/app_config_service.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'admin/admin_main_screen.dart';
import 'package:provider/provider.dart';
import 'maintenance_screen.dart';
import 'package:krushi_kalp_admin/presentation/widgets/common/responsive_wrapper.dart';

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

    // Run config fetch + notification init in parallel with a combined timeout
    // so a slow network doesn't hang the app indefinitely.
    await Future.wait([
      AppConfigService.fetchConfigs().catchError((e) {
        debugPrint("Splash: Config fetch error (non-fatal): $e");
        return null;
      }),
      NotificationService().initialize().catchError((e) {
        debugPrint("Splash: Notification init error (non-fatal): $e");
        return null;
      }),
    ]).timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        debugPrint("Splash: Parallel init timed out — proceeding anyway.");
        return [];
      },
    );

    debugPrint("Splash: Parallel init done.");

    // Wait for AuthProvider to finish its own session check (max ~4s)
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    int attempts = 0;
    while (!authProvider.isAuthCheckComplete && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;
    }

    debugPrint(
        "Splash: AuthProvider retrieved. isLoggedIn: ${authProvider.isLoggedIn}");

    if (!mounted) return;

    // Navigation
    if (authProvider.isLoggedIn) {
      final role = authProvider.userRole;

      // MAINTENANCE CHECK — admins bypass maintenance mode
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
        NotificationService().connectAdmin(); // fire-and-forget
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminMainScreen()),
          );
        }
      } else {
        NotificationService().connectUser(); // fire-and-forget
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
