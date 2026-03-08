import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/splash_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/test_provider.dart';
import 'presentation/providers/admin_provider.dart';

import 'presentation/providers/offer_provider.dart';
import 'presentation/providers/navigation_provider.dart';
import 'presentation/providers/cart_provider.dart';
import 'presentation/providers/resource_provider.dart';
import 'presentation/utils/navigator_key.dart';
import 'presentation/widgets/common/responsive_wrapper.dart';
import 'presentation/widgets/common/network_aware_wrapper.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'utils/crashlytics_service.dart';
import 'utils/analytics_navigator_observer.dart';

Future<void> main() async {
  // ── Crashlytics: Initialize Platform Dispatcher (Catch-all for Asynchronous errors) ──
  // This is the most modern way to catch unhandled errors in Flutter.
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  await Firebase.initializeApp();

  // 2. Initialize Crashlytics Service
  await CrashlyticsService.instance.init();

  // ── Crashlytics: Log all synchronous Flutter framework errors ──
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // ── Crashlytics: Log all unhandled asynchronous errors (Modern Approach) ──
  if (!kIsWeb) {
    PlatformDispatcher.instance.onError = (error, stack) {
      CrashlyticsService.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TestProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => OfferProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ResourceProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [AnalyticsNavigatorObserver()],
      debugShowCheckedModeBanner: false,
      title: 'Krushi kalp',
      // ── ACTIVE THEME: User Defined ──
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      // Auto-detects device OS theme
      builder: (context, child) =>
          NetworkAwareWrapper(child: ResponsiveWrapper(child: child!)),

      home: const SplashScreen(),
    );
  }
}
