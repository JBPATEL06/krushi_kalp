import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/auth_provider.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/app_config_service.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'admin/admin_main_screen.dart';
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
  double _progress = 0.0;
  String _statusText = 'Initializing modules...';

  @override
  void initState() {
    super.initState();
    _startProgressSimulation();
    _checkAuthAndNavigate();
  }

  void _startProgressSimulation() {
    // Simulate loading progress for a smoother visual experience
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 50));
      if (_disposed || _progress >= 0.95) return false;
      setState(() {
        _progress += 0.02;
        if (_progress > 0.3) _statusText = 'Loading preferences...';
        if (_progress > 0.6) _statusText = 'Syncing data...';
        if (_progress > 0.8) _statusText = 'Ready';
      });
      return true;
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _checkAuthAndNavigate() async {
    debugPrint("Splash: Starting checks...");

    // Run config fetch + notification init in parallel
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
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint("Splash: Parallel init timed out — proceeding anyway.");
        return [];
      },
    );

    setState(() => _progress = 1.0);
    await Future.delayed(const Duration(milliseconds: 300));

    debugPrint("Splash: Parallel init done.");

    // ── Force Update Check ──────────────────────────────────────────────────
    if (mounted) {
      final minVer = AppConfigService.minVersion;
      if (minVer != null && minVer.isNotEmpty) {
        final info = await PackageInfo.fromPlatform();
        final current = info.version;
        if (_isVersionBelow(current, minVer)) {
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
          return;
        }
      }
    }

    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    int attempts = 0;
    while (!authProvider.isAuthCheckComplete && attempts < 10) {
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;
      if (_disposed) return;
    }

    if (!mounted) return;

    // Final navigation
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

      if (role != 'Admin') {
        NotificationService().connectUser();
        if (mounted && !_disposed) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } else {
        NotificationService().connectAdmin();
        if (mounted && !_disposed) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminMainScreen()),
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
          // Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Container with Soft Shadow
                Container(
                  width: context.w(150),
                  height: context.w(150),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.08),
                        blurRadius: 40,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/playstore.png',
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: context.h(48)),
                // App Title
                Text(
                  'Krushi Kalp',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                // Tagline
                Text(
                  'Empowering Agricultural Academics',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: context.h(80)),
                // Loading Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
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
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 6,
                          backgroundColor:
                              colorScheme.primary.withOpacity(0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'AGRICULTURAL ACADEMIC INDUSTRY',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                    letterSpacing: 1.2,
                    fontSize: 10,
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
                      Icons.verified_user_rounded,
                      size: 14,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SECURE ACCESS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final version = snapshot.data?.version ?? '1.0.0';
                    final build = snapshot.data?.buildNumber ?? '1';
                    return Text(
                      'v$version Build $build',
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
