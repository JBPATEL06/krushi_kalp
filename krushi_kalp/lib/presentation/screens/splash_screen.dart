import 'package:flutter/material.dart';
import 'package:krushi_kalp/core/theme/app_spacing.dart';
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
    // Run config fetch + notification init in parallel
    await Future.wait([
      AppConfigService.fetchConfigs().catchError((e) {
        return null;
      }),
      NotificationService().initialize().catchError((e) {
        return null;
      }),
    ]).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        return [];
      },
    );

    setState(() => _progress = 1.0);
    await Future.delayed(const Duration(milliseconds: 300));

    // ── Force Update Check ──────────────────────────────────────────────────
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    int attempts = 0;
    while (!authProvider.isAuthCheckComplete && attempts < 10) {
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;
      if (_disposed) return;
    }

    if (!mounted) return;
    final role = authProvider.userRole;

    // ── App Status Checks (Skip for Admins) ──────────────────────────────────
    if (role != 'Admin') {
      // 1. Force Update Check
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

      // 2. Maintenance Check
      if (AppConfigService.isMaintenanceMode) {
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
    }

    // Final navigation
    if (authProvider.isLoggedIn) {
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
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/playstore.png',
                  width: context.w(140), // FIXED
                  height: context.w(140), // FIXED
                  fit: BoxFit.contain,
                ),
                SizedBox(height: context.h(48)), // FIXED: Using context.h(48)
                // App Title
                Text(
                  'Krushi Kalp',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    fontSize: context.sp(36), // FIXED: context.sp(36)
                  ),
                ),
                SizedBox(height: AppSpacing.sm), // FIXED: AppSpacing.sm
                // Tagline
                Text(
                  'Empowering Agricultural Academics',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    letterSpacing: 0.2,
                    fontSize: context.sp(14), // FIXED: context.sp(14)
                  ),
                ),
                SizedBox(height: context.h(80)), // FIXED
                // Loading Section
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxl), // FIXED: AppSpacing.xxl
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _statusText,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                              fontSize: context.sp(12), // FIXED: context.sp(12)
                            ),
                          ),
                          Text(
                            '${(_progress * 100).toInt()}%',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: context.sp(12), // FIXED: context.sp(12)
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.md), // FIXED: AppSpacing.md
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 6,
                          backgroundColor:
                              colorScheme.primary.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.xl), // FIXED: AppSpacing.xl
                Text(
                  'AGRICULTURAL ACADEMIC INDUSTRY',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    letterSpacing: 1.2,
                    fontSize: context.sp(10), // FIXED: context.sp(10)
                  ),
                ),
              ],
            ),
          ),
          // Footer
          Positioned(
            left: 0,
            right: 0,
            bottom: context.h(40), // FIXED: context.h(40)
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      size: context.sp(14), // FIXED: context.sp(14)
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    SizedBox(width: AppSpacing.sm), // FIXED: AppSpacing.sm
                    Text(
                      'SECURE ACCESS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color:
                            colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        fontSize: context.sp(11), // FIXED: context.sp(11)
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.xs), // FIXED: AppSpacing.xs
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final version = snapshot.data?.version ?? '1.0.0';
                    final build = snapshot.data?.buildNumber ?? '1';
                    return Text(
                      'v$version Build $build',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                        fontSize: context.sp(10), // FIXED: context.sp(10)
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
