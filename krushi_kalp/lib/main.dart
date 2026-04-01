import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'presentation/widgets/common/network_aware_wrapper.dart';
import 'data/services/local_caching_service.dart';

import 'core/env/env.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'utils/crashlytics_service.dart';
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

  // 3. Load Environment Variables & DB
  await LocalCachingService.init();

  // 4. Initialize Supabase
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
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
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      title: 'Krushi Kalp',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: NetworkAwareWrapper(child: child!),
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: double.infinity, name: DESKTOP),
        ],
      ),
    );
  }
}
