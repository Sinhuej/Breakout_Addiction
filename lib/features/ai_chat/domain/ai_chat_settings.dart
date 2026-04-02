import 'chat_provider_mode.dart';

class AiChatSettings {
  final ChatProviderMode providerMode;

  const AiChatSettings({
    required this.providerMode,
  });

  factory AiChatSettings.defaults() {
    return const AiChatSettings(
      providerMode: ChatProviderMode.mock,
    );
  }

  AiChatSettings copyWith({
    ChatProviderMode? providerMode,
  }) {
    return AiChatSettings(
      providerMode: providerMode ?? this.providerMode,
    );
  }
}
