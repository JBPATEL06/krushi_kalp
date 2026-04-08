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
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false, // Start only when upload begins
      isForegroundMode: true,
      notificationChannelId: 'krushi_background_service',
      initialNotificationTitle: 'Krushi Kalp Upload Service',
      initialNotificationContent: 'Ready to process file...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    // Explicitly set as foreground service immediately on start to show notification
    service.setAsForegroundService();

    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });

    // ── REAL-TIME PROGRESS UPDATE ──────────────────────────────────────────
    // Receive progress events from the main isolate and update the foreground
    // notification (ID 888). This is the only notification MIUI guarantees
    // to keep visible while the foreground service is running.
    service.on('updateProgress').listen((event) {
      if (event != null) {
        final title = event['title'] as String? ?? 'Krushi Kalp Upload Service';
        final content = event['content'] as String? ?? 'Processing...';
        service.setForegroundNotificationInfo(
          title: title,
          content: content,
        );
      }
    });

    // Reset foreground notification to idle state after upload completes/fails
    service.on('clearProgress').listen((event) {
      if (event != null) {
        final content = event['content'] as String? ?? 'Ready to process file...';
        service.setForegroundNotificationInfo(
          title: 'Krushi Kalp Upload Service',
          content: content,
        );
      }
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 0. Initialize Background Service
  await initializeService();

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
