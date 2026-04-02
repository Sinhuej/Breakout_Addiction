import 'package:shared_preferences/shared_preferences.dart';

import '../domain/feature_control_settings.dart';

class FeatureControlSettingsRepository {
  static const String _aiChatEnabledKey = 'feature_ai_chat_enabled';
  static const String _aiGuidanceEnabledKey = 'feature_ai_guidance_enabled';
  static const String _faithLayerEnabledKey = 'feature_faith_layer_enabled';
  static const String _showStartupNoticeKey = 'feature_show_startup_notice';
  static const String _remoteAiFeaturesEnabledKey = 'feature_remote_ai_enabled';

  Future<FeatureControlSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return FeatureControlSettings(
      aiChatEnabled: prefs.getBool(_aiChatEnabledKey) ?? true,
      aiGuidanceEnabled: prefs.getBool(_aiGuidanceEnabledKey) ?? true,
      faithLayerEnabled: prefs.getBool(_faithLayerEnabledKey) ?? true,
      showStartupNotice: prefs.getBool(_showStartupNoticeKey) ?? true,
      remoteAiFeaturesEnabled:
          prefs.getBool(_remoteAiFeaturesEnabledKey) ?? false,
    );
  }

  Future<void> saveSettings(FeatureControlSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_aiChatEnabledKey, settings.aiChatEnabled);
    await prefs.setBool(_aiGuidanceEnabledKey, settings.aiGuidanceEnabled);
    await prefs.setBool(_faithLayerEnabledKey, settings.faithLayerEnabled);
    await prefs.setBool(_showStartupNoticeKey, settings.showStartupNotice);
    await prefs.setBool(
      _remoteAiFeaturesEnabledKey,
      settings.remoteAiFeaturesEnabled,
    );
  }
}
