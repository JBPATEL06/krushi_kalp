import 'package:flutter/material.dart';
import 'package:krushi_kalp/utils/responsive.dart';
import 'package:krushi_kalp/core/theme/app_radius.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../data/services/banner_service.dart';
import '../../../../../domain/models/home_banner.dart';
import 'package:krushi_kalp/core/theme/app_spacing.dart';
import '../../../../../data/services/app_config_service.dart';
import '../../../../utils/ui_helpers.dart';
import '../../../../../utils/error_utils.dart';
import '../../../../../utils/crashlytics_service.dart';

class BannerManagementTab extends StatefulWidget {
  const BannerManagementTab({super.key});

  @override
  State<BannerManagementTab> createState() => _BannerManagementTabState();
}

class _BannerManagementTabState extends State<BannerManagementTab> {
  bool _isUploading = false;
  bool _autoScroll = false;
  int _interval = 15;

  @override
  void initState() {
    super.initState();
    _autoScroll = AppConfigService.bannerAutoScroll;
    _interval = AppConfigService.bannerInterval;
  }

  // ─── Save Banner Settings ─────────────────────────
  Future<void> _saveSettings(bool autoScroll, int interval) async {
    try {
      await AppConfigService.updateConfig('banner_settings', {
        'auto_scroll': autoScroll,
        'interval': interval,
      });
      if (mounted) {
        setState(() {
          _autoScroll = autoScroll;
          _interval = interval;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Banner settings saved successfully")),
        );
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'banner_management_tab');
      if (mounted) ErrorUtils.showError(context, e);
    }
  }

  // ─── Show Settings Dialog ──────────────────────────
  void _showSettingsDialog() {
    bool tempAutoScroll = _autoScroll;
    int tempInterval = _interval;

    showAppDialog(
      context: context,
      title: "Banner Carousel Settings",
      content: StatefulBuilder(
        builder: (context, setDialogState) {
          final colorScheme = Theme.of(context).colorScheme;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                title: const Text("Auto Scroll Banners"),
                subtitle: const Text("Automatically slide through banners"),
                value: tempAutoScroll,
                activeThumbColor: colorScheme.primary,
                onChanged: (val) {
                  setDialogState(() => tempAutoScroll = val);
                },
                contentPadding: EdgeInsets.zero,
              ),
              SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Text("Scroll Interval:"),
                  Expanded(
                    child: Slider(
                      value: tempInterval.toDouble(),
                      min: 3,
                      max: 60,
                      divisions: 57,
                      activeColor: colorScheme.primary,
                      inactiveColor: colorScheme.outline.withValues(alpha: 0.3),
                      label: "$tempInterval s",
                      onChanged: tempAutoScroll
                          ? (val) {
                              setDialogState(() => tempInterval = val.toInt());
                            }
                          : null,
                    ),
                  ),
                  Text("$tempInterval s"),
                ],
              ),
            ],
          );
        },
      ),
      confirmText: "Save Settings",
      onConfirm: () => _saveSettings(tempAutoScroll, tempInterval),
    );
  }

  // ─── Upload Multiple New Banners ───────────────────
  Future<void> _uploadBanners() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true, // â† Multiple files
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _isUploading = true);

      for (final file in result.files) {
        if (file.bytes == null) continue;
        await BannerService.instance.uploadBanner(
          file.bytes!,
          file.name,
          title:
              file.name.replaceAll(RegExp(r'\.\w+$'), ''), // Name without ext
          priority: 0,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "${result.files.length} banner(s) uploaded successfully")),
        );
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'banner_management_tab');
      if (mounted) ErrorUtils.showError(context, e);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ─── Replace Image at a Specific Banner ───────────────────
  Future<void> _replaceBannerImage(HomeBanner banner) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null || result.files.single.bytes == null) return;

      setState(() => _isUploading = true);

      await BannerService.instance.replaceBannerImage(
        banner.id,
        banner.imageUrl,
        result.files.single.bytes!,
        result.files.single.name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Banner image replaced successfully")),
        );
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'banner_management_tab');
      if (mounted) ErrorUtils.showError(context, e);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ─── Edit Banner Meta (Title, Priority, Active) ───────────────────
  Future<void> _editBanner(HomeBanner banner) async {
    final titleController = TextEditingController(text: banner.title);
    final priorityController =
        TextEditingController(text: banner.priority.toString());
    bool isActive = banner.isActive;

    await showAppDialog(
      context: context,
      title: "Edit Banner",
      content: StatefulBuilder(
        builder: (ctx, setDialogState) {
          final colorScheme = Theme.of(ctx).colorScheme;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: getPremiumInputDecoration(
                  ctx,
                  labelText: 'Title',
                  prefixIcon: const Icon(Icons.title_rounded),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              TextField(
                controller: priorityController,
                keyboardType: TextInputType.number,
                decoration: getPremiumInputDecoration(
                  ctx,
                  labelText: 'Priority (higher = shown first)',
                  prefixIcon: const Icon(Icons.low_priority_rounded),
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                title: const Text("Active"),
                value: isActive,
                activeThumbColor: colorScheme.primary,
                onChanged: (val) => setDialogState(() => isActive = val),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          );
        },
      ),
      confirmText: "Save",
      onConfirm: () async {
        try {
          await BannerService.instance.updateBannerMeta(
            banner.id,
            title: titleController.text.trim(),
            priority: int.tryParse(priorityController.text) ?? 0,
            isActive: isActive,
          );
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text("Banner updated")));
          }
        } catch (e, stack) {
          CrashlyticsService.instance.recordError(e, stack, reason: 'banner_management_tab');
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text("Error: $e")));
          }
        }
      },
    );
  }

  // ─── Delete Banner ───────────────────
  Future<void> _deleteBanner(HomeBanner banner) async {
    await showAppDialog(
      context: context,
      title: "Delete Banner",
      content: const Text("Are you sure? This cannot be undone."),
      confirmText: "Delete",
      isDestructive: true,
      onConfirm: () async {
        try {
          await BannerService.instance.deleteBanner(banner.id, banner.imageUrl);
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text("Banner deleted")));
          }
        } catch (e, stack) {
          CrashlyticsService.instance.recordError(e, stack, reason: 'banner_management_tab');
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text("Error: $e")));
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: RefreshIndicator(
          onRefresh: () async {
            // StreamBuilder will handle the data, but we force a fetch for safety/UX
            await AppConfigService.fetchConfigs();
          },
          child: Column(
            children: [
              if (_isUploading)
                LinearProgressIndicator(
                    color: colorScheme.primary, minHeight: 2),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isUploading ? null : _uploadBanners,
                        icon: const Icon(Icons.add_photo_alternate_rounded,
                            size: 20),
                        label: Text("Upload Banners",
                            style:
                                TextStyle(fontSize: context.sp(14))), // FIXED
                        style: FilledButton.styleFrom(
                          minimumSize:
                              Size(double.infinity, context.h(48)), // FIXED
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md)), // FIXED
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: IconButton(
                        onPressed: () async {
                          await AppConfigService.fetchConfigs();
                          if (mounted) setState(() {});
                        },
                        icon: Icon(Icons.refresh_rounded,
                            color: colorScheme.primary),
                        tooltip: 'Refresh',
                        style: IconButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md)), // FIXED
                          minimumSize:
                              Size(context.sp(48), context.sp(48)), // FIXED
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: IconButton(
                        onPressed: _showSettingsDialog,
                        icon: Icon(Icons.settings_suggest_rounded,
                            color: colorScheme.primary),
                        tooltip: 'Settings',
                        style: IconButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md)), // FIXED
                          minimumSize:
                              Size(context.sp(48), context.sp(48)), // FIXED
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    _buildSectionHeader(context, "ACTIVE BANNERS"),
                    const Spacer(),
                    Text(
                      "Tap to edit details",
                      style: theme.textTheme.labelSmall?.copyWith(
                        color:
                            colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── Banner List (real-time stream) ──
              Expanded(
                child: StreamBuilder<List<HomeBanner>>(
                  stream: BannerService.instance.streamAllBanners(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline_rounded,
                                  color: colorScheme.error, size: 48),
                              const SizedBox(height: AppSpacing.md),
                              Text("Error: ${snapshot.error}",
                                  style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final banners = snapshot.data!;

                    if (banners.isEmpty) {
                      return Center(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.image_not_supported_rounded,
                                  size: 64,
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.2)),
                              const SizedBox(height: AppSpacing.md),
                              Text("No banners yet",
                                  style: TextStyle(
                                      color: colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.6))),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: banners.length,
                      itemBuilder: (context, index) {
                        final banner = banners[index];
                        return _BannerCard(
                          banner: banner,
                          index: index + 1,
                          total: banners.length,
                          onEdit: () => _editBanner(banner),
                          onReplace: () => _replaceBannerImage(banner),
                          onDelete: () => _deleteBanner(banner),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 0.0), // Reduced
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
          fontSize: context.sp(12), // FIXED
        ),
      ),
    );
  }
}

// ─── Reusable Banner Card Widget ───────────────────────────────────────────
class _BannerCard extends StatelessWidget {
  final HomeBanner banner;
  final int index;
  final int total;
  final VoidCallback onEdit;
  final VoidCallback onReplace;
  final VoidCallback onDelete;

  const _BannerCard({
    required this.banner,
    required this.index,
    required this.total,
    required this.onEdit,
    required this.onReplace,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 21 / 9,
                  child: CachedNetworkImage(
                    imageUrl: banner.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.2),
                      child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: colorScheme.errorContainer.withValues(alpha: 0.2),
                      child: Icon(Icons.broken_image_rounded,
                          color: colorScheme.error),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "#$index / $total",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: banner.isActive
                          ? const Color(0xFF10B981)
                          : colorScheme.error,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      banner.isActive ? "ACTIVE" : "INACTIVE",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          banner.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: context.sp(16)), // FIXED
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Priority Level: ${banner.priority}",
                          style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: context.sp(11)), // FIXED
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionIcon(
                        context,
                        icon: Icons.image_search_rounded,
                        onPressed: onReplace,
                        tooltip: "Replace Image",
                      ),
                      const SizedBox(width: 8),
                      _buildActionIcon(
                        context,
                        icon: Icons.edit_rounded,
                        onPressed: onEdit,
                        tooltip: "Edit details",
                      ),
                      const SizedBox(width: 8),
                      _buildActionIcon(
                        context,
                        icon: Icons.delete_rounded,
                        onPressed: onDelete,
                        color: colorScheme.error,
                        tooltip: "Delete",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcon(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
    required String tooltip,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(context.sp(8)), // FIXED
          decoration: BoxDecoration(
            color: (color ?? colorScheme.primary).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.sm), // FIXED
          ),
          child: Icon(icon,
              color: color ?? colorScheme.primary,
              size: context.sp(20)), // FIXED
        ),
      ),
    );
  }
}
