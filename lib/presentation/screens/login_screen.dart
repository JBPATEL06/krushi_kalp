import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:krushi_kalp/presentation/screens/admin/admin_main_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import 'main_screen.dart';
import '../../data/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../widgets/common/primary_button.dart';
import '../widgets/common/custom_text_field.dart';
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

      if (role == 'Admin') {
        debugPrint("LoginScreen: Navigating to AdminMainScreen");
        NotificationService().connectAdmin();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AdminMainScreen()),
        );
      } else {
        debugPrint("LoginScreen: Navigating to MainScreen");
        NotificationService().connectUser();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } else {
      debugPrint(
          "LoginScreen: Auth changed but not logged in or loading. SignedIn: ${authProvider.isLoggedIn}, Loading: ${authProvider.isLoading}");
    }
  }

  @override
  void dispose() {
    debugPrint("LoginScreen: Disposing");
    try {
      context.read<AuthProvider>().removeListener(_onAuthChanged);
    } catch (_) {}
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleLogin() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms and Conditions to proceed.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    try {
      await context.read<AuthProvider>().signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Failed: $e')),
        );
      }
    }
  }

  Future<void> _launchTerms() async {
    final Uri url = Uri.parse(
        'https://example.com/terms-and-conditions'); // UPDATE THIS URL IF NEEDED
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not launch Terms and Conditions')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>((p) => p.isLoading);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.1),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
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
                          height: context.h(80),
                          width: context.w(80),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Welcome Back',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Sign in to continue to Krushi Kalp',
                          style: Theme.of(context).textTheme.bodyMedium,
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
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  text: 'I agree with the ',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  children: [
                                    TextSpan(
                                      text: 'Terms and Conditions',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
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
                          text: 'Sign in with Google',
                          isLoading: isLoading,
                          onPressed: _handleGoogleLogin,
                          // icon: Icons.login, // Can add icon if available
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Divider
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md),
                              child: Text(
                                'OR',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        if (kIsWeb) ...[
                          _EmailLoginForm(
                            isLoading: isLoading,
                            onLogin: (email, pass) async {
                              if (!_agreedToTerms) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Please agree to the Terms and Conditions to proceed.'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                                return;
                              }
                              try {
                                await context
                                    .read<AuthProvider>()
                                    .signInWithEmailPassword(email, pass);
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Login Failed: $e')),
                                  );
                                }
                              }
                            },
                          ),
                        ],
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

class _EmailLoginForm extends StatefulWidget {
  final bool isLoading;
  final Function(String, String) onLogin;

  const _EmailLoginForm({required this.isLoading, required this.onLogin});

  @override
  State<_EmailLoginForm> createState() => _EmailLoginFormState();
}

class _EmailLoginFormState extends State<_EmailLoginForm> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextField(
            label: "Email Address",
            hint: "Enter your email",
            controller: _emailController,
            prefixIcon: const Icon(Icons.email_outlined),
            validator: (value) => value != null && value.contains('@')
                ? null
                : 'Enter valid email',
          ),
          const SizedBox(height: AppSpacing.lg),
          CustomTextField(
            label: "Password",
            hint: "Enter your password",
            controller: _passController,
            obscureText: true,
            prefixIcon: const Icon(Icons.lock_outline),
            validator: (value) =>
                value != null && value.length >= 6 ? null : 'Min 6 characters',
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            text: 'Login to Dashboard',
            isLoading: widget.isLoading,
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                widget.onLogin(_emailController.text, _passController.text);
              }
            },
          ),
        ],
      ),
    );
  }
}
