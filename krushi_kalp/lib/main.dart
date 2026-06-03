import 'dart:async';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'presentation/widgets/common/network_aware_wrapper.dart';
import 'data/services/local_caching_service.dart';

import 'core/env/env.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'utils/crashlytics_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart:
          false, // Disable autoStart to prevent Android 14 Foreground crash!
      isForegroundMode:
          false, // Will be dynamically promoted when upload begins
      notificationChannelId: 'krushi_background_service',
      initialNotificationTitle: 'Krushi Kalp',
      initialNotificationContent: 'Preparing file transfer...',
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
  // 1. Minimum initialization for background life-cycle
  WidgetsFlutterBinding.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });

    // ── REAL-TIME PROGRESS UPDATE ──────────────────────────────────────────
    service.on('updateProgress').listen((event) {
      if (event != null) {
        final title =
            event['title'] as String? ?? 'Krushi Kalp Transfer Service';
        final content = event['content'] as String? ?? 'Processing...';
        service.setForegroundNotificationInfo(
          title: title,
          content: content,
        );
      }
    });

    service.on('clearProgress').listen((event) {
      if (event != null) {
        final content = event['content'] as String? ?? 'Transfer complete';
        service.setForegroundNotificationInfo(
          title: 'Krushi Kalp',
          content: content,
        );
      }
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });
}

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Firebase and Crashlytics (Foundational)
    await Firebase.initializeApp();
    await CrashlyticsService.instance.init();

    FlutterError.onError = (FlutterErrorDetails details) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

    // 2. Critical Core Services (Blocking)
    // We MUST await these to ensure the app is stable and database is ready.
    await LocalCachingService.init();
    await initializeService();

    // 3. Initialize Supabase
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );

    // 4. Run App
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('──────────────────────────────────────────────────────────');
    debugPrint('CRITICAL STARTUP ERROR: $error');
    debugPrint('STACK TRACE: $stack');
    debugPrint('──────────────────────────────────────────────────────────');

    try {
      CrashlyticsService.instance.recordError(error, stack, fatal: true);
    } catch (e) {
      debugPrint('Could not log to Crashlytics (likely not initialized): $e');
    }
  });
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
