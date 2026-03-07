import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart'
    show Chat, DefaultChatTheme;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:krushi_kalp_admin/data/services/chat_service.dart';
import 'package:krushi_kalp_admin/data/services/auth_service.dart';
import 'package:krushi_kalp_admin/domain/models/message.dart';
import 'package:krushi_kalp_admin/presentation/widgets/common/network_error_state.dart';
import 'package:krushi_kalp_admin/presentation/widgets/chat/chat_input.dart';
import 'package:krushi_kalp_admin/presentation/utils/chat_mapper.dart';
import 'package:krushi_kalp_admin/presentation/screens/main_screen.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  late Stream<List<Message>> _messagesStream;
  final types.User _user = types.User(id: AuthService().currentUser?.id ?? '');

  @override
  void initState() {
    super.initState();
    _messagesStream = _chatService.getMessagesStream();
  }

  void _handleSendPressed(types.PartialText message) async {
    try {
      await _chatService.sendMessage(message.text);
    } catch (e) {
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _clearChat() async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('Clear Chat?'),
        content: const Text('This will delete all your sent messages.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _chatService.clearChat();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing chat: $e'),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _handleMessageLongPress(
      BuildContext context, types.Message message) async {
    if (message.author.id != _user.id) return;

    final colorScheme = Theme.of(context).colorScheme;
    final createdAt = message.createdAt;
    if (createdAt != null) {
      final messageTime = DateTime.fromMillisecondsSinceEpoch(createdAt);
      final difference = DateTime.now().difference(messageTime);
      if (difference.inMinutes >= 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can only unsend messages within 2 minutes.'),
            ),
          );
        }
        return;
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('Unsend Message?'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: const Text('Unsend'),
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
            SnackBar(
              content: Text('Error deleting message: $e'),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (AuthService().currentUser == null) {
      return const Scaffold(body: Center(child: Text("Please login to chat.")));
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              child:
                  Icon(Icons.support_agent_rounded, color: colorScheme.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Support',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Online',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.tertiary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        shape: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.home_rounded, color: colorScheme.primary),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MainScreen()),
                (route) => false,
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'clear') _clearChat();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear Chat'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Message>>(
        stream: _messagesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return NetworkErrorState(
              message: 'Error loading messages',
              onRetry: () => setState(() {
                _messagesStream = _chatService.getMessagesStream();
              }),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var messages =
              ChatMapper.mapToUI(snapshot.data!, otherUserName: 'Support');
          messages = messages.reversed.toList();

          return Chat(
            messages: messages,
            onSendPressed: _handleSendPressed,
            onMessageLongPress: _handleMessageLongPress,
            user: _user,
            customBottomWidget: ChatInput(
              onSendPressed: (text) =>
                  _handleSendPressed(types.PartialText(text: text)),
            ),
            theme: DefaultChatTheme(
              primaryColor: colorScheme.primary,
              secondaryColor: colorScheme.surfaceVariant.withOpacity(0.5),
              userNameTextStyle: theme.textTheme.labelSmall!
                  .copyWith(color: colorScheme.onSurfaceVariant),
              userAvatarTextStyle: theme.textTheme.labelSmall!
                  .copyWith(color: colorScheme.onPrimary),
              receivedMessageBodyTextStyle: theme.textTheme.bodyMedium!
                  .copyWith(color: colorScheme.onSurfaceVariant),
              sentMessageBodyTextStyle: theme.textTheme.bodyMedium!
                  .copyWith(color: colorScheme.onPrimary),
              inputBackgroundColor: colorScheme.surface,
              backgroundColor: colorScheme.background,
              inputTextColor: colorScheme.onSurface,
            ),
            showUserAvatars: true,
            showUserNames: true,
          );
        },
      ),
    );
  }
}
