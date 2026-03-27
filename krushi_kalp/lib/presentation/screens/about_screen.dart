import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';
import '../../data/services/app_config_service.dart';
import '../widgets/common/network_error_state.dart';
import 'package:shimmer/shimmer.dart';
import '../../utils/responsive.dart'; 

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: AppConfigService.fetchAboutConfig(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading(context);
          }
          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(title: const Text('About Krushi Kalp')),
              body: NetworkErrorState(
                message: 'Unable to load info. Please check your connection.',
                onRetry: () {
                  Navigator.pushReplacementNamed(context, '/about');
                },
              ),
            );
          }

          final data = snapshot.data ?? {};
          return CustomScrollView(
            slivers: [
              const SliverAppBar(
                title: Text("About Krushi Kalp"),
                pinned: true,
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md + MediaQuery.of(context).padding.bottom,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _HeroCard(data: data),
                    SizedBox(height: AppSpacing.lg),
                    _DynamicSectionsList(data: data),
                    SizedBox(height: AppSpacing.lg),
                    _KeyFeaturesSection(data: data),
                    SizedBox(height: AppSpacing.md),
                    _SupportCard(data: data),
                    SizedBox(height: AppSpacing.xl),
                    _FooterText(data: data),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(title: Text("About Krushi Kalp"), pinned: true),
        SliverPadding(
          padding: EdgeInsets.all(AppSpacing.md),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Shimmer.fromColors(
                baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                highlightColor: Theme.of(context).colorScheme.surface,
                child: Column(
                  children: [
                    Container(height: context.hp(25), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg))),
                    SizedBox(height: AppSpacing.md),
                    Container(height: context.hp(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg))),
                    SizedBox(height: AppSpacing.md),
                    Container(height: context.hp(30), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg))),
                  ],
                ),
              )
            ]),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _HeroCard({required this.data});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          // Tractor Icon (Replacing Logo)
          Center(
            child: Container(
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.agriculture_rounded,
                size: context.wp(15),
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            data['app_name'] ?? 'Krushi Kalp',
            style: AppTypography.display.copyWith(
              color: theme.colorScheme.primary,
              fontSize: context.sp(28),
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              'Version ${data['version'] ?? ''}',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: context.sp(12),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            data['tagline'] ?? '',
            textAlign: TextAlign.center,
            style: AppTypography.bodyLabel.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DynamicSectionsList extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DynamicSectionsList({required this.data});

  @override
  Widget build(BuildContext context) {
    final sections = List<Map<String, dynamic>>.from(data['sections'] ?? []);
    if (sections.isEmpty) return const SizedBox.shrink();

    return Column(
      children: sections.map((s) => _SectionCard(section: s)).toList(),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Map<String, dynamic> section;
  const _SectionCard({required this.section});

  IconData _iconFromString(String name) {
    const map = {
      'auto_awesome': Icons.auto_awesome,
      'mission': Icons.flag,
      'vision': Icons.visibility,
      'history': Icons.history,
      'group': Icons.group,
      'agriculture': Icons.agriculture,
      'school': Icons.school,
      'star': Icons.star,
    };
    return map[name] ?? Icons.auto_awesome;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: AppSpacing.lg),
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _iconFromString(section['icon'] ?? 'auto_awesome'),
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                section['title'] ?? '',
                style: AppTypography.heading.copyWith(
                  color: theme.colorScheme.primary,
                  fontSize: context.sp(18),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            section['description'] ?? '',
            style: AppTypography.bodyLarge.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyFeaturesSection extends StatelessWidget {
  final Map<String, dynamic> data;
  const _KeyFeaturesSection({required this.data});

  IconData _iconFromString(String name) {
    const map = {
      'quiz': Icons.quiz,
      'menu_book': Icons.menu_book,
      'bar_chart': Icons.bar_chart,
      'science': Icons.science,
      'agriculture': Icons.agriculture,
      'school': Icons.school,
      'emoji_events': Icons.emoji_events,
      'chat': Icons.chat,
      'download': Icons.download,
      'star': Icons.star,
    };
    return map[name] ?? Icons.help_outline;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final features = List<Map<String, dynamic>>.from(data['features'] ?? []);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.sm),
          child: Text(
            'Key Features',
            style: AppTypography.heading.copyWith(
              color: theme.colorScheme.primary,
              fontSize: context.sp(18),
            ),
          ),
        ),
        ...features.map((f) => Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.sm),
          child: Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.02),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    _iconFromString(f['icon']?.toString() ?? ''),
                    color: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f['title'] ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: context.sp(16),
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        f['subtitle'] ?? '',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: context.sp(14),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        )),
      ],
    );
  }
}

class _SupportCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _SupportCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final support = data['support'] ?? {};
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            support['support_label'] ?? 'Need Support?',
            style: AppTypography.heading.copyWith(
              color: theme.colorScheme.onPrimary,
              fontSize: context.sp(18),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            support['support_description'] ?? '',
            style: TextStyle(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
              fontSize: context.sp(14),
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(Icons.email, color: theme.colorScheme.onPrimary, size: context.sp(18)),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    support['email'] ?? '',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(Icons.send, color: theme.colorScheme.onPrimary, size: context.sp(18)),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    support['telegram'] ?? '',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterText extends StatelessWidget {
  final Map<String, dynamic> data;
  const _FooterText({required this.data});

  @override
  Widget build(BuildContext context) {
    // REMOVED: Footer Text Section (jfjf field)
    return const SizedBox.shrink();
  }
}
