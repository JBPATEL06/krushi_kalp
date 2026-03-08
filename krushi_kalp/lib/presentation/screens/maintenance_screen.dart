import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
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
                  size: 64,
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
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Retry Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Check Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
                  style: TextStyle(color: colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
