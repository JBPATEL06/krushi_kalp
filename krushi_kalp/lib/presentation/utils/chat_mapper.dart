import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import '../../domain/models/message.dart';

class ChatMapper {
  static List<types.Message> mapToUI(List<Message> messages,
      {String? otherUserName}) {
    return messages.map((msg) {
      final authorId = msg.isFromAdmin ? 'admin' : msg.userId;
      final firstName = msg.isFromAdmin ? 'Support' : (otherUserName ?? 'User');

      return types.TextMessage(
        author: types.User(id: authorId, firstName: firstName),
        createdAt: msg.createdAt.millisecondsSinceEpoch,
        id: msg.id,
        text: msg.message,
      );
    }).toList();
  }
}
