import '../domain/chat_message.dart';
import '../domain/chat_provider.dart';

class VertexPrivateReadyProvider implements ChatProvider {
  @override
  Future<ChatMessage> generateReply({
    required List<ChatMessage> messages,
    required String userInput,
  }) async {
    return ChatMessage(
      role: ChatRole.assistant,
      text:
          'Vertex Private Ready mode is configured as a future paid backend path, but no live request is being made yet. Keep using sanitized dummy prompts until the real cutover is complete.',
      timestamp: DateTime.now(),
    );
  }
}
