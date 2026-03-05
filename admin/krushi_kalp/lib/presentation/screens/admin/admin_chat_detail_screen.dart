import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart'
    show Chat, DefaultChatTheme;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:krushi_kalp_admin/core/theme/app_colors.dart';
import 'package:krushi_kalp_admin/data/services/chat_service.dart';
import 'package:krushi_kalp_admin/domain/models/message.dart';
import 'package:krushi_kalp_admin/data/services/notification_service.dart';
import 'package:krushi_kalp_admin/presentation/widgets/common/network_error_state.dart';
import 'package:krushi_kalp_admin/presentation/utils/chat_mapper.dart';
import 'package:krushi_kalp_admin/presentation/widgets/chat/chat_input.dart';

class AdminChatDetailScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const AdminChatDetailScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AdminChatDetailScreen> createState() => _AdminChatDetailScreenState();
}

class _AdminChatDetailScreenState extends State<AdminChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final types.User _adminUser = const types.User(id: 'admin');

  @override
  void initState() {
    super.initState();
    NotificationService.currentChatUserId = widget.userId;
  }

  @override
  void dispose() {
    NotificationService.currentChatUserId = null;
    super.dispose();
  }

  void _handleSendPressed(types.PartialText message) async {
    try {
      await _chatService.sendMessageAsAdmin(message.text, widget.userId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _clearConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Conversation?'),
        content: const Text(
            'This will delete ALL messages in this chat permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _chatService.deleteConversation(widget.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chat cleared')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  void _handleMessageLongPress(
      BuildContext context, types.Message message) async {
    // Admin can delete ALL messages (their own AND user's)
    // Removed: if (message.author.id != _adminUser.id) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message?'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _chatService.deleteMessage(message.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting message: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: AppColors.error),
            onPressed: _clearConversation,
          ),
        ],
      ),
      body: StreamBuilder<List<Message>>(
        stream: _chatService.getAdminMessagesStream(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return NetworkErrorState(
              message: 'Error loading messages',
              onRetry: () => setState(() {}),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var messages = ChatMapper.mapToUI(snapshot.data!,
              otherUserName: widget.userName);
          messages = messages.reversed.toList();

          return Chat(
            messages: messages,
            onSendPressed: _handleSendPressed,
            onMessageLongPress: _handleMessageLongPress,
            user: _adminUser,
            customBottomWidget: ChatInput(
              onSendPressed: (text) =>
                  _handleSendPressed(types.PartialText(text: text)),
            ),
            theme: const DefaultChatTheme(
              primaryColor: AppColors.primary,
              secondaryColor: AppColors.neutral200, // User messages bubbles
              inputBackgroundColor: AppColors.neutral50,
              backgroundColor: AppColors.background,
            ),
            showUserAvatars: true,
            showUserNames: false, // Name is in AppBar
          );
        },
      ),
    );
  }
}
