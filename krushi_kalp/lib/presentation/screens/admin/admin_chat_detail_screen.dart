import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart'
    show Chat, DefaultChatTheme;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:krushi_kalp/data/services/chat_service.dart';
import 'package:krushi_kalp/domain/models/message.dart';
import 'package:krushi_kalp/data/services/notification_service.dart';
import 'package:krushi_kalp/presentation/widgets/common/network_error_state.dart';
import 'package:krushi_kalp/presentation/utils/chat_mapper.dart';
import 'package:krushi_kalp/presentation/widgets/chat/chat_input.dart';
import 'package:krushi_kalp/core/theme/app_radius.dart';
import '../../../utils/error_utils.dart';

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
        ErrorUtils.showError(context, e);
      }
    }
  }

  Future<void> _clearConversation() async {
    final theme = Theme.of(context);
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
            child: Text('Clear All',
                style: TextStyle(color: theme.colorScheme.error)),
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
    final theme = Theme.of(context);
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
            child: Text('Delete',
                style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _chatService.deleteMessage(message.id);
      } catch (e) {
        if (mounted) {
          ErrorUtils.showError(context, e);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.userName),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        scrolledUnderElevation: 0,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep_rounded, color: colorScheme.error),
            onPressed: _clearConversation,
          ),
        ],
      ),
      body: StreamBuilder<List<Message>>(
        stream: _chatService.getAdminMessagesStream(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return NetworkErrorState(
              message: 'Something went wrong.',
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
            customBottomWidget: Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom),
              child: ChatInput(
                onSendPressed: (text) =>
                    _handleSendPressed(types.PartialText(text: text)),
              ),
            ),
            theme: DefaultChatTheme(
              primaryColor: colorScheme.primary,
              secondaryColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              inputBackgroundColor: colorScheme.surface,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              receivedMessageBodyTextStyle: theme.textTheme.bodyMedium!,
              sentMessageBodyTextStyle: theme.textTheme.bodyMedium!
                  .copyWith(color: colorScheme.onPrimary),
              messageBorderRadius: AppRadius.md,
              userNameTextStyle: theme.textTheme.labelSmall!,
            ),
            showUserAvatars: true,
            showUserNames: false,
          );
        },
      ),
    );
  }
}
