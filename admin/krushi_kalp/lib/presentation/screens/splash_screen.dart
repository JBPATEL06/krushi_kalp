import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/app_config_service.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'admin/admin_main_screen.dart';
import 'package:provider/provider.dart';
import 'maintenance_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:krushi_kalp_admin/presentation/widgets/common/responsive_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // State for simulated progress
  double _progress = 0.0;
  String _statusText = 'Initializing system...';
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _startProgressSimulation();
    _checkAuthAndNavigate();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _startProgressSimulation() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 50));
      if (_disposed || _progress >= 0.95) return false;
      setState(() {
        _progress += 0.02;
        if (_progress > 0.4) _statusText = 'Accessing dashboards...';
        if (_progress > 0.7) _statusText = 'Syncing records...';
      });
      return true;
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    debugPrint("Splash: Starting checks...");

    // Parallel init
    await Future.wait([
      AppConfigService.fetchConfigs().catchError((e) {
        debugPrint("Splash: Config fetch error: $e");
        return null;
      }),
      NotificationService().initialize().catchError((e) {
        debugPrint("Splash: Notification init error: $e");
        return null;
      }),
    ]).timeout(
      const Duration(seconds: 4),
      onTimeout: () {
        debugPrint("Splash: Initial checks timed out.");
        return [];
      },
    );

    setState(() => _progress = 1.0);
    await Future.delayed(const Duration(milliseconds: 300));

    // Wait for Auth check
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    int attempts = 0;
    while (!authProvider.isAuthCheckComplete && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;
    }

    if (!mounted) return;

    // Navigation
    if (authProvider.isLoggedIn) {
      final role = authProvider.userRole;
      if (AppConfigService.isMaintenanceMode && role != 'Admin') {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MaintenanceScreen(
                error: AppConfigService.maintenanceMessage,
                onRetry: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SplashScreen()),
                ),
              ),
            ),
          );
        }
        return;
      }

      if (role == 'Admin') {
        NotificationService().connectAdmin();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminMainScreen()),
          );
        }
      } else {
        NotificationService().connectUser();
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Box
                Container(
                  width: context.w(130),
                  height: context.w(130),
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.06),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/playstore.png',
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: context.h(40)),
                // Title
                Text(
                  'Krushi Kalp',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                // Admin Tagline
                Text(
                  'Agri-Academic Management',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                    letterSpacing: 0.1,
                  ),
                ),
                SizedBox(height: context.h(80)),
                // Loading Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 56),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _statusText,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color:
                                  colorScheme.onSurfaceVariant.withOpacity(0.5),
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '${(_progress * 100).toInt()}%',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 5,
                          backgroundColor: colorScheme.primary.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'ACADEMIC CONTROL HUB',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                    letterSpacing: 1.5,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          // Footer
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 14,
                      color: colorScheme.primary.withOpacity(0.4),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SECURE ACCESS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final version = snapshot.data?.version ?? '1.0.0';
                    return Text(
                      'v$version Administrator',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                        fontSize: 10,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
