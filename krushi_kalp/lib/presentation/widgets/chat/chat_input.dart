import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12), // Outer padding
      color: theme.colorScheme.surface,
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
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 16,
                fontFamily: 'Inter',
              ),
              decoration: InputDecoration(
                hintText: 'Message',
                hintStyle: TextStyle(color: theme.colorScheme.outlineVariant),
                filled: true,
                fillColor:
                    theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16, // Comfort padding inside field
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8), // Square-ish (8px)
                  borderSide:
                      BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.colorScheme.primary),
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
              color: theme.colorScheme.primary,
              iconSize: 28, // Slightly larger icon
              splashRadius: 24,
              tooltip: 'Send',
            ),
          ),
        ],
      ),
    );
  }
}
