import '../domain/ai_backend_config.dart';
import '../domain/chat_message.dart';

abstract class AiRemoteTransport {
  Future<String> send({
    required List<ChatMessage> messages,
    required String userInput,
    required AiBackendConfig config,
  });
}
