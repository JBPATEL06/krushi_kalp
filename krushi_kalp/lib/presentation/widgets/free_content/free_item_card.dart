import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../common/responsive_wrapper.dart';

/// A premium horizontal card for free content (Mocks/Resources).
/// Optimized for responsiveness and high clarity.
class FreeItemCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? typeLabel;
  final String? coverUrl;
  final String actionLabel;
  final VoidCallback onActionTap;
  final VoidCallback onTap;
  final String? heroTag;
  final bool isPurchased;

  const FreeItemCard({
    super.key,
    required this.title,
    this.subtitle,
    this.typeLabel,
    this.coverUrl,
    required this.actionLabel,
    required this.onActionTap,
    required this.onTap,
    this.heroTag,
    this.isPurchased = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.15 : 0.3),
        ),
      ),
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // â”€â”€ IMAGE PANE (40% roughly) â”€â”€
              SizedBox(
                width: context.w(110),
                child: Hero(
                  tag: heroTag ?? 'free_${title}_${DateTime.now().millisecond}',
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImage(context, theme),
                      if (isPurchased)
                        Positioned(
                          top: AppSpacing.xs,
                          left: AppSpacing.xs,
                          child: _badge(
                            'Owned',
                            bg: theme.colorScheme.primary,
                            fg: theme.colorScheme.onPrimary,
                            context: context,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // â”€â”€ CONTENT PANE (60%) â”€â”€
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (typeLabel != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                typeLabel!.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.tertiary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                  fontSize: context.sp(10),
                                ),
                              ),
                            ),
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.onSurface,
                              fontSize: context.sp(16),
                              height: 1.2,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: context.sp(12),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        height: context.h(36),
                        child: ElevatedButton(
                          onPressed: isPurchased ? onTap : onActionTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPurchased
                                ? theme.colorScheme.surfaceContainerHighest
                                : theme.colorScheme.tertiary,
                            foregroundColor: isPurchased
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.onTertiary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            isPurchased ? 'OPEN' : actionLabel.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: context.sp(12),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, ThemeData theme) {
    if (coverUrl != null && coverUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: coverUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => _placeholder(theme),
      );
    }
    return _placeholder(theme);
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primary.withValues(alpha: 0.05),
      child: Center(
        child: Icon(
          Icons.school_outlined,
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          size: 32,
        ),
      ),
    );
  }

  Widget _badge(String label,
      {required Color bg, required Color fg, required BuildContext context}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: context.sp(10),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
