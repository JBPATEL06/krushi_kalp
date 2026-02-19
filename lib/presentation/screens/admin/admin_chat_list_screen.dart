import 'package:flutter/material.dart';
import 'package:krushi_kalp/data/services/chat_service.dart';
import '../../widgets/common/network_error_state.dart';
import 'admin_chat_detail_screen.dart';

class AdminChatListScreen extends StatefulWidget {
  const AdminChatListScreen({super.key});

  @override
  State<AdminChatListScreen> createState() => _AdminChatListScreenState();
}

class _AdminChatListScreenState extends State<AdminChatListScreen> {
  final ChatService _chatService = ChatService();
  Stream<List<Map<String, dynamic>>>? _conversationsStream;

  @override
  void initState() {
    super.initState();
    _conversationsStream = _chatService.getConversationsStream();
  }

  void _refresh() {
    setState(() {
      _conversationsStream = _chatService.getConversationsStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Inbox',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _refresh,
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _conversationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return NetworkErrorState(
              message: isNetworkError(snapshot.error)
                  ? 'Unable to load conversations. Check your connection.'
                  : 'Error: ${snapshot.error}',
              onRetry: _refresh,
            );
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No active conversations.',
                      style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 16,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: conversations.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final chat = conversations[index];
              final username = chat['username'] ?? 'User';
              final firstChar = username.isNotEmpty
                  ? (username as String)[0].toUpperCase()
                  : '?';

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.blue.withOpacity(0.4), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Text(
                      firstChar,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  title: Text(
                    username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      chat['email'] ?? 'No Email',
                      style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.grey, size: 14),
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminChatDetailScreen(
                          userId: chat['user_id'],
                          userName: chat['username'],
                        ),
                      ),
                    );
                    _refresh();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
