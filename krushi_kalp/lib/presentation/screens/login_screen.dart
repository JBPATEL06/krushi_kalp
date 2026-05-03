import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:krushi_kalp/core/theme/app_motion.dart'; // MODIFIED: Added AppMotion token import
import 'package:krushi_kalp/core/theme/app_radius.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'package:url_launcher/url_launcher.dart';
import '../../data/services/app_config_service.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';

import '../../data/services/notification_service.dart';
import 'package:krushi_kalp/core/theme/app_spacing.dart';
import 'package:krushi_kalp/core/router/route_constants.dart';
import '../widgets/common/primary_button.dart';
import '../widgets/common/premium_card.dart';
import 'package:krushi_kalp/presentation/widgets/common/responsive_wrapper.dart';
import '../../utils/crashlytics_service.dart';
import '../../utils/error_utils.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion
          .slow, // MODIFIED: was Duration(milliseconds: 1200) â†’ now AppMotion.slow (500ms)
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
    ref.listenManual(authProvider, (AuthState? previous, AuthState next) {
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

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ErrorUtils.showError(
          context, 'Please agree to the Terms and Conditions to proceed.');
      return;
    }

    try {
      await ref.read(authProvider.notifier).loginWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
    } catch (e, s) {
      CrashlyticsService().recordError(e, s);
      if (mounted) {
        ErrorUtils.showError(context, e);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    if (!_agreedToTerms) {
      ErrorUtils.showError(
          context, 'Please agree to the Terms and Conditions to proceed.');
      return;
    }
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
    } catch (e, s) {
      CrashlyticsService().recordError(e, s);
      if (mounted) {
        if (e is AuthException && (e.code == 'provider_already_linked' || e.code == 'email_already_used')) {
          _showPasswordLinkDialog();
        } else {
          ErrorUtils.showError(context, e);
        }
      }
    }
  }

  void _showPasswordLinkDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Conflict'),
        content: const Text(
            'This email is already registered with a password. Please log in using your email and password first. '
            'Once logged in, you can link your Google account in the Profile settings for future use.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
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
                        
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Enter email';
                                  if (!value.contains('@')) return 'Invalid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(_isPasswordVisible 
                                      ? Icons.visibility_off 
                                      : Icons.visibility),
                                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                  ),
                                ),
                                obscureText: !_isPasswordVisible,
                                validator: (value) => (value == null || value.isEmpty) ? 'Enter password' : null,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => context.push(RouteConstants.forgotPassword),
                                  child: const Text('Forgot Password?'),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

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
                          text: 'Login',
                          isLoading: isLoading,
                          onPressed: _handleEmailLogin,
                        ),

                        const SizedBox(height: AppSpacing.xl),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                              child: Text('OR', style: theme.textTheme.bodySmall),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        OutlinedButton.icon(
                          onPressed: isLoading ? null : _handleGoogleLogin,
                          icon: const Icon(Icons.login),
                          label: const Text('Continue with Google'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account? ", style: theme.textTheme.bodyMedium),
                            GestureDetector(
                              onTap: () => context.push('/signup'),
                              child: Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
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
    final Uri url = Uri.parse(AppConfigService.termsUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ErrorUtils.showError(context, 'Could not launch terms and conditions');
      }
    }
  }
}
