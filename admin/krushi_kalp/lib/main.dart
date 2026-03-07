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
import 'presentation/providers/resource_provider.dart'; // NEW
import 'presentation/utils/navigator_key.dart';
import 'presentation/widgets/common/responsive_wrapper.dart'; // NEW
import 'presentation/widgets/common/network_aware_wrapper.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Firebase.initializeApp(); // Initialize Firebase

  // Initialize Supabase
  await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TestProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => OfferProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ResourceProvider()), // NEW
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
      navigatorKey: navigatorKey, // Register Global Key
      debugShowCheckedModeBanner: false,
      title: 'Krushi kalp',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      builder: (context, child) => NetworkAwareWrapper(
        child: SafeArea(
          child: ResponsiveWrapper(child: child!),
        ),
      ),
      home: const SplashScreen(), // Start with Splash Screen
    );
  }
}
