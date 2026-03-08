import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:krushi_kalp/presentation/widgets/common/responsive_wrapper.dart'; // FIXED
import '../../data/services/auth_service.dart';
import '../../utils/error_utils.dart';
import '../../core/theme/app_spacing.dart'; // FIXED
import '../../core/theme/app_radius.dart'; // FIXED

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _usernameController;
  late final TextEditingController _phoneController;
  late String _selectedLanguage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
      text: widget.profile['username'] as String? ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.profile['phonenumber'] as String? ?? '',
    );
    _selectedLanguage = widget.profile['language'] as String? ?? 'en';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final theme = Theme.of(context);
    final username = _usernameController.text.trim();
    final phone = _phoneController.text.trim();

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty.')),
      );
      return;
    }

    if (phone.isNotEmpty && phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid 10-digit phone number.')),
      );
      return;
    }

    // Check if phone changed
    final oldPhone = widget.profile['phonenumber'] as String? ?? '';
    if (phone != oldPhone) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Phone Number'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You are changing your phone number to: +91 $phone'),
              const SizedBox(height: AppSpacing.md), // FIXED: AppSpacing.md
              Text(
                'Note: This number will be used for all future payments and pre-filled in Razorpay. Please ensure it is a valid and active number.',
                style: TextStyle(
                    fontSize: context.sp(13),
                    color: theme
                        .colorScheme.onSurfaceVariant), // FIXED: context.sp(13)
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm & Save'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isSaving = true);
    try {
      final userId = AuthService.instance.currentUser?.id;
      if (userId != null) {
        await AuthService.instance.updateProfile(userId, {
          'username': username,
          'phonenumber': phone.isEmpty ? null : phone,
          'language': _selectedLanguage,
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: theme.colorScheme.primary,
          ),
        );
        Navigator.pop(context, true); // Signal profile screen to refresh
      }
    } catch (e) {
      if (mounted) {
        ErrorUtils.showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile',
            style:
                TextStyle(fontSize: context.sp(18))), // FIXED: context.sp(18)
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? SizedBox(
                    width: context.w(20), // FIXED: context.w(20)
                    height: context.h(20), // FIXED: context.h(20)
                    child: const CircularProgressIndicator(strokeWidth: 2))
                : Text('Save',
                    style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                        fontSize: context.sp(16))), // FIXED: context.sp(16)
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.of(context).padding.bottom, // FIXED
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display Name
            Text('Display Name',
                style: TextStyle(
                    fontSize: context.sp(13), // FIXED: context.sp(13)
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.sm), // FIXED: AppSpacing.sm
            TextField(
              controller: _usernameController,
              textCapitalization: TextCapitalization.words,
              style:
                  TextStyle(fontSize: context.sp(16)), // FIXED: context.sp(16)
              decoration: InputDecoration(
                hintText: 'Enter your name',
                prefixIcon: Icon(Icons.person_outline,
                    size: context.sp(22)), // FIXED: context.sp(22)
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        AppRadius.md)), // FIXED: AppRadius.md
              ),
            ),
            const SizedBox(height: AppSpacing.xl), // FIXED: AppSpacing.xl

            // Language Option
            Text('App Language',
                style: TextStyle(
                    fontSize: context.sp(13), // FIXED: context.sp(13)
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.sm), // FIXED: AppSpacing.sm
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md), // FIXED: AppSpacing.md
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline),
                borderRadius:
                    BorderRadius.circular(AppRadius.md), // FIXED: AppRadius.md
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLanguage,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(
                        value: 'en',
                        child: Text('English',
                            style:
                                TextStyle(fontSize: context.sp(16)))), // FIXED
                    DropdownMenuItem(
                        value: 'gu',
                        child: Text('Gujarati',
                            style:
                                TextStyle(fontSize: context.sp(16)))), // FIXED
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedLanguage = val);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl), // FIXED: AppSpacing.xl

            // Phone Number
            Text('Phone Number',
                style: TextStyle(
                    fontSize: context.sp(13), // FIXED: context.sp(13)
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.sm), // FIXED: AppSpacing.sm
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              style:
                  TextStyle(fontSize: context.sp(16)), // FIXED: context.sp(16)
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: '10-digit mobile number',
                prefixIcon: Icon(Icons.phone_outlined,
                    size: context.sp(22)), // FIXED: context.sp(22)
                prefixText: '+91  ',
                counterText: '',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        AppRadius.md)), // FIXED: AppRadius.md
              ),
            ),
            const SizedBox(height: AppSpacing.sm), // FIXED: AppSpacing.sm
            Text(
              'Your number will be used to prefill Razorpay during checkout.',
              style: TextStyle(
                  fontSize: context.sp(12),
                  color: theme
                      .colorScheme.onSurfaceVariant), // FIXED: context.sp(12)
            ),
          ],
        ),
      ),
    );
  }
}
