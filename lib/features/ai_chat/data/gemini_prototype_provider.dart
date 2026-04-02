import '../domain/chat_message.dart';
import '../domain/chat_provider.dart';
import 'ai_backend_config_repository.dart';
import 'ai_backend_preflight_service.dart';
import 'ai_remote_transport.dart';

class GeminiPrototypeProvider implements ChatProvider {
  final AiRemoteTransport transport;
  final AiBackendPreflightService _preflightService =
      AiBackendPreflightService();
  final AiBackendConfigRepository _configRepository =
      AiBackendConfigRepository();

  GeminiPrototypeProvider({
    required this.transport,
  });

  @override
  Future<ChatMessage> generateReply({
    required List<ChatMessage> messages,
    required String userInput,
  }) async {
    final preflight = await _preflightService.run();

    if (!preflight.readyForRemoteStub) {
      final blockers = preflight.blockerLines.isEmpty
          ? ''
          : ' ${preflight.blockerLines.join(' ')}';

      return ChatMessage(
        role: ChatRole.assistant,
        text:
            'Gemini prototype mode is selected, but the live prototype path is not armed yet. ${preflight.summaryLine}$blockers',
        timestamp: DateTime.now(),
      );
    }

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
