import 'package:flutter/material.dart';
import 'package:krushi_kalp/data/services/chat_service.dart';
import 'package:krushi_kalp/domain/models/message.dart';
import 'package:krushi_kalp/data/services/notification_service.dart';
import '../../widgets/common/network_error_state.dart';

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
  final TextEditingController _controller = TextEditingController();
  final ChatService _chatService = ChatService();
  double _lastKeyboardHeight = 0;

  @override
  void initState() {
    super.initState();
    // Suppress notifications for this user while chatting
    NotificationService.currentChatUserId = widget.userId;
  }

  @override
  void dispose() {
    NotificationService.currentChatUserId = null;
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    try {
      await _chatService.sendMessageAsAdmin(text, widget.userId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    if (bottomPadding > _lastKeyboardHeight) {
      _lastKeyboardHeight = bottomPadding;
    }
    // Snap to the known max height if keyboard is opening (height > 0)
    final effectivePadding =
        (bottomPadding > 0) ? _lastKeyboardHeight : bottomPadding;

    return Scaffold(
      resizeToAvoidBottomInset: false, // Instant keyboard
      appBar: AppBar(
        title: Text(widget.userName),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear Conversation?'),
                  content: const Text(
                      'This will delete ALL messages in this chat permanently.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (!context.mounted) return;
                        Navigator.pop(ctx);
                        try {
                          await _chatService.deleteConversation(widget.userId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Chat cleared')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      child: const Text('Clear All',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.getAdminMessagesStream(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return NetworkErrorState(
                    message: isNetworkError(snapshot.error)
                        ? 'Unable to load messages.'
                        : 'Error: ${snapshot.error}',
                    onRetry: () => setState(() {}),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;
                // Reverse the list locally so Index 0 is the NEWEST message (Bottom)
                final reversedMessages = messages.reversed.toList();

                return ListView.builder(
                  reverse: true, // Start from bottom
                  padding: const EdgeInsets.all(16),
                  itemCount: reversedMessages.length,
                  itemBuilder: (context, index) {
                    final msg = reversedMessages[index];
                    // IMPORTANT: In Admin View, "Me" is the Admin (isFromAdmin == true)
                    final isMe = msg.isFromAdmin;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: () {
                          // Admin can delete *any* message
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Message?'),
                              content: const Text(
                                  'This will remove the message for everyone.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    if (!context.mounted) return;
                                    Navigator.pop(ctx);

                                    try {
                                      await _chatService.deleteMessage(msg.id);
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            // Admin (Me) = Indigo, User = Grey
                            color: isMe
                                ? Theme.of(context).primaryColor
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(20).copyWith(
                              bottomRight:
                                  isMe ? const Radius.circular(0) : null,
                              bottomLeft:
                                  !isMe ? const Radius.circular(0) : null,
                            ),
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          child: Text(
                            msg.message,
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: effectivePadding),
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autocorrect: true,
                      decoration: const InputDecoration(
                        hintText: 'Reply as Admin...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon:
                        Icon(Icons.send, color: Theme.of(context).primaryColor),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
