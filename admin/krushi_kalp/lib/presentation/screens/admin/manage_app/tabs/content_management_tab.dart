import 'package:flutter/material.dart';
import '../../../../../data/services/app_config_service.dart';
import 'package:krushi_kalp_admin/core/theme/app_spacing.dart';
import '../../../../utils/ui_helpers.dart';

class ContentManagementTab extends StatefulWidget {
  const ContentManagementTab({super.key});

  @override
  State<ContentManagementTab> createState() => _ContentManagementTabState();
}

class _ContentManagementTabState extends State<ContentManagementTab> {
  bool _isLoading = false;

  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _telegramController = TextEditingController();
  final _privacyController = TextEditingController();
  final _termsController = TextEditingController();

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
        _whatsappController.text = AppConfigService.getValue(
            'contact_info', 'whatsapp',
            defaultValue: '');
        _emailController.text = AppConfigService.getValue(
            'contact_info', 'email',
            defaultValue: '');
        _telegramController.text = AppConfigService.getValue(
            'contact_info', 'telegram',
            defaultValue: '');

        _privacyController.text = AppConfigService.getValue(
            'legal_urls', 'privacy_policy',
            defaultValue: '');
        _termsController.text =
            AppConfigService.getValue('legal_urls', 'terms', defaultValue: '');
        _isLoading = false;
      });
    }
  }

  Future<void> _saveContactInfo() async {
    try {
      await AppConfigService.updateConfig('contact_info', {
        'whatsapp': _whatsappController.text,
        'email': _emailController.text,
        'telegram': _telegramController.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Contact Info Saved")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Future<void> _saveLegalUrls() async {
    try {
      await AppConfigService.updateConfig('legal_urls', {
        'privacy_policy': _privacyController.text,
        'terms': _termsController.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Legal URLs Saved")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _buildSectionHeader(context, "CONTACT INFORMATION"),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(context, "WhatsApp Number", _whatsappController,
                TextInputType.phone, Icons.phone_android_rounded),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(context, "Support Email", _emailController,
                TextInputType.emailAddress, Icons.alternate_email_rounded),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(context, "Telegram Channel Link",
                _telegramController, TextInputType.url, Icons.send_rounded),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _saveContactInfo,
              icon: const Icon(Icons.save_rounded),
              label: const Text("Save Contact Info"),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSectionHeader(context, "LEGAL DOCUMENTS"),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(context, "Privacy Policy URL", _privacyController,
                TextInputType.url, Icons.privacy_tip_rounded),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(context, "Terms & Conditions URL", _termsController,
                TextInputType.url, Icons.gavel_rounded),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _saveLegalUrls,
              icon: const Icon(Icons.save_rounded),
              label: const Text("Save Legal Config"),
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

  Widget _buildTextField(BuildContext context, String label,
      TextEditingController controller, TextInputType type, IconData icon) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: getPremiumInputDecoration(
        context,
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }
}
