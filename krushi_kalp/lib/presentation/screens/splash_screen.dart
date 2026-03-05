import 'package:krushi_kalp/core/theme/app_colors.dart';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/auth_provider.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/app_config_service.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'update_required_screen.dart';
import 'package:provider/provider.dart';
import 'maintenance_screen.dart';
import 'package:krushi_kalp/presentation/widgets/common/responsive_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// Returns true if [current] is strictly less than [minimum].
  /// Both strings must be in "major.minor.patch" format, e.g. "1.2.0".
  bool _isVersionBelow(String current, String minimum) {
    try {
      final c = current.split('.').map(int.parse).toList();
      final m = minimum.split('.').map(int.parse).toList();
      for (int i = 0; i < 3; i++) {
        final cv = i < c.length ? c[i] : 0;
        final mv = i < m.length ? m[i] : 0;
        if (cv < mv) return true;
        if (cv > mv) return false;
      }
      return false; // equal versions are not "below"
    } catch (_) {
      return false; // if parsing fails, do not block the user
    }
  }

  // Disposed flag to prevent navigation after widget is removed from tree
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _checkAuthAndNavigate() async {
    debugPrint("Splash: Starting checks...");

    // Run config fetch + notification init in parallel with a combined timeout
    // so a slow network doesn't hang the app indefinitely.
    await Future.wait([
      AppConfigService.fetchConfigs().catchError((e) {
        debugPrint("Splash: Config Config fetch error (non-fatal): $e");
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

    // ── Force Update Check ──────────────────────────────────────────────────
    // Compare installed version vs the min_version set in Supabase app_status.
    // If not mounted yet, skip safely.
    if (mounted) {
      final minVer = AppConfigService.minVersion;
      if (minVer != null && minVer.isNotEmpty) {
        final info = await PackageInfo.fromPlatform();
        final current = info.version; // e.g. "1.0.0"
        if (_isVersionBelow(current, minVer)) {
          debugPrint(
              "Splash: Version $current < required $minVer — showing update screen.");
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => UpdateRequiredScreen(
                  currentVersion: current,
                  requiredVersion: minVer,
                ),
              ),
            );
          }
          return; // Stop here — user must update
        }
      }
    }
    // ───────────────────────────────────────────────────────────────────────

    // Wait for AuthProvider to finish its own session check (max ~4s)
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    int attempts = 0;
    while (!authProvider.isAuthCheckComplete && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;
      if (_disposed) return; // Stop if widget disposed
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

      if (role != 'Admin') {
        // Regular User → connect user notifications → go to MainScreen
        NotificationService().connectUser();
        if (mounted && !_disposed) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } else {
        // Admin → connect admin notifications → redirect to LoginScreen
        // (Admin user who signed in via user app gets sent to login)
        NotificationService().connectAdmin();
        if (mounted && !_disposed) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
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
