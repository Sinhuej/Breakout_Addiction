import '../domain/chat_message.dart';
import '../domain/chat_provider.dart';
import 'ai_backend_config_repository.dart';
import 'ai_remote_transport.dart';

class VertexPrivateReadyProvider implements ChatProvider {
  final AiRemoteTransport transport;
  final AiBackendConfigRepository _configRepository =
      AiBackendConfigRepository();

  VertexPrivateReadyProvider({
    required this.transport,
  });

  @override
  Future<ChatMessage> generateReply({
    required List<ChatMessage> messages,
    required String userInput,
  }) async {
    final config = await _configRepository.getConfig();

    final text = await transport.send(
      messages: messages,
      userInput: userInput,
      config: config,
    );

    return ChatMessage(
      role: ChatRole.assistant,
      text: text,
      timestamp: DateTime.now(),
    );
  }
}
