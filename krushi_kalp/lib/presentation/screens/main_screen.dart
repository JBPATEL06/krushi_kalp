import 'package:flutter/material.dart';
import 'package:krushi_kalp/presentation/screens/purchased_tests_screen.dart'; // Show only mock tests
import 'package:krushi_kalp/presentation/screens/store_screen.dart';
import 'downloads_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import '../providers/navigation_provider.dart';
import 'profile_screen.dart';
import '../providers/test_provider.dart';
import '../providers/resource_provider.dart';

import 'package:package_info_plus/package_info_plus.dart';
import '../../data/services/app_config_service.dart';
import 'maintenance_screen.dart';
import 'update_required_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // _selectedIndex moved to NavigationProvider

  AuthProvider? _authProvider;

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
    
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    _authProvider?.addListener(_handleAuthChange);

    // Initial Sync for logged in user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAppStatus(); // NEW: Gate check
      _initialSync();
    });
  }

  Future<void> _checkAppStatus() async {
    final auth = context.read<AuthProvider>();
    if (auth.isAdmin) {
      
      return;
    }

    // Ensure configs are fresh (though Splash usually fetches them)
    // We don't await here to avoid blocking UI, but Splash ensures they are ready.

    // 1. Maintenance Check
    if (AppConfigService.isMaintenanceMode) {
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MaintenanceScreen(
              error: AppConfigService.maintenanceMessage,
              onRetry: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MainScreen()),
              ),
            ),
          ),
        );
      }
      return;
    }

    // 2. Version Check
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
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) {
      final userId = auth.currentUser!.id;
      

      // Trigger background fetches (Non-blocking)
      final testProvider = context.read<TestProvider>();
      final resourceProvider = context.read<ResourceProvider>();

      // We don't await them so they run in the background post-login
      testProvider.fetchTests();
      testProvider.fetchUserTests(userId);
      resourceProvider.fetchAll();
      resourceProvider.fetchPurchasedResources(userId);
    }
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_handleAuthChange);
    super.dispose();
  }

  void _handleAuthChange() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    
    final theme = Theme.of(context);
    return Consumer<NavigationProvider>(
      builder: (context, navProvider, child) {
        return PopScope(
          canPop: navProvider.selectedIndex == 0, // Allow pop only on Home tab
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;

            // If not on Home tab, go to Home instead of exiting
            if (navProvider.selectedIndex != 0) {
              navProvider.setIndex(0);
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
                      if (navProvider.selectedIndex < 4)
                        NavigationRail(
                          selectedIndex: navProvider.selectedIndex,
                          onDestinationSelected: (index) {
                            if (index == 2) {
                              navProvider.setStoreCategory('All');
                            }
                            navProvider.setIndex(index);
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
                      if (navProvider.selectedIndex < 4)
                        const VerticalDivider(thickness: 1, width: 1),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: IndexedStack(
                            index: navProvider.selectedIndex,
                            children: _screens,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                // Mobile
                return Scaffold(
                  body: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: IndexedStack(
                      index: navProvider.selectedIndex,
                      children: _screens,
                    ),
                  ),
                  bottomNavigationBar: navProvider.selectedIndex >= 4
                      ? null
                      : SafeArea(
                          bottom: true,
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.shadow
                                      .withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, -5),
                                ),
                              ],
                            ),
                            child: NavigationBarTheme(
                              data: NavigationBarThemeData(
                                backgroundColor: theme.colorScheme.surface,
                                elevation: 0,
                                indicatorColor:
                                    theme.colorScheme.primary.withOpacity(0.1),
                                labelBehavior:
                                    NavigationDestinationLabelBehavior
                                        .alwaysShow,
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
                                iconTheme:
                                    WidgetStateProperty.resolveWith((states) {
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
                                selectedIndex: navProvider.selectedIndex,
                                onDestinationSelected: (index) {
                                  if (index == 2) {
                                    navProvider.setStoreCategory('All');
                                  }
                                  navProvider.setIndex(index);
                                },
                                destinations: const [
                                  NavigationDestination(
                                    icon: Icon(Icons.home_outlined),
                                    selectedIcon:
                                        Icon(Icons.home_rounded, size: 28),
                                    label: 'Home',
                                  ),
                                  NavigationDestination(
                                    icon: Icon(Icons.quiz_outlined),
                                    selectedIcon:
                                        Icon(Icons.quiz_rounded, size: 28),
                                    label: 'Mocks',
                                  ),
                                  NavigationDestination(
                                    icon: Icon(Icons.storefront_outlined),
                                    selectedIcon: Icon(Icons.storefront_rounded,
                                        size: 28),
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
                        ),
                );
              }
            },
          ),
        );
      },
    );
  }
}
