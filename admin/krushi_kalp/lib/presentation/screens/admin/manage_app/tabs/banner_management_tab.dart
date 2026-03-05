import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../data/services/banner_service.dart';
import '../../../../../domain/models/home_banner.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../data/services/app_config_service.dart';

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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving settings: $e")),
        );
      }
    }
  }

  // ─── Show Settings Dialog ──────────────────────────
  void _showSettingsDialog() {
    bool tempAutoScroll = _autoScroll;
    int tempInterval = _interval;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              title: const Text(
                "Banner Carousel Settings",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: const Text("Auto Scroll Banners"),
                    subtitle: const Text("Automatically slide through banners"),
                    value: tempAutoScroll,
                    activeTrackColor:
                        Colors.black, // Dark switch color like image
                    onChanged: (val) {
                      setDialogState(() => tempAutoScroll = val);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text("Scroll Interval:"),
                      Expanded(
                        child: Slider(
                          value: tempInterval.toDouble(),
                          min: 3,
                          max: 60,
                          divisions: 57,
                          activeColor: AppColors.neutral400, // Gray slider
                          inactiveColor: AppColors.neutral200,
                          label: "$tempInterval s",
                          onChanged: tempAutoScroll
                              ? (val) {
                                  setDialogState(
                                      () => tempInterval = val.toInt());
                                }
                              : null,
                        ),
                      ),
                      Text("$tempInterval s"),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        _saveSettings(tempAutoScroll, tempInterval);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Save Settings"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Upload Multiple New Banners ───────────────────
  Future<void> _uploadBanners() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true, // ← Multiple files
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _isUploading = true);

      for (final file in result.files) {
        if (file.bytes == null) continue;
        await BannerService.uploadBanner(
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Upload Error: $e")));
      }
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

      await BannerService.replaceBannerImage(
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Replace Error: $e")));
      }
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text("Edit Banner"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priorityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Priority (higher = shown first)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text("Active"),
                value: isActive,
                onChanged: (val) => setDialogState(() => isActive = val),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel")),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Save")),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await BannerService.updateBannerMeta(
          banner.id,
          title: titleController.text.trim(),
          priority: int.tryParse(priorityController.text) ?? 0,
          isActive: isActive,
        );
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Banner updated")));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }
  }

  // ─── Delete Banner ───────────────────
  Future<void> _deleteBanner(HomeBanner banner) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Banner"),
        content: const Text("Are you sure? This cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await BannerService.deleteBanner(banner.id, banner.imageUrl);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Banner deleted")));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Upload Bar and Settings Icon ──
        if (_isUploading) const LinearProgressIndicator(),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadBanners,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text("Upload Banners"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _showSettingsDialog,
                icon: const Icon(Icons.settings_outlined,
                    color: AppColors.primary),
                tooltip: 'Banner Settings',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                  minimumSize: const Size(50, 50),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Tap a banner to edit details. Use icons to replace image or delete.",
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 8),

        // ── Banner List (real-time stream) ──
        Expanded(
          child: StreamBuilder<List<HomeBanner>>(
            stream: BannerService.streamAllBanners(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 8),
                      Text("Error: ${snapshot.error}"),
                      const SizedBox(height: 4),
                      const Text(
                        "Make sure you ran the SQL script to create the banner table.",
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final banners = snapshot.data!;

              if (banners.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.image_not_supported_outlined,
                          size: 64, color: AppColors.neutral400),
                      const SizedBox(height: 12),
                      const Text("No banners yet.",
                          style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 4),
                      Text("Upload banners using the button above.",
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      child: InkWell(
        onTap: onEdit,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner Image ──
            Stack(
              children: [
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: banner.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppColors.neutral100,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.neutral200,
                      child: const Center(
                        child: Icon(Icons.broken_image,
                            size: 40, color: AppColors.neutral400),
                      ),
                    ),
                  ),
                ),
                // Index badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "#$index of $total",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                ),
                // Active/Inactive badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: banner.isActive ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      banner.isActive ? "Active" : "Inactive",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),

            // ── Banner Actions ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          banner.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Priority: ${banner.priority}",
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  // Replace image button
                  IconButton(
                    icon: const Icon(Icons.swap_horiz_rounded,
                        color: AppColors.primary),
                    tooltip: "Replace Image",
                    onPressed: onReplace,
                  ),
                  // Edit meta button
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: AppColors.neutral600),
                    tooltip: "Edit Details",
                    onPressed: onEdit,
                  ),
                  // Delete button
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: "Delete",
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
