import 'chat_message.dart';

abstract class ChatProvider {
  Future<ChatMessage> generateReply({
    required List<ChatMessage> messages,
    required String userInput,
  });
}
