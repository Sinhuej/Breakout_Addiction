import '../../premium/data/premium_access_repository.dart';
import '../../settings/data/feature_control_settings_repository.dart';
import '../domain/ai_preflight_status.dart';
import '../domain/chat_provider_mode.dart';
import 'ai_backend_config_repository.dart';
import 'ai_chat_settings_repository.dart';
import 'ai_runtime_gate_repository.dart';

class AiBackendPreflightService {
  final PremiumAccessRepository _premiumRepository =
      PremiumAccessRepository();
  final AiChatSettingsRepository _settingsRepository =
      AiChatSettingsRepository();
  final AiBackendConfigRepository _backendRepository =
      AiBackendConfigRepository();
  final AiRuntimeGateRepository _runtimeGateRepository =
      AiRuntimeGateRepository();
  final FeatureControlSettingsRepository _featureRepository =
      FeatureControlSettingsRepository();

  Future<AiPreflightStatus> run() async {
    final premium = await _premiumRepository.getStatus();
    final settings = await _settingsRepository.getSettings();
    final backend = await _backendRepository.getConfig();
    final remoteEnabled = await _runtimeGateRepository.getRemotePathEnabled();
    final featureSettings = await _featureRepository.getSettings();

    final providerIsVertex =
        settings.providerMode == ChatProviderMode.vertexPrivateReady;

    final riskyFeaturesForcedOff = !backend.allowGrounding &&
        !backend.allowMapsGrounding &&
        !backend.allowSessionMemory &&
        !backend.allowFileUploads;

    final blockers = <String>[];

    if (!premium.hasAiPremium) {
      blockers.add('Breakout Plus AI is not active.');
    }
    if (!featureSettings.aiChatEnabled) {
      blockers.add('AI chat is disabled in Feature Controls.');
    }
    if (!featureSettings.remoteAiFeaturesEnabled) {
      blockers.add('Remote AI features are disabled in Feature Controls.');
    }
    if (!providerIsVertex) {
      blockers.add('Provider mode is not Vertex Private Ready.');
    }
    if (!remoteEnabled) {
      blockers.add('Remote backend path is disabled.');
    }
    if (!backend.hasApiKey) {
      blockers.add('No API key is saved.');
    }
    if (!riskyFeaturesForcedOff) {
      blockers.add('One or more risky features are enabled.');
    }

    final readyForRemoteStub = premium.hasAiPremium &&
        featureSettings.aiChatEnabled &&
        featureSettings.remoteAiFeaturesEnabled &&
        providerIsVertex &&
        remoteEnabled &&
        backend.hasApiKey &&
        riskyFeaturesForcedOff;

    String summaryLine;
    if (readyForRemoteStub) {
      summaryLine =
          'Remote paid path is armed, but it is still routed to a stub transport until the live cutover is built.';
    } else if (settings.providerMode == ChatProviderMode.mock) {
      summaryLine = 'Local mock mode is active. No cloud path is armed.';
    } else if (settings.providerMode == ChatProviderMode.geminiPrototype) {
      summaryLine =
          'Gemini prototype placeholder mode is active. Keep using sanitized dummy prompts only.';
    } else {
      summaryLine =
          'Vertex private-ready mode is selected, but the paid path is still blocked by one or more preflight checks.';
    }

    return AiPreflightStatus(
      premiumUnlocked: premium.hasAiPremium,
      providerModeLabel: settings.providerMode.label,
      providerIsVertexPrivateReady: providerIsVertex,
      remotePathEnabled: remoteEnabled,
      apiKeyPresent: backend.hasApiKey,
      riskyFeaturesForcedOff: riskyFeaturesForcedOff,
      readyForRemoteStub: readyForRemoteStub,
      summaryLine: summaryLine,
      blockerLines: blockers,
    );
  }
}
