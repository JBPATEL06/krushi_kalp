import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:krushi_kalp/core/theme/app_motion.dart'; // MODIFIED: Added AppMotion token import
import 'package:krushi_kalp/core/theme/app_radius.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';

import '../../utils/error_utils.dart';
import 'main_screen.dart';
import 'admin/admin_main_screen.dart';
import '../../data/services/notification_service.dart';
import '../../core/theme/app_spacing.dart';
import '../widgets/common/primary_button.dart';
import '../widgets/common/premium_card.dart';
import 'package:krushi_kalp/presentation/widgets/common/responsive_wrapper.dart';
import '../../utils/crashlytics_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
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
      duration: AppMotion
          .slow, // MODIFIED: was Duration(milliseconds: 1200) → now AppMotion.slow (500ms)
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
            begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToAuth();
    });
  }

  void _listenToAuth() {
    ref.listenManual(authNotifierProvider, (AuthState? previous, AuthState next) {
      if (next.isLoggedIn && !next.isLoading) {
        final role = next.userRole;
        if (role != 'Admin') {
          NotificationService().connectUser();
          if (mounted) context.go('/');
        } else {
          NotificationService().connectAdmin();
          if (mounted) context.go('/admin');
        }
      }
    });
  }

  Future<void> _handleGoogleLogin() async {
    if (!_agreedToTerms) {
      ErrorUtils.showError(
          context, 'Please agree to the Terms and Conditions to proceed.');
      return;
    }
    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    } catch (e, s) {
      CrashlyticsService().recordError(e, s);
      if (mounted) {
        ErrorUtils.showError(context, 'Failed to sign in with Google.');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background UI
          Positioned(
            top: -context.h(100),
            right: -context.w(100),
            child: Container(
              width: context.w(300),
              height: context.h(300),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -context.h(50),
            left: -context.w(50),
            child: Container(
              width: context.w(200),
              height: context.h(200),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
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
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            "assets/images/applogo.png",
                            height: context.h(130),
                            width: context.w(130),
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Welcome to Krushi Kalp',
                          style: theme.textTheme.headlineMedium?.copyWith(
                                fontSize: context.sp(28),
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Sign in to continue to Krushi Kalp',
                          style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: context.sp(14),
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xl),

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
                              activeColor: theme.colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.xs),
                              ),
                            ),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  text: 'I agree with the ',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                        fontSize: context.sp(12),
                                      ),
                                  children: [
                                    TextSpan(
                                      text: 'Terms and Conditions',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: context.sp(12),
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
                        const SizedBox(height: AppSpacing.lg),

                        PrimaryButton(
                          text: 'Continue with Google',
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

  Future<void> _launchTerms() async {
    final Uri url = Uri.parse('https://krushikalp.com/terms');
    if (!await launchUrl(url)) {
      if (mounted) {
        ErrorUtils.showError(context, 'Could not launch terms and conditions');
      }
    }
  }
}
