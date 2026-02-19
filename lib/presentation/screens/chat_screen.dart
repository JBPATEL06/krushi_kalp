import 'package:flutter/material.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/auth_service.dart';
import '../../domain/models/message.dart';
import '../../data/services/notification_service.dart';
import '../widgets/common/network_error_state.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ChatService _chatService = ChatService();
  final FocusNode _focusNode = FocusNode();

  late Stream<List<Message>> _messagesStream;
  bool _isSelectionMode = false;
  final Set<String> _selectedMessageIds = {};

  @override
  void initState() {
    super.initState();
    NotificationService.currentChatUserId = 'admin_support_chat';
    _messagesStream = _chatService.getMessagesStream();

    // Small delay ensures the route transition is finished before the keyboard pops
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    NotificationService.currentChatUserId = null;
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // --- Logic Methods ---

  void _toggleSelectionMode(String? initialId) {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedMessageIds.clear();
      if (_isSelectionMode && initialId != null) {
        _selectedMessageIds.add(initialId);
      }
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedMessageIds.contains(id)) {
        _selectedMessageIds.remove(id);
        if (_selectedMessageIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedMessageIds.add(id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedMessageIds.isEmpty) return;
    final confirmed = await _showConfirmDialog(
        'Delete ${_selectedMessageIds.length} messages?',
        'This will remove them for everyone.');

    if (confirmed == true) {
      try {
        await _chatService.deleteMessages(_selectedMessageIds.toList());
        if (mounted)
          setState(() {
            _isSelectionMode = false;
            _selectedMessageIds.clear();
          });
      } catch (e) {
        _showError(e.toString());
      }
    }
  }

  Future<void> _clearChat() async {
    final confirmed = await _showConfirmDialog(
        'Clear Chat?', 'This will delete ALL sent messages.');
    if (confirmed == true) {
      try {
        await _chatService.clearChat();
      } catch (e) {
        _showError(e.toString());
      }
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    try {
      await _chatService.sendMessage(text);
    } catch (e) {
      _showError('Error sending: $e');
    }
  }

  // --- Helper UI Methods ---

  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please login to chat.")));
    }

    return PopScope(
      onPopInvoked: (_) => _focusNode.unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        // ⚡ KEY FIX: Set to true and remove manual padding for smooth system animation
        resizeToAvoidBottomInset: true,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(
              child: RepaintBoundary(
                // ⚡ PERFORMANCE: Prevents list repainting during keyboard slide
                child: StreamBuilder<List<Message>>(
                  stream: _messagesStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return NetworkErrorState(
                        message: isNetworkError(snapshot.error)
                            ? 'Unable to load messages.'
                            : 'Error: ${snapshot.error}',
                        onRetry: () => setState(() {
                          _messagesStream = _chatService.getMessagesStream();
                        }),
                      );
                    }
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());

                    final messages = snapshot.data!;
                    if (messages.isEmpty) return _buildEmptyState();

                    final reversedMessages = messages.reversed.toList();
                    return RefreshIndicator(
                      onRefresh: () async {
                        setState(() {
                          _messagesStream = _chatService.getMessagesStream();
                        });
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: ListView.builder(
                        reverse: true,
                        // AlwaysScrollableScrollPhysics needed for refresh when list is small
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 24),
                        itemCount: reversedMessages.length,
                        itemBuilder: (context, index) => _buildMessageItem(
                            reversedMessages[index], index, reversedMessages),
                      ),
                    );
                  },
                ),
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  // --- Sub-Widgets ---

  PreferredSizeWidget _buildAppBar() {
    if (_isSelectionMode) {
      return AppBar(
        backgroundColor: const Color(0xFF6200EA),
        foregroundColor: Colors.white,
        leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() {
                  _isSelectionMode = false;
                  _selectedMessageIds.clear();
                })),
        title: Text('${_selectedMessageIds.length} Selected'),
        actions: [
          IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteSelected)
        ],
      );
    }
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      foregroundColor: Colors.black,
      title: const Row(
        children: [
          CircleAvatar(
              backgroundColor: Color(0xFFE8EAF6),
              child: Icon(Icons.support_agent, color: Color(0xFF6200EA))),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('App Support',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('Typically replies in minutes',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          onSelected: (v) => v == 'clear' ? _clearChat() : null,
          itemBuilder: (ctx) =>
              [const PopupMenuItem(value: 'clear', child: Text('Clear Chat'))],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.message_outlined,
              size: 64, color: Color(0xFF6200EA)),
          const SizedBox(height: 16),
          const Text('How can we help?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Send us a message below.',
              style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Message msg, int index, List<Message> allMessages) {
    final isMe = !msg.isFromAdmin;
    final isSelected = _selectedMessageIds.contains(msg.id);

    return GestureDetector(
      onTap: () => _isSelectionMode && isMe ? _toggleSelection(msg.id) : null,
      onLongPress: () => isMe
          ? (_isSelectionMode
              ? _toggleSelection(msg.id)
              : _toggleSelectionMode(msg.id))
          : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (_isSelectionMode && isMe) _buildSelectionCircle(isSelected),
            if (!isMe) ...[
              const CircleAvatar(
                  radius: 12, child: Icon(Icons.support_agent, size: 14)),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFF6200EA) : Colors.white,
                  borderRadius: BorderRadius.circular(18).copyWith(
                    bottomRight: isMe ? const Radius.circular(2) : null,
                    bottomLeft: !isMe ? const Radius.circular(2) : null,
                  ),
                  border: isSelected
                      ? Border.all(color: Colors.amber, width: 2)
                      : null,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Text(
                  msg.message,
                  style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionCircle(bool selected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? Colors.green : Colors.transparent,
        border: Border.all(color: selected ? Colors.green : Colors.grey),
      ),
      child: selected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE)))),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Message...',
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: Color(0xFF6200EA)),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
