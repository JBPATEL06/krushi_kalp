import 'package:flutter/material.dart';
import '../../../data/services/admin_notification_service.dart';
import '../../../data/services/admin_service.dart';

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
  final _userIdController =
      TextEditingController(); // Simple text input for now

  bool _isBroadcast = true;
  bool _isLoading = false;

  final AdminNotificationService _notificationService =
      AdminNotificationService();

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isBroadcast) {
        await _notificationService.sendBroadcast(
          title: _titleController.text.trim(),
          body: _messageController.text.trim(),
        );
      } else {
        String inputId = _userIdController.text.trim();
        if (inputId.contains('@')) {
          // Resolve Email to UUID
          final resolvedId = await AdminService.getUserIdByEmail(inputId);
          if (resolvedId == null) {
            throw Exception("User with email '$inputId' not found.");
          }
          inputId = resolvedId;
        }

        await _notificationService.sendToUser(
          userId: inputId,
          title: _titleController.text.trim(),
          body: _messageController.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification Sent Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _titleController.clear();
        _messageController.clear();
        // Keep ID maybe? Or clear it too.
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Push Notifications",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),

              // Target Selection
              _buildLabel("Target Audience"),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildRadioTile(
                      title: "All Users (Broadcast)",
                      value: true,
                      icon: Icons.public,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRadioTile(
                      title: "Specific User",
                      value: false,
                      icon: Icons.person,
                    ),
                  ),
                ],
              ),

              if (!_isBroadcast) ...[
                const SizedBox(height: 24),
                _buildLabel("User Email or ID"),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _userIdController,
                  decoration: _inputDecoration(
                    hint: "Enter User Email or UUID...",
                    icon: Icons.person_search,
                  ),
                  validator: (value) {
                    if (!_isBroadcast && (value == null || value.isEmpty)) {
                      return "User ID is required";
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 24),
              _buildLabel("Notification Title"),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration(
                  hint: "e.g. New Mock Test Available!",
                  icon: Icons.title,
                ),
                validator: (v) => v!.isEmpty ? "Title is required" : null,
              ),

              const SizedBox(height: 24),
              _buildLabel("Message Body"),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                decoration: _inputDecoration(
                  hint: "Enter your message here...",
                  icon: Icons.message,
                ),
                validator: (v) => v!.isEmpty ? "Message is required" : null,
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendNotification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, color: Colors.white),
                            SizedBox(width: 12),
                            Text(
                              "Send Notification",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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

  Widget _buildHeader() {
    final primaryColor = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_active_rounded,
                color: primaryColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Send Alerts",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Keep your users engaged with timely updates.",
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFF64748B),
      ),
    );
  }

  Widget _buildRadioTile({
    required String title,
    required bool value,
    required IconData icon,
  }) {
    final primaryColor = Theme.of(context).primaryColor;
    final isSelected = _isBroadcast == value;
    return GestureDetector(
      onTap: () => setState(() => _isBroadcast = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 4,
                  )
                ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
      {required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon:
          Icon(icon, color: Theme.of(context).primaryColor.withOpacity(0.6)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade200),
      ),
    );
  }
}
