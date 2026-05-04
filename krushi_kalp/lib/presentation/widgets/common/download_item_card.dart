import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import 'modern_card.dart';
import 'responsive_wrapper.dart';

/// Purchased-item card used in purchased_tests_screen and my_resources_screen.
///
/// Horizontal layout:
///   â”Œ──────────────────────────────────────────────â”
///   │        │  Title (max 2 lines)                 │
///   │ IMAGE  │  Subtitle                            │
///   │ fills  │─────────────────────────────────────│
///   │ pane   │            [ Action button ]         │
///   └──────────────────────────────────────────────┘
///
/// Image uses [BoxFit.cover] inside [ClipRRect] — fills container completely,
/// no letterboxing, no empty space.
class DownloadItemCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? coverUrl;
  final Widget customAction;
  final VoidCallback onTap;
  final String? heroTag;

  const DownloadItemCard({
    super.key,
    required this.title,
    this.subtitle,
    this.coverUrl,
    required this.customAction,
    required this.onTap,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Card height: 18% of screen height — matches StoreItemCard for visual consistency
    final cardHeight = MediaQuery.of(context).size.height * 0.18;

    return RepaintBoundary(
      child: ModernCard(
        animate: false,
        onTap: onTap,
        padding: EdgeInsets.zero,
      child: SizedBox(
        height: cardHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── LEFT: IMAGE PANE (flex 2 = ~40%) ─────────────────────────
            Flexible(
              flex: 2,
              child: Hero(
                tag: heroTag ?? 'download_${Object.hash(title, coverUrl)}',
                child: ClipRRect(
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(AppRadius.lg),
                  ),
                  child: _buildImage(context, theme),
                ),
              ),
            ),

            // ── RIGHT: CONTENT PANE (flex 3 = ~60%) ─────────────────────
            Flexible(
              flex: 3,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(AppSpacing.md),
                  vertical: context.h(AppSpacing.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title + subtitle block
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                            height: 1.25,
                            fontSize: context.sp(18),
                          ),
                        ),
                        if (subtitle != null) ...[
                          SizedBox(height: context.h(AppSpacing.xs)),
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: context.sp(15),
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Action button — properly sized to match DownloadActionButton minimum height
                    SizedBox(
                      height: context.h(48),
                      width: double.infinity,
                      child: customAction,
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
    return Container(
      // Use transparent to inherit card surface color directly - "blends with UI"
      color: Colors.transparent,
      child: (coverUrl != null && coverUrl!.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: coverUrl!,
              // BoxFit.cover: fills container completely for consistency
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  _placeholder(context, theme, loading: true),
              errorWidget: (_, __, ___) => _placeholder(context, theme),
            )
          : _placeholder(context, theme),
    );
  }

  Widget _placeholder(BuildContext context, ThemeData theme,
      {bool loading = false}) {
    return Center(
      child: loading
          ? SizedBox(
              width: context.w(20),
              height: context.w(20),
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
              ),
            )
          : Icon(
              Icons.school_outlined,
              size: context.sp(30),
              color: theme.colorScheme.primary.withValues(alpha: 0.25),
            ),
    );
  }
}
