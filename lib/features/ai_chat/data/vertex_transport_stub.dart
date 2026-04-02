import '../domain/ai_backend_config.dart';
import '../domain/chat_message.dart';
import 'ai_remote_transport.dart';

class VertexTransportStub implements AiRemoteTransport {
  @override
  Future<String> send({
    required List<ChatMessage> messages,
    required String userInput,
    required AiBackendConfig config,
  }) async {
    return 'Vertex transport stub only. The paid path is configured with model ${config.modelName}, but no live remote request is being made yet.';
  }
}
