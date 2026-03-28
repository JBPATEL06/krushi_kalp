import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';
import '../widgets/common/responsive_wrapper.dart';

class MaintenanceScreen extends StatelessWidget {
  final String? error;
  final VoidCallback onRetry;

  const MaintenanceScreen({
    super.key,
    this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Engineering/Construction Icon
              Container(
                width: context.w(120),
                height: context.w(120),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.engineering_rounded,
                  size: context.sp(64), // FIXED
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Title
              Text(
                'Under Maintenance',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  fontSize: context.sp(24), // FIXED
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),

              // Message
              Text(
                error ??
                    'We are currently performing scheduled maintenance to improve our services. Please check back soon.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                  fontSize: context.sp(14), // FIXED
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Retry Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: Icon(Icons.refresh_rounded,
                      size: context.sp(18)), // FIXED
                  label: Text('Check Again',
                      style: TextStyle(fontSize: context.sp(14))), // FIXED
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Back to Login (Safety exit)
              TextButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: Text(
                  'Back to Start',
                  style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: context.sp(14)), // FIXED
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
