import '../domain/chat_provider.dart';
import '../domain/chat_provider_mode.dart';
import 'gemini_prototype_provider.dart';
import 'mock_recovery_coach_provider.dart';

class ChatProviderFactory {
  static ChatProvider create(ChatProviderMode mode) {
    switch (mode) {
      case ChatProviderMode.mock:
        return MockRecoveryCoachProvider();
      case ChatProviderMode.geminiPrototype:
        return GeminiPrototypeProvider();
    }
  }
}
