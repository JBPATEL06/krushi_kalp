import 'package:flutter/material.dart';
import 'package:krushi_kalp/utils/responsive.dart';
import '../../../data/services/admin_notification_service.dart';
import '../../../utils/error_utils.dart';
import 'package:krushi_kalp/core/theme/app_spacing.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() =>
      _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isLoading = false;

  final AdminNotificationService _notificationService =
      AdminNotificationService();

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _notificationService.sendBroadcast(
        title: _titleController.text.trim(),
        body: _messageController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification Sent Successfully!'),
            backgroundColor: Color(0xFF10B981), // Emerald
          ),
        );
        _titleController.clear();
        _messageController.clear();
      }
    } catch (e) {
      if (mounted) {
        ErrorUtils.showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.of(context).padding.bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(context, "BROADCAST ALERTS"),
              const SizedBox(height: AppSpacing.sm),
              Text(
                "Send push notifications to all registered users simultaneously.",
                style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: context.sp(12)), // FIXED
              ),
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Notification Title",
                  labelStyle: TextStyle(fontSize: context.sp(14)), // FIXED
                  hintText: "e.g. New Mock Test Available!",
                  hintStyle: TextStyle(fontSize: context.sp(14)), // FIXED
                  prefixIcon:
                      Icon(Icons.title_rounded, size: context.sp(20)), // FIXED
                ),
                validator: (v) => v!.isEmpty ? "Title is required" : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "Message Body",
                  labelStyle: TextStyle(fontSize: context.sp(14)), // FIXED
                  hintText: "Enter your message here...",
                  hintStyle: TextStyle(fontSize: context.sp(14)), // FIXED
                  prefixIcon: Icon(Icons.message_rounded,
                      size: context.sp(20)), // FIXED
                ),
                validator: (v) => v!.isEmpty ? "Message is required" : null,
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _sendNotification,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text("SEND BROADCAST",
                      style: TextStyle(fontSize: context.sp(14))), // FIXED
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
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          fontSize: context.sp(10), // FIXED
        ),
      ),
    );
  }
}
