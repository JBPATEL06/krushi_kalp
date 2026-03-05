import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart'
    show Chat, DefaultChatTheme;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:krushi_kalp_admin/core/theme/app_colors.dart';
import 'package:krushi_kalp_admin/data/services/chat_service.dart';
import 'package:krushi_kalp_admin/data/services/auth_service.dart';
import 'package:krushi_kalp_admin/domain/models/message.dart';
import 'package:krushi_kalp_admin/presentation/widgets/common/network_error_state.dart';
import 'package:krushi_kalp_admin/presentation/widgets/chat/chat_input.dart';
import 'package:krushi_kalp_admin/presentation/utils/chat_mapper.dart';
import 'package:krushi_kalp_admin/presentation/screens/main_screen.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  void _handleMessageTap(BuildContext _, types.Message message) async {
    // Optional: Implement message tap actions (e.g., copy, delete)
  }

  Future<void> _clearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Chat?'),
        content: const Text('This will delete all your sent messages.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Clear', style: TextStyle(color: AppColors.error)),
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
            SnackBar(content: Text('Error clearing chat: $e')),
          );
        }
      }
    }
  }

  void _handleMessageLongPress(
      BuildContext context, types.Message message) async {
    if (message.author.id != _user.id)
      return; // Only allow deleting own messages

    // Check time limit (2 minutes)
    final createdAt = message.createdAt;
    if (createdAt != null) {
      final messageTime = DateTime.fromMillisecondsSinceEpoch(createdAt);
      final difference = DateTime.now().difference(messageTime);
      if (difference.inMinutes >= 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can only unsend messages within 2 minutes.'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsend Message?'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Unsend', style: TextStyle(color: AppColors.error)),
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
    if (AuthService().currentUser == null) {
      return const Scaffold(body: Center(child: Text("Please login to chat.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.neutral100,
              child: Icon(Icons.support_agent, color: AppColors.primary),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Support',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Online',
                    style: TextStyle(fontSize: 12, color: AppColors.success)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: AppColors.primary),
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
        elevation: 1,
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
          // Chat widget expects newest messages at index 0 (if reversed? No, the list order matters)
          // flutter_chat_ui expects the list to be ordered such that index 0 is the newest message.
          // Our fetch retrieves in ascending order (oldest first).
          // So we need to reverse it.
          messages = messages.reversed.toList();

          return Chat(
            messages: messages,
            onSendPressed: _handleSendPressed,
            onMessageLongPress: _handleMessageLongPress,
            onMessageTap: _handleMessageTap,
            user: _user,
            customBottomWidget: ChatInput(
              onSendPressed: (text) =>
                  _handleSendPressed(types.PartialText(text: text)),
            ),
            theme: const DefaultChatTheme(
              primaryColor: AppColors.primary,
              secondaryColor: AppColors.neutral100,
              inputBackgroundColor: AppColors.neutral50,
              backgroundColor: AppColors.background,
            ),
            showUserAvatars: true,
            showUserNames: true,
          );
        },
      ),
    );
  }
}
