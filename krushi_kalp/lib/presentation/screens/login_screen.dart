import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:krushi_kalp/core/theme/app_radius.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../../utils/error_utils.dart';
import 'main_screen.dart';
import 'admin/admin_main_screen.dart';
import '../../data/services/notification_service.dart';
import '../../core/theme/app_spacing.dart';
import '../widgets/common/primary_button.dart';
import '../widgets/common/premium_card.dart';
import 'package:krushi_kalp/presentation/widgets/common/responsive_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
            begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      authProvider.addListener(_onAuthChanged);
    });
  }

  void _onAuthChanged() {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();

    if (authProvider.isLoggedIn && !authProvider.isLoading) {
      final role = authProvider.userRole;
      authProvider.removeListener(_onAuthChanged);

      if (role != 'Admin') {
        NotificationService().connectUser();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        NotificationService().connectAdmin();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AdminMainScreen()),
        );
      }
    } else {}
  }

  @override
  void dispose() {
    try {
      context.read<AuthProvider>().removeListener(_onAuthChanged);
    } catch (_) {}
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleLogin() async {
    if (!_agreedToTerms) {
      ErrorUtils.showError(
          context, 'Please agree to the Terms and Conditions to proceed.');
      return;
    }
    try {
      await context.read<AuthProvider>().signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ErrorUtils.showError(context, e);
      }
    }
  }

  Future<void> _launchTerms() async {
    final Uri url = Uri.parse(
        'https://example.com/terms-and-conditions'); // UPDATE THIS URL IF NEEDED
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ErrorUtils.showError(context, 'Could not launch Terms and Conditions');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>((p) => p.isLoading);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          // Background Elements
          Positioned(
            top: -context.h(100), // FIXED: context.h(100)
            right: -context.w(100), // FIXED: context.w(100)
            child: Container(
              width: context.w(300), // FIXED: context.w(300)
              height: context.h(300), // FIXED: context.h(300)
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -context.h(50), // FIXED: context.h(50)
            left: -context.w(50), // FIXED: context.w(50)
            child: Container(
              width: context.w(200), // FIXED: context.w(200)
              height: context.h(200), // FIXED: context.h(200)
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context)
                    .colorScheme
                    .secondary
                    .withValues(alpha: 0.1),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg + MediaQuery.of(context).padding.bottom,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: PremiumCard(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          "assets/images/notification_logo.png",
                          height: context.h(130), // FIXED
                          width: context.w(130), // FIXED
                        ),
                        const SizedBox(
                            height: AppSpacing.lg), // FIXED: AppSpacing.lg
                        Text(
                          'Welcome Back',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontSize:
                                    context.sp(28), // FIXED: context.sp(28)
                              ),
                        ),
                        const SizedBox(
                            height: AppSpacing.sm), // FIXED: AppSpacing.sm
                        Text(
                          'Sign in to continue to Krushi Kalp',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize:
                                        context.sp(14), // FIXED: context.sp(14)
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(
                            height: AppSpacing.xl), // FIXED: AppSpacing.xl

                        // Terms Checkbox
                        Row(
                          children: [
                            Checkbox(
                              value: _agreedToTerms,
                              onChanged: (value) {
                                setState(() {
                                  _agreedToTerms = value ?? false;
                                });
                              },
                              activeColor:
                                  Theme.of(context).colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppRadius.xs), // FIXED: AppRadius.xs
                              ),
                            ),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  text: 'I agree with the ',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontSize: context
                                            .sp(12), // FIXED: context.sp(12)
                                      ),
                                  children: [
                                    TextSpan(
                                      text: 'Terms and Conditions',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: context
                                            .sp(12), // FIXED: context.sp(12)
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = _launchTerms,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                            height: AppSpacing.lg), // FIXED: AppSpacing.lg

                        PrimaryButton(
                          text: 'Sign in with Google',
                          isLoading: isLoading,
                          onPressed: _handleGoogleLogin,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
