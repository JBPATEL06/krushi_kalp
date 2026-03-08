import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
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
import 'data/services/notification_service.dart';
import 'data/services/transfer_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase & Analytics
  await Firebase.initializeApp();
  await CrashlyticsService.instance.init();

  // 2. Setup Crashlytics error reporting
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  if (!kIsWeb) {
    PlatformDispatcher.instance.onError = (error, stack) {
      CrashlyticsService.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // 3. Load Environment Variables
  await dotenv.load(fileName: ".env");

  // 4. Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // 5. Initialize Notification Engine
  final notificationService = NotificationService();
  await notificationService.initialize();

  // 6. Initialize specialized Transfer Notifications
  final transferNotifications = TransferNotificationService();
  transferNotifications.initialize(notificationService.plugin);
  await transferNotifications.setupChannel();

  // 7. Request Notification Permissions (Android 13+)
  if (!kIsWeb) {
    await Permission.notification.isDenied.then((value) {
      if (value) Permission.notification.request();
    });
  }

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
      title: 'Krushi Kalp',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      builder: (context, child) =>
          NetworkAwareWrapper(child: ResponsiveWrapper(child: child!)),
      home: const SplashScreen(),
    );
  }
}
