import '../domain/chat_message.dart';
import '../domain/chat_provider.dart';

class GeminiPrototypeProvider implements ChatProvider {
  @override
  Future<ChatMessage> generateReply({
    required List<ChatMessage> messages,
    required String userInput,
  }) async {
    return ChatMessage(
      role: ChatRole.assistant,
      text:
          'Gemini prototype mode is not wired to a live API yet. This placeholder exists so the app architecture can switch providers later. For now, keep using sanitized dummy prompts only and do not enter confidential or identifying information.',
      timestamp: DateTime.now(),
    );
  }
}
