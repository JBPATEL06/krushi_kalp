import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/login_screen.dart';
import '../../presentation/screens/about_screen.dart';
import '../../presentation/screens/profile_screen.dart';
import '../../presentation/screens/admin/admin_main_screen.dart';
import '../../presentation/screens/admin/admin_user_list_screen.dart';
import '../../presentation/screens/admin/admin_order_list_screen.dart';
import '../../presentation/screens/main_screen.dart';
import '../../presentation/screens/maintenance_screen.dart';
import '../../presentation/screens/update_required_screen.dart';
import '../../presentation/screens/all_tests_screen.dart';
import '../../presentation/utils/navigator_key.dart';
import '../../presentation/providers/auth_notifier.dart';
import 'route_constants.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: RouteConstants.splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: RouteConstants.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteConstants.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteConstants.home,
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: RouteConstants.maintenance,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return MaintenanceScreen(
            error: extra?['error'] as String?,
            onRetry: extra?['onRetry'] as VoidCallback? ?? () {},
          );
        },
      ),
      GoRoute(
        path: RouteConstants.updateRequired,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return UpdateRequiredScreen(
            currentVersion: extra?['currentVersion'] as String? ?? '0.0.0',
            requiredVersion: extra?['requiredVersion'] as String? ?? '0.0.0',
          );
        },
      ),
      GoRoute(
        path: RouteConstants.about,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: RouteConstants.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: RouteConstants.allTests,
        builder: (context, state) => const AllTestsScreen(),
      ),

      // Admin Routes
      GoRoute(
        path: RouteConstants.adminDashboard,
        builder: (context, state) => const AdminMainScreen(),
        routes: [
          GoRoute(
            path: 'users', // Sub-route of /admin
            builder: (context, state) => const AdminUserListScreen(),
          ),
          GoRoute(
            path: 'orders',
            builder: (context, state) => const AdminOrderListScreen(),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      // 1. If auth check is not done, ALWAYS stay on Splash
      if (!authState.isAuthCheckComplete) {
        return RouteConstants.splash;
      }

      final isLoggedIn = authState.isLoggedIn;
      final isLoggingIn = state.matchedLocation == RouteConstants.login;
      final isSplash = state.matchedLocation == RouteConstants.splash;

      // New: Determine where to send a logged-in user
      final String targetHome = authState.isAdmin ? RouteConstants.adminDashboard : RouteConstants.home;

      // 2. If finished check and still on splash, decide where to go
      if (isSplash) {
        return isLoggedIn ? targetHome : RouteConstants.login;
      }

      // 3. Protected routes logic
      if (!isLoggedIn && !isLoggingIn) {
        return RouteConstants.login;
      }

      if (isLoggedIn && isLoggingIn) {
        return targetHome;
      }

      return null;
    },
  );
}
