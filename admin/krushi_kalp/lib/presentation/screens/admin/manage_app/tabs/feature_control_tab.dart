import 'package:flutter/material.dart';
import '../../../../../data/services/app_config_service.dart';
import 'package:krushi_kalp_admin/core/theme/app_spacing.dart';
import '../../../../utils/ui_helpers.dart';

class FeatureControlTab extends StatefulWidget {
  const FeatureControlTab({super.key});

  @override
  State<FeatureControlTab> createState() => _FeatureControlTabState();
}

class _FeatureControlTabState extends State<FeatureControlTab> {
  bool _isLoading = false;
  bool _showReviews = true;
  bool _allowWriting = true;
  bool _maintenanceMode = false;
  final TextEditingController _maintenanceMsgController =
      TextEditingController();
  final TextEditingController _minVersionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    await AppConfigService.fetchConfigs();
    if (mounted) {
      setState(() {
        _showReviews = AppConfigService.areReviewsVisible;
        _allowWriting = AppConfigService.canWriteReviews;
        _maintenanceMode = AppConfigService.isMaintenanceMode;
        _maintenanceMsgController.text = AppConfigService.maintenanceMessage;
        _minVersionController.text = AppConfigService.minVersion ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateReviewConfig() async {
    try {
      await AppConfigService.updateConfig('feature_reviews', {
        'show_reviews': _showReviews,
        'allow_writing': _allowWriting,
      });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Review settings updated")));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _toggleMaintenance(bool value) async {
    setState(() => _maintenanceMode = value);
    _updateMaintenanceConfig();
  }

  Future<void> _updateMaintenanceConfig() async {
    try {
      await AppConfigService.updateConfig('app_status', {
        'maintenance_mode': _maintenanceMode,
        'message': _maintenanceMsgController.text,
        'min_version': _minVersionController.text.trim().isEmpty
            ? null
            : _minVersionController.text.trim(),
      });
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("App Status updated")));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _buildSectionHeader(context, "FEATURE FLAGS"),
            const SizedBox(height: AppSpacing.md),
            _buildSwitchCard(
              context,
              title: "Show Reviews",
              subtitle: "Show/Hide the entire review section.",
              value: _showReviews,
              icon: Icons.reviews_rounded,
              onChanged: (val) {
                setState(() => _showReviews = val);
                _updateReviewConfig();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _buildSwitchCard(
              context,
              title: "Allow Writing Reviews",
              subtitle:
                  "Allow users to submit reviews (independent of visibility).",
              value: _allowWriting,
              icon: Icons.rate_review_rounded,
              onChanged: (val) {
                setState(() => _allowWriting = val);
                _updateReviewConfig();
              },
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSectionHeader(context, "APP STATUS"),
            const SizedBox(height: AppSpacing.md),
            _buildSwitchCard(
              context,
              title: "Maintenance Mode",
              subtitle: "Block user access with a maintenance screen.",
              value: _maintenanceMode,
              icon: Icons.engineering_rounded,
              onChanged: _toggleMaintenance,
            ),
            if (_maintenanceMode) ...[
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _maintenanceMsgController,
                decoration: getPremiumInputDecoration(
                  context,
                  labelText: "Maintenance Message",
                  prefixIcon: const Icon(Icons.message_rounded),
                  hintText: "Reason for maintenance...",
                ),
                onSubmitted: (_) => _updateMaintenanceConfig(),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            const SizedBox(height: AppSpacing.xxl),
            _buildSectionHeader(context, "FORCE UPDATE"),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _minVersionController,
              decoration: getPremiumInputDecoration(
                context,
                labelText: "Minimum Required Version",
                hintText: "e.g. 1.2.0  (leave empty to disable)",
                prefixIcon: const Icon(Icons.system_update_alt_rounded),
              ),
              keyboardType: TextInputType.text,
              onSubmitted: (_) => _updateMaintenanceConfig(),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Users with an app version below this will be forced to update before they can use the app.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: _updateMaintenanceConfig,
              icon: const Icon(Icons.save_rounded),
              label: const Text("Save Version & Status"),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Text(
      title,
      style: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: colorScheme.onSurfaceVariant,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildSwitchCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 24),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: colorScheme.onSurfaceVariant, fontSize: 13),
        ),
        value: value,
        activeColor: colorScheme.primary,
        onChanged: onChanged,
      ),
    );
  }
}
