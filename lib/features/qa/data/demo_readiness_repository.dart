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

  Future<DemoReadinessSnapshot> build() async {
    final premium = await _premiumRepository.getStatus();
    final riskWindows = await _riskRepository.getRiskWindows();
    final reminderSettings = await _riskRepository.getReminderSettings();
    final aiSettings = await _aiSettingsRepository.getSettings();
    final featureSettings = await _featureRepository.getSettings();

    final summaryLine = [
      premium.isUnlocked
          ? 'Premium active: ${premium.plan.label}.'
          : 'Free tier active.',
      reminderSettings.remindersEnabled
          ? 'Live reminders enabled.'
          : 'Live reminders disabled.',
      'AI mode: ${aiSettings.providerMode.label}.',
    ].join(' ');

    return DemoReadinessSnapshot(
      premiumPlanLabel: premium.plan.label,
      remindersEnabled: reminderSettings.remindersEnabled,
      riskWindowCount: riskWindows.length,
      aiModeLabel: aiSettings.providerMode.label,
      startupNoticeEnabled: featureSettings.showStartupNotice,
      faithLayerEnabled: featureSettings.faithLayerEnabled,
      summaryLine: summaryLine,
    );
  }
}
