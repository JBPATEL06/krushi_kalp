import 'package:flutter/material.dart';
import '../../../../../data/services/app_config_service.dart';

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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader("Feature Flags"),
        SwitchListTile(
          title: const Text("Show Reviews"),
          subtitle: const Text("Show/Hide the entire review section."),
          value: _showReviews,
          onChanged: (val) {
            setState(() => _showReviews = val);
            _updateReviewConfig();
          },
        ),
        SwitchListTile(
          title: const Text("Allow Writing Reviews"),
          subtitle: const Text(
              "Allow users to submit reviews (independent of visibility)."),
          value: _allowWriting,
          onChanged: (val) {
            setState(() => _allowWriting = val);
            _updateReviewConfig();
          },
        ),
        const Divider(height: 32),
        _buildSectionHeader("App Status"),
        SwitchListTile(
          title: const Text("Maintenance Mode"),
          subtitle: const Text("Block user access with a maintenance screen."),
          value: _maintenanceMode,
          onChanged: _toggleMaintenance,
        ),
        if (_maintenanceMode)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _maintenanceMsgController,
              decoration: const InputDecoration(
                labelText: "Maintenance Message",
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _updateMaintenanceConfig(),
            ),
          ),
        if (_maintenanceMode)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: _updateMaintenanceConfig,
              child: const Text("Update Message"),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey)),
    );
  }
}
