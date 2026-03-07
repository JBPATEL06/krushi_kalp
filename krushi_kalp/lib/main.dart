import 'dart:async';
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

Future<void> main() async {
  // ── Crashlytics: Catch all uncaught async errors ──
  // runZonedGuarded must wrap EVERYTHING including ensureInitialized + runApp
  // so they share the same Dart zone (avoids "Zone mismatch" assertion).
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await dotenv.load(fileName: ".env");
      await Firebase.initializeApp();

      // Initialize Supabase
      await Supabase.initialize(
          url: dotenv.env['SUPABASE_URL']!,
          anonKey: dotenv.env['SUPABASE_ANON_KEY']!);

      // ── Crashlytics: Catch all Flutter framework errors ──
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

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
    },
    (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Krushi kalp',
      // ── ACTIVE THEME: User Defined ──
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      // Auto-detects device OS theme
      builder: (context, child) => NetworkAwareWrapper(
        child: ResponsiveWrapper(child: child!),
      ),

      home: const SplashScreen(),
    );
  }
}
