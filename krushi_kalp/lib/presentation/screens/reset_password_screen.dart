import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../providers/auth_notifier.dart';
import '../../utils/error_utils.dart';
import '../widgets/common/primary_button.dart';
import '../widgets/common/premium_card.dart';
import 'package:krushi_kalp/presentation/widgets/common/responsive_wrapper.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handlePasswordUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(authNotifierProvider.notifier).updatePassword(
            _passwordController.text.trim(),
          );
      if (mounted) {
        setState(() => _isSuccess = true);
        // After successful update, we should signed out to force a fresh login with new credentials
        // Or redirect to home if Supabase keeps them logged in.
        // For security, usually forcing login is better, but Supabase standard is to stay logged in.
        // We'll redirect to Home in 2 seconds.
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) context.go('/');
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorUtils.showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Don't allow back during reset flow for security
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: CircleAvatar(
              radius: 120,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.05),
            ),
          ),
          
          SafeArea(
            child: ResponsiveWrapper(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.security_update_good_rounded,
                            size: 80,
                            color: Colors.green,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Create New Password',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _isSuccess
                                ? 'Password updated successfully! Redirecting you to home...'
                                : 'Almost there! Create a strong new password to secure your account.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          
                          if (!_isSuccess) ...[
                            Form(
                              key: _formKey,
                              child: PremiumCard(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: !_isPasswordVisible,
                                        decoration: InputDecoration(
                                          labelText: 'New Password',
                                          prefixIcon: const Icon(Icons.lock_outline),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _isPasswordVisible
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _isPasswordVisible = !_isPasswordVisible;
                                              });
                                            },
                                          ),
                                          border: const OutlineInputBorder(),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter a new password';
                                          }
                                          if (value.length < 6) {
                                            return 'Password must be at least 6 characters';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      TextFormField(
                                        controller: _confirmPasswordController,
                                        obscureText: !_isPasswordVisible,
                                        decoration: const InputDecoration(
                                          labelText: 'Confirm New Password',
                                          prefixIcon: Icon(Icons.lock_reset_outlined),
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (value) {
                                          if (value != _passwordController.text) {
                                            return 'Passwords do not match';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            PrimaryButton(
                              text: 'Update Password',
                              onPressed: _handlePasswordUpdate,
                              isLoading: authState.isLoading,
                            ),
                          ] else ...[
                            const Center(child: CircularProgressIndicator()),
                          ],
                        ],
                      ),
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
