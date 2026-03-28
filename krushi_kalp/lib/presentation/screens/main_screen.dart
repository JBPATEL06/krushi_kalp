import 'package:flutter/material.dart';
import 'package:krushi_kalp/presentation/screens/purchased_tests_screen.dart'; // Show only mock tests
import 'package:krushi_kalp/presentation/screens/store_screen.dart';
import 'downloads_screen.dart';
import '../providers/auth_notifier.dart';
import '../providers/test_notifier.dart';
import '../providers/resource_notifier.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import '../providers/navigation_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../data/services/app_config_service.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  // _selectedIndex moved to NavigationProvider

  final List<Widget> _screens = [
    const HomeScreen(),
    const PurchasedTestsScreen(), // Mock Tests Only
    const StoreScreen(), // Replaces Result
    const DownloadsScreen(),
    const ProfileScreen(), // Index 4
  ];

  @override
  void initState() {
    super.initState();

    // Initial Sync for logged in user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAppStatus(); // NEW: Gate check
      _initialSync();
    });
  }

  Future<void> _checkAppStatus() async {
    final authState = ref.read(authNotifierProvider);
    if (authState.isAdmin) {
      return;
    }

    // Ensure configs are fresh (though Splash usually fetches them)
    // We don't await here to avoid blocking UI, but Splash ensures they are ready.

    // 1. Maintenance Check
    if (AppConfigService.isMaintenanceMode) {
      return;
    }

    // 2. Version Check
    final minVer = AppConfigService.minVersion;
    if (minVer != null && minVer.isNotEmpty) {
      final info = await PackageInfo.fromPlatform();
      final current = info.version;
      if (_isVersionBelow(current, minVer)) {
        return;
      }
    }
  }

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

  Future<void> _initialSync() async {
    final authState = ref.read(authNotifierProvider);
    if (authState.isLoggedIn && authState.user != null) {
      final userId = authState.user!.id;

      // Trigger background fetches (Non-blocking)
      ref.read(testNotifierProvider.notifier).fetchTests();
      ref.read(testNotifierProvider.notifier).fetchUserTests(userId);
      ref.read(resourceNotifierProvider.notifier).fetchAll();
      ref
          .read(resourceNotifierProvider.notifier)
          .fetchPurchasedResources(userId);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navState = ref.watch(navigationProvider);
    final navNotifier = ref.read(navigationProvider.notifier);

    // Listen for auth state changes to handle logout

    return PopScope(
      canPop: navState.selectedIndex == 0, // Allow pop only on Home tab
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // If not on Home tab, go to Home instead of exiting
        if (navState.selectedIndex != 0) {
          navNotifier.setIndex(0);
          return;
        }
        // On Home tab - do nothing (already prevented by canPop = true)
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 640) {
            // Desktop
            return Scaffold(
              body: Row(
                children: [
                  if (navState.selectedIndex < 4)
                    NavigationRail(
                      selectedIndex: navState.selectedIndex,
                      onDestinationSelected: (index) {
                        if (index == 2) {
                          navNotifier.setStoreCategory('All');
                        }
                        navNotifier.setIndex(index);
                      },
                      labelType: NavigationRailLabelType.all,
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.home_outlined),
                          selectedIcon: Icon(Icons.home),
                          label: Text('Home'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.quiz_outlined),
                          selectedIcon: Icon(Icons.quiz),
                          label: Text('Mock Tests'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.storefront_outlined),
                          selectedIcon: Icon(Icons.storefront),
                          label: Text('Store'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.download_outlined),
                          selectedIcon: Icon(Icons.download),
                          label: Text('Downloads'),
                        ),
                      ],
                    ),
                  if (navState.selectedIndex < 4)
                    const VerticalDivider(thickness: 1, width: 1),
                  Expanded(
                    child: IndexedStack(
                      index: navState.selectedIndex,
                      children: _screens,
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Mobile
            return Scaffold(
              body: IndexedStack(
                index: navState.selectedIndex,
                children: _screens,
              ),
              bottomNavigationBar: navState.selectedIndex >= 4
                  ? null
                  : SafeArea(
                      top: false,
                      child: NavigationBarTheme(
                        data: NavigationBarThemeData(
                          backgroundColor: theme.colorScheme.surface,
                          elevation: 0,
                          indicatorColor:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                          labelBehavior:
                              NavigationDestinationLabelBehavior.alwaysShow,
                          labelTextStyle:
                              WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              );
                            }
                            return TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurfaceVariant,
                            );
                          }),
                          iconTheme: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return IconThemeData(
                                size: 26,
                                color: theme.colorScheme.primary,
                              );
                            }
                            return IconThemeData(
                              size: 24,
                              color: theme.colorScheme.onSurfaceVariant,
                            );
                          }),
                        ),
                        child: NavigationBar(
                          height: 70,
                          backgroundColor: theme.colorScheme.surface,
                          shadowColor: Colors.transparent,
                          surfaceTintColor: theme.colorScheme.surface,
                          selectedIndex: navState.selectedIndex,
                          onDestinationSelected: (index) {
                            if (index == 2) {
                              navNotifier.setStoreCategory('All');
                            }
                            navNotifier.setIndex(index);
                          },
                          destinations: const [
                            NavigationDestination(
                              icon: Icon(Icons.home_outlined),
                              selectedIcon: Icon(Icons.home_rounded, size: 28),
                              label: 'Home',
                            ),
                            NavigationDestination(
                              icon: Icon(Icons.quiz_outlined),
                              selectedIcon: Icon(Icons.quiz_rounded, size: 28),
                              label: 'Mocks',
                            ),
                            NavigationDestination(
                              icon: Icon(Icons.storefront_outlined),
                              selectedIcon:
                                  Icon(Icons.storefront_rounded, size: 28),
                              label: 'Store',
                            ),
                            NavigationDestination(
                              icon: Icon(Icons.download_outlined),
                              selectedIcon:
                                  Icon(Icons.download_rounded, size: 28),
                              label: 'Downloads',
                            ),
                          ],
                        ),
                      ),
                    ),
            );
          }
        },
      ),
    );
  }
}
