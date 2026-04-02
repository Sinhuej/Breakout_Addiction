import '../../ai_chat/data/ai_chat_settings_repository.dart';
import '../../premium/data/premium_access_repository.dart';
import '../../risk/data/risk_window_repository.dart';
import '../../settings/data/feature_control_settings_repository.dart';
import '../domain/demo_readiness_snapshot.dart';

class DemoReadinessRepository {
  final PremiumAccessRepository _premiumRepository =
      PremiumAccessRepository();
  final RiskWindowRepository _riskRepository = RiskWindowRepository();
  final AiChatSettingsRepository _aiSettingsRepository =
      AiChatSettingsRepository();
  final FeatureControlSettingsRepository _featureRepository =
      FeatureControlSettingsRepository();

  String _premiumPlanLabel(dynamic plan) {
    final name = plan.name as String;
    switch (name) {
      case 'plus':
        return 'Breakout Plus';
      case 'plusAi':
        return 'Breakout Plus AI';
      default:
        return 'Free';
    }
  }

  String _aiModeLabel(dynamic providerMode) {
    final name = providerMode.name as String;
    switch (name) {
      case 'geminiPrototype':
        return 'Gemini Prototype';
      case 'vertexPrivateReady':
        return 'Vertex Private Ready';
      default:
        return 'Mock';
    }
  }

  Future<DemoReadinessSnapshot> build() async {
    final premium = await _premiumRepository.getStatus();
    final riskWindows = await _riskRepository.getRiskWindows();
    final reminderSettings = await _riskRepository.getReminderSettings();
    final aiSettings = await _aiSettingsRepository.getSettings();
    final featureSettings = await _featureRepository.getSettings();

    final premiumPlanLabel = _premiumPlanLabel(premium.plan);
    final aiModeLabel = _aiModeLabel(aiSettings.providerMode);

    final summaryLine = [
      premium.isUnlocked
          ? 'Premium active: $premiumPlanLabel.'
          : 'Free tier active.',
      reminderSettings.remindersEnabled
          ? 'Live reminders enabled.'
          : 'Live reminders disabled.',
      'AI mode: $aiModeLabel.',
    ].join(' ');

    return DemoReadinessSnapshot(
      premiumPlanLabel: premiumPlanLabel,
      remindersEnabled: reminderSettings.remindersEnabled,
      riskWindowCount: riskWindows.length,
      aiModeLabel: aiModeLabel,
      startupNoticeEnabled: featureSettings.showStartupNotice,
      faithLayerEnabled: featureSettings.faithLayerEnabled,
      summaryLine: summaryLine,
    );
  }
}
