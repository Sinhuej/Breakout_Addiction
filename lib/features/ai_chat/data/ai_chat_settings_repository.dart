import 'package:shared_preferences/shared_preferences.dart';

import '../domain/ai_chat_settings.dart';
import '../domain/chat_provider_mode.dart';

class AiChatSettingsRepository {
  static const String _providerModeKey = 'ai_chat_provider_mode';

  Future<AiChatSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_providerModeKey);

    final mode = raw == null || raw.isEmpty
        ? ChatProviderMode.mock
        : ChatProviderMode.values.byName(raw);

    return AiChatSettings(providerMode: mode);
  }

  Future<void> saveSettings(AiChatSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_providerModeKey, settings.providerMode.name);
  }

  Future<void> setProviderMode(ChatProviderMode mode) async {
    final current = await getSettings();
    await saveSettings(current.copyWith(providerMode: mode));
  }
}
