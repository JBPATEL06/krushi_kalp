import 'package:flutter/material.dart';
import 'package:krushi_kalp/core/theme/app_colors.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendPressed;

  const ChatInput({
    super.key,
    required this.onSendPressed,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.onSendPressed(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12), // Outer padding
      color: Colors.white,
      child: SafeArea(
        // Handle bottom notch
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.end, // Align to bottom if multiline
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.multiline,
                maxLines: 5,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontFamily: 'Inter',
                ),
                decoration: InputDecoration(
                  hintText: 'Message',
                  hintStyle: const TextStyle(color: AppColors.neutral400),
                  filled: true,
                  fillColor: AppColors.neutral50,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16, // Comfort padding inside field
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8), // Square-ish (8px)
                    borderSide: const BorderSide(color: AppColors.neutral200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.neutral200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 54, // Match approx height of single line input
              width: 54,
              alignment: Alignment.center,
              child: IconButton(
                onPressed: _handleSend,
                icon: const Icon(Icons.send),
                color: AppColors.primary,
                iconSize: 28, // Slightly larger icon
                splashRadius: 24,
                tooltip: 'Send',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
