import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/route_constants.dart';
import 'package:krushi_kalp/core/theme/app_spacing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_notifier.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/app_config_service.dart';
import 'package:krushi_kalp/presentation/widgets/common/responsive_wrapper.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
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
      return false;
    } catch (_) {
      return false;
    }
  }

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
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 20));
      if (_disposed || _progress >= 0.95) return false;
      setState(() {
        _progress += 0.05;
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
    await Future.wait([
      AppConfigService.fetchConfigs().catchError((e) => null),
      NotificationService().initialize().catchError((e) => null),
    ]).timeout(
      const Duration(seconds: 5),
      onTimeout: () => [],
    );

    if (!mounted) return;
    setState(() => _progress = 1.0);
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    final authState = ref.read(authNotifierProvider);

    int attempts = 0;
    while (!authState.isAuthCheckComplete && attempts < 4) {
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;
      if (_disposed) return;
    }

    if (!mounted) return;
    final role = authState.userRole;

    if (role != 'Admin') {
      final minVer = AppConfigService.minVersion;
      if (minVer != null && minVer.isNotEmpty) {
        final info = await PackageInfo.fromPlatform();
        if (!mounted) return;
        final current = info.version;
        if (_isVersionBelow(current, minVer)) {
          if (mounted) {
            context.go(
              RouteConstants.updateRequired,
              extra: {
                'currentVersion': current,
                'requiredVersion': minVer,
              },
            );
          }
          return;
        }
      }

      if (AppConfigService.isMaintenanceMode) {
        if (mounted) {
          context.go(
            RouteConstants.maintenance,
            extra: {
              'error': AppConfigService.maintenanceMessage,
              'onRetry': () => context.go(RouteConstants.splash),
            },
          );
        }
        return;
      }
    }

    if (authState.isLoggedIn) {
      if (role != 'Admin') {
        NotificationService().connectUser();
        if (mounted && !_disposed) {
          context.go(RouteConstants.home);
        }
      } else {
        NotificationService().connectAdmin();
        if (mounted && !_disposed) {
          context.go(RouteConstants.adminDashboard);
        }
      }
    } else {
      if (mounted && !_disposed) {
        context.go(RouteConstants.login);
      }
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
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/applogo.png',
                    width: context.wp(40),
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: context.h(48)),
                Text(
                  'Krushi Kalp',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    fontSize: context.sp(36),
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Empowering Agricultural Academics',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    letterSpacing: 0.2,
                    fontSize: context.sp(14),
                  ),
                ),
                SizedBox(height: context.h(80)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _statusText,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              fontSize: context.sp(12),
                            ),
                          ),
                          Text(
                            '${(_progress * 100).toInt()}%',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: context.sp(12),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.md),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 6,
                          backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                Text(
                  'AGRICULTURAL ACADEMIC INDUSTRY',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    letterSpacing: 1.2,
                    fontSize: context.sp(10),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: context.h(40),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      size: context.sp(14),
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      'SECURE ACCESS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        fontSize: context.sp(11),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.xs),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final version = snapshot.data?.version ?? '1.0.0';
                    final build = snapshot.data?.buildNumber ?? '1';
                    return Text(
                      'v$version Build $build',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                        fontSize: context.sp(10),
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
