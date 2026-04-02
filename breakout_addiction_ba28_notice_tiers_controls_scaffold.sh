#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

echo "==> Applying Breakout Addiction BA-28 notice, tiers, and feature controls scaffold in: $ROOT_DIR"

mkdir -p \
  lib/features/premium/domain \
  lib/features/settings/domain \
  lib/features/settings/data \
  lib/features/settings/presentation \
  lib/features/home/presentation/widgets \
  tools

cat > lib/core/constants/route_names.dart <<'EOD'
class RouteNames {
  static const home = '/';
  static const onboarding = '/onboarding';
  static const rescue = '/rescue';
  static const logHub = '/log';
  static const moodLog = '/log/mood';
  static const cycleStageLog = '/log/cycle-stage';
  static const recoveryEventLog = '/log/recovery-event';
  static const insights = '/insights';
  static const educate = '/educate';
  static const educateLesson = '/educate/lesson';
  static const premium = '/premium';
  static const aiChat = '/ai-chat';
  static const support = '/support';
  static const riskWindows = '/risk-windows';
  static const recoveryPlan = '/recovery-plan';
  static const widgetPreview = '/widget-preview';
  static const cycle = '/cycle';
  static const privacySettings = '/privacy';
  static const featureControls = '/feature-controls';
}
EOD

cat > lib/features/premium/domain/premium_plan.dart <<'EOD'
enum PremiumPlan {
  none,
  plus,
  plusAi,
}

extension PremiumPlanX on PremiumPlan {
  String get label {
    switch (this) {
      case PremiumPlan.none:
        return 'Free';
      case PremiumPlan.plus:
        return 'Breakout Plus';
      case PremiumPlan.plusAi:
        return 'Breakout Plus AI';
    }
  }

  String get subtitle {
    switch (this) {
      case PremiumPlan.none:
        return 'Core recovery tools only.';
      case PremiumPlan.plus:
        return 'Private, powerful, no AI required.';
      case PremiumPlan.plusAi:
        return 'Everything in Plus, with optional AI guidance and chat.';
    }
  }
}
EOD

cat > lib/features/premium/domain/premium_status.dart <<'EOD'
import 'premium_plan.dart';

class PremiumStatus {
  final PremiumPlan plan;
  final bool showUpgradePrompts;

  const PremiumStatus({
    required this.plan,
    required this.showUpgradePrompts,
  });

  factory PremiumStatus.defaults() {
    return const PremiumStatus(
      plan: PremiumPlan.none,
      showUpgradePrompts: true,
    );
  }

  PremiumStatus copyWith({
    PremiumPlan? plan,
    bool? showUpgradePrompts,
  }) {
    return PremiumStatus(
      plan: plan ?? this.plan,
      showUpgradePrompts: showUpgradePrompts ?? this.showUpgradePrompts,
    );
  }

  bool get isUnlocked => plan != PremiumPlan.none;
  bool get hasPremium => plan == PremiumPlan.plus || plan == PremiumPlan.plusAi;
  bool get hasAiPremium => plan == PremiumPlan.plusAi;
}
EOD

cat > lib/features/premium/data/premium_access_repository.dart <<'EOD'
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/premium_plan.dart';
import '../domain/premium_status.dart';

class PremiumAccessRepository {
  static const String _premiumPlanKey = 'premium_plan';
  static const String _legacyPremiumUnlockedKey = 'premium_unlocked';
  static const String _upgradePromptsKey = 'premium_upgrade_prompts';

  Future<PremiumStatus> getStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final rawPlan = prefs.getString(_premiumPlanKey);
    final legacyUnlocked = prefs.getBool(_legacyPremiumUnlockedKey) ?? false;

    final PremiumPlan plan;
    if (rawPlan == null || rawPlan.isEmpty) {
      plan = legacyUnlocked ? PremiumPlan.plus : PremiumPlan.none;
    } else {
      plan = PremiumPlan.values.byName(rawPlan);
    }

    return PremiumStatus(
      plan: plan,
      showUpgradePrompts: prefs.getBool(_upgradePromptsKey) ?? true,
    );
  }

  Future<void> saveStatus(PremiumStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_premiumPlanKey, status.plan.name);
    await prefs.setBool(_legacyPremiumUnlockedKey, status.isUnlocked);
    await prefs.setBool(_upgradePromptsKey, status.showUpgradePrompts);
  }

  Future<void> setPlan(PremiumPlan plan) async {
    final current = await getStatus();
    await saveStatus(current.copyWith(plan: plan));
  }

  Future<void> setUnlocked(bool value) async {
    await setPlan(value ? PremiumPlan.plus : PremiumPlan.none);
  }

  Future<void> setUpgradePrompts(bool value) async {
    final current = await getStatus();
    await saveStatus(current.copyWith(showUpgradePrompts: value));
  }
}
EOD

cat > lib/features/settings/domain/feature_control_settings.dart <<'EOD'
class FeatureControlSettings {
  final bool aiChatEnabled;
  final bool aiGuidanceEnabled;
  final bool faithLayerEnabled;
  final bool showStartupNotice;
  final bool remoteAiFeaturesEnabled;

  const FeatureControlSettings({
    required this.aiChatEnabled,
    required this.aiGuidanceEnabled,
    required this.faithLayerEnabled,
    required this.showStartupNotice,
    required this.remoteAiFeaturesEnabled,
  });

  factory FeatureControlSettings.defaults() {
    return const FeatureControlSettings(
      aiChatEnabled: true,
      aiGuidanceEnabled: true,
      faithLayerEnabled: true,
      showStartupNotice: true,
      remoteAiFeaturesEnabled: false,
    );
  }

  FeatureControlSettings copyWith({
    bool? aiChatEnabled,
    bool? aiGuidanceEnabled,
    bool? faithLayerEnabled,
    bool? showStartupNotice,
    bool? remoteAiFeaturesEnabled,
  }) {
    return FeatureControlSettings(
      aiChatEnabled: aiChatEnabled ?? this.aiChatEnabled,
      aiGuidanceEnabled: aiGuidanceEnabled ?? this.aiGuidanceEnabled,
      faithLayerEnabled: faithLayerEnabled ?? this.faithLayerEnabled,
      showStartupNotice: showStartupNotice ?? this.showStartupNotice,
      remoteAiFeaturesEnabled:
          remoteAiFeaturesEnabled ?? this.remoteAiFeaturesEnabled,
    );
  }
}
EOD

cat > lib/features/settings/data/feature_control_settings_repository.dart <<'EOD'
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
EOD
cat > lib/features/settings/presentation/feature_controls_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/info_card.dart';
import '../data/feature_control_settings_repository.dart';
import '../domain/feature_control_settings.dart';

class FeatureControlsScreen extends StatefulWidget {
  const FeatureControlsScreen({super.key});

  @override
  State<FeatureControlsScreen> createState() => _FeatureControlsScreenState();
}

class _FeatureControlsScreenState extends State<FeatureControlsScreen> {
  final FeatureControlSettingsRepository _repository =
      FeatureControlSettingsRepository();

  FeatureControlSettings _settings = FeatureControlSettings.defaults();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _repository.getSettings();
    if (!mounted) {
      return;
    }
    setState(() {
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _save(FeatureControlSettings updated) async {
    await _repository.saveSettings(updated);
    if (!mounted) {
      return;
    }
    setState(() => _settings = updated);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Feature Controls')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Feature Controls')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Choose your comfort level.', style: AppTypography.title),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'You do not need to use every feature. Keep the app as simple, private, and low-pressure as you want.',
            style: AppTypography.muted,
          ),
          const SizedBox(height: AppSpacing.lg),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Core Controls', style: AppTypography.section),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _settings.showStartupNotice,
                  onChanged: (value) => _save(
                    _settings.copyWith(showStartupNotice: value),
                  ),
                  title: const Text('Show startup notice'),
                  subtitle: const Text(
                    'Show the calm welcome and privacy reminder when the app opens.',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _settings.faithLayerEnabled,
                  onChanged: (value) => _save(
                    _settings.copyWith(faithLayerEnabled: value),
                  ),
                  title: const Text('Faith layer'),
                  subtitle: const Text(
                    'Enable or hide faith-sensitive guidance and preferences.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Controls', style: AppTypography.section),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _settings.aiGuidanceEnabled,
                  onChanged: (value) => _save(
                    _settings.copyWith(aiGuidanceEnabled: value),
                  ),
                  title: const Text('AI quotes / guidance'),
                  subtitle: const Text(
                    'Reserved for optional AI-generated guidance later.',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _settings.aiChatEnabled,
                  onChanged: (value) => _save(
                    _settings.copyWith(aiChatEnabled: value),
                  ),
                  title: const Text('AI chat'),
                  subtitle: const Text(
                    'Turn AI conversation features on or off.',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _settings.remoteAiFeaturesEnabled,
                  onChanged: (value) => _save(
                    _settings.copyWith(remoteAiFeaturesEnabled: value),
                  ),
                  title: const Text('Remote AI features'),
                  subtitle: const Text(
                    'Arms remote AI paths only when premium and preflight allow it.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
EOD

cat > lib/features/home/presentation/widgets/startup_notice_sheet.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../../core/widgets/primary_button.dart';

class StartupNoticeSheet extends StatelessWidget {
  final bool showOnStartup;
  final ValueChanged<bool> onShowOnStartupChanged;
  final VoidCallback onContinue;
  final VoidCallback onOpenFeatureChoices;
  final VoidCallback onOpenSupport;

  const StartupNoticeSheet({
    super.key,
    required this.showOnStartup,
    required this.onShowOnStartupChanged,
    required this.onContinue,
    required this.onOpenFeatureChoices,
    required this.onOpenSupport,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome to Breakout', style: AppTypography.title),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'This app is designed to help you interrupt patterns earlier, not make you feel worse.',
                    style: AppTypography.body,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You are not expected to use every feature. You can keep things simple, private, and low-pressure.',
                    style: AppTypography.muted,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'AI features are optional and can be turned off or avoided entirely.',
                    style: AppTypography.muted,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'If you feel discouraged, come back to the smallest next step — not the perfect one.',
                    style: AppTypography.muted,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: showOnStartup,
                    onChanged: onShowOnStartupChanged,
                    title: const Text('Show this on startup'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Continue',
              icon: Icons.arrow_forward_outlined,
              onPressed: onContinue,
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenFeatureChoices,
                icon: const Icon(Icons.tune_outlined),
                label: const Text('Privacy & Feature Choices'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenSupport,
                icon: const Icon(Icons.support_agent_outlined),
                label: const Text('Support'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
EOD

cat > lib/features/home/presentation/home_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../settings/data/feature_control_settings_repository.dart';
import '../../settings/domain/feature_control_settings.dart';
import 'widgets/daily_quote_card.dart';
import 'widgets/home_hero_card.dart';
import 'widgets/progress_snapshot_card.dart';
import 'widgets/quick_actions_row.dart';
import 'widgets/risk_status_card.dart';
import 'widgets/startup_notice_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static bool _startupNoticeHandledThisSession = false;
  final FeatureControlSettingsRepository _settingsRepository =
      FeatureControlSettingsRepository();

  @override
  void initState() {
    super.initState();
    _maybeShowStartupNotice();
  }

  Future<void> _maybeShowStartupNotice() async {
    final settings = await _settingsRepository.getSettings();
    if (!mounted) {
      return;
    }

    if (!settings.showStartupNotice || _startupNoticeHandledThisSession) {
      return;
    }

    _startupNoticeHandledThisSession = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      var currentSettings = settings;

      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              return StartupNoticeSheet(
                showOnStartup: currentSettings.showStartupNotice,
                onShowOnStartupChanged: (value) async {
                  currentSettings =
                      currentSettings.copyWith(showStartupNotice: value);
                  await _settingsRepository.saveSettings(currentSettings);
                  setSheetState(() {});
                },
                onContinue: () {
                  Navigator.pop(sheetContext);
                },
                onOpenFeatureChoices: () {
                  Navigator.pop(sheetContext);
                  Navigator.pushNamed(context, RouteNames.featureControls);
                },
                onOpenSupport: () {
                  Navigator.pop(sheetContext);
                  Navigator.pushNamed(context, RouteNames.support);
                },
              );
            },
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Breakout Addiction'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, RouteNames.support),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const HomeHeroCard(),
            const SizedBox(height: AppSpacing.md),
            const DailyQuoteCard(),
            const SizedBox(height: AppSpacing.md),
            const RiskStatusCard(),
            const SizedBox(height: AppSpacing.md),
            const QuickActionsRow(),
            const SizedBox(height: AppSpacing.md),
            const ProgressSnapshotCard(),
            const SizedBox(height: AppSpacing.md),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Keep Building'),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Use Learn for deeper understanding and Support for your personal plan, privacy settings, premium choices, and feature controls.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    label: 'Open Learn',
                    icon: Icons.menu_book_outlined,
                    onPressed: () => Navigator.pushNamed(
                      context,
                      RouteNames.educate,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.pushReplacementNamed(context, RouteNames.rescue);
              break;
            case 2:
              Navigator.pushReplacementNamed(context, RouteNames.logHub);
              break;
            case 3:
              Navigator.pushReplacementNamed(context, RouteNames.insights);
              break;
            case 4:
              Navigator.pushReplacementNamed(context, RouteNames.support);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.flash_on_outlined), label: 'Rescue'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_note_outlined), label: 'Log'),
          BottomNavigationBarItem(icon: Icon(Icons.insights_outlined), label: 'Insights'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent_outlined), label: 'Support'),
        ],
      ),
    );
  }
}
EOD
cat > lib/features/ai_chat/data/ai_backend_preflight_service.dart <<'EOD'
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
EOD

cat > lib/features/ai_chat/presentation/ai_chat_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../premium/data/premium_access_repository.dart';
import '../../premium/domain/premium_status.dart';
import '../../settings/data/feature_control_settings_repository.dart';
import '../../settings/domain/feature_control_settings.dart';
import '../data/ai_backend_preflight_service.dart';
import '../data/ai_chat_repository.dart';
import '../data/ai_chat_settings_repository.dart';
import '../data/ai_input_guardrail_service.dart';
import '../data/chat_provider_factory.dart';
import '../domain/ai_chat_settings.dart';
import '../domain/ai_preflight_status.dart';
import '../domain/chat_message.dart';
import '../domain/chat_provider_mode.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final PremiumAccessRepository _premiumRepository = PremiumAccessRepository();
  final AiChatRepository _chatRepository = AiChatRepository();
  final AiChatSettingsRepository _settingsRepository =
      AiChatSettingsRepository();
  final FeatureControlSettingsRepository _featureRepository =
      FeatureControlSettingsRepository();
  final AiInputGuardrailService _guardrailService = AiInputGuardrailService();
  final AiBackendPreflightService _preflightService =
      AiBackendPreflightService();
  final TextEditingController _controller = TextEditingController();

  PremiumStatus _premiumStatus = PremiumStatus.defaults();
  FeatureControlSettings _featureSettings =
      FeatureControlSettings.defaults();
  AiChatSettings _settings = AiChatSettings.defaults();
  AiPreflightStatus _preflightStatus = AiPreflightStatus.initial();
  List<ChatMessage> _messages = <ChatMessage>[];
  bool _loading = true;
  bool _sending = false;

  static const List<String> _starterPrompts = <String>[
    'I feel pulled toward a risky ritual tonight.',
    'I am stressed and want a quick escape.',
    'I feel lonely and I am drifting.',
    'Help me interrupt the pattern earlier.',
  ];

  ChatMessage _welcomeMessage() {
    return ChatMessage(
      role: ChatRole.assistant,
      text:
          'Prototype AI coach ready. This version is still prototype-only. Do not enter highly sensitive, identifying, or emergency information here yet.',
      timestamp: DateTime.now(),
    );
  }

  ChatMessage _systemStyleMessage(String text) {
    return ChatMessage(
      role: ChatRole.assistant,
      text: text,
      timestamp: DateTime.now(),
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final premium = await _premiumRepository.getStatus();
    final featureSettings = await _featureRepository.getSettings();
    final messages = await _chatRepository.getMessages();
    final settings = await _settingsRepository.getSettings();
    final preflight = await _preflightService.run();

    if (!mounted) {
      return;
    }

    final loadedMessages = <ChatMessage>[...messages];
    if (premium.hasAiPremium && loadedMessages.isEmpty) {
      loadedMessages.add(_welcomeMessage());
      await _chatRepository.saveMessages(loadedMessages);
    }

    setState(() {
      _premiumStatus = premium;
      _featureSettings = featureSettings;
      _settings = settings;
      _preflightStatus = preflight;
      _messages = loadedMessages;
      _loading = false;
    });
  }

  Future<void> _clearLocalChat() async {
    await _chatRepository.clearMessages();
    final reset = <ChatMessage>[_welcomeMessage()];
    await _chatRepository.saveMessages(reset);

    if (!mounted) {
      return;
    }

    setState(() => _messages = reset);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Local AI chat cleared.')),
    );
  }

  Future<void> _send([String? starterText]) async {
    final raw = starterText ?? _controller.text;
    final input = raw.trim();
    if (input.isEmpty || _sending) {
      return;
    }

    final review = _guardrailService.review(input);

    if (review.blocked) {
      final blockedMessage = _systemStyleMessage(review.reason.userMessage);
      final nextMessages = <ChatMessage>[..._messages, blockedMessage];
      await _chatRepository.saveMessages(nextMessages);

      if (!mounted) {
        return;
      }

      setState(() {
        _messages = nextMessages;
        _controller.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message blocked: ${review.reason.label}.')),
      );
      return;
    }

    final freshPreflight = await _preflightService.run();
    if (!mounted) {
      return;
    }
    setState(() => _preflightStatus = freshPreflight);

    if (_settings.providerMode == ChatProviderMode.vertexPrivateReady &&
        !freshPreflight.readyForRemoteStub) {
      final blockedRemoteMessage = _systemStyleMessage(
        'Remote paid path is not ready yet. ${freshPreflight.summaryLine} ${freshPreflight.blockerLines.join(' ')}',
      );
      final nextMessages = <ChatMessage>[..._messages, blockedRemoteMessage];
      await _chatRepository.saveMessages(nextMessages);

      if (!mounted) {
        return;
      }

      setState(() {
        _messages = nextMessages;
        _controller.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paid backend path blocked by preflight checks.')),
      );
      return;
    }

    final userMessage = ChatMessage(
      role: ChatRole.user,
      text: review.sanitizedText,
      timestamp: DateTime.now(),
    );

    final updated = <ChatMessage>[..._messages];

    if (review.wasSanitized) {
      updated.add(
        _systemStyleMessage(
          'Prototype guardrail: identifying details were scrubbed before processing (${review.scrubbedFlags.join(', ')}).',
        ),
      );
    }

    updated.add(userMessage);

    setState(() {
      _sending = true;
      _messages = updated;
      _controller.clear();
    });

    await _chatRepository.saveMessages(updated);

    final provider = ChatProviderFactory.create(_settings.providerMode);
    final reply = await provider.generateReply(
      messages: updated,
      userInput: review.sanitizedText,
    );

    final finalMessages = <ChatMessage>[...updated, reply];
    await _chatRepository.saveMessages(finalMessages);

    if (!mounted) {
      return;
    }

    setState(() {
      _messages = finalMessages;
      _sending = false;
    });
  }

  Widget _bubble(ChatMessage message) {
    final isUser = message.role == ChatRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF3DD9C5) : const Color(0xFF151B23),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF263041)),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.black : const Color(0xFFF5F7FA),
            height: 1.35,
          ),
        ),
      ),
    );
  }

  Widget _starterChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () => _send(text),
    );
  }

  Widget _providerStatusCard() {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current Provider', style: AppTypography.section),
          const SizedBox(height: AppSpacing.sm),
          Chip(label: Text(_settings.providerMode.label)),
          const SizedBox(height: 8),
          Text(
            _settings.providerMode.description,
            style: AppTypography.muted,
          ),
        ],
      ),
    );
  }

  Widget _modeBannerCard() {
    if (_settings.providerMode == ChatProviderMode.mock) {
      return const InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mode Banner', style: AppTypography.section),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Local mock mode is active. No cloud path is armed.',
              style: AppTypography.muted,
            ),
          ],
        ),
      );
    }

    if (_settings.providerMode == ChatProviderMode.geminiPrototype) {
      return const InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mode Banner', style: AppTypography.section),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Gemini prototype placeholder mode is active. Not confidential. Use sanitized dummy prompts only.',
              style: AppTypography.muted,
            ),
          ],
        ),
      );
    }

    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mode Banner', style: AppTypography.section),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _preflightStatus.summaryLine,
            style: AppTypography.muted,
          ),
          if (_preflightStatus.blockerLines.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            for (final line in _preflightStatus.blockerLines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $line', style: AppTypography.body),
              ),
          ],
        ],
      ),
    );
  }

  Widget _guardrailCard() {
    return const InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Prototype guardrails', style: AppTypography.section),
          SizedBox(height: AppSpacing.sm),
          Text(
            'This screen blocks minor sexual content and imminent self-harm or violence language. It also scrubs obvious identifying details like phone numbers, emails, addresses, names, and exact locations before prototype processing.',
            style: AppTypography.muted,
          ),
        ],
      ),
    );
  }

  Widget _lockedView(BuildContext context) {
    final whyLocked = !_premiumStatus.hasAiPremium
        ? 'AI chat is part of Breakout Plus AI, not Breakout Plus.'
        : !_featureSettings.aiChatEnabled
            ? 'AI chat is currently turned off in Feature Controls.'
            : 'This feature is not available yet.';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('AI Recovery Coach', style: AppTypography.title),
        const SizedBox(height: AppSpacing.xs),
        Text(
          whyLocked,
          style: AppTypography.muted,
        ),
        const SizedBox(height: AppSpacing.lg),
        _providerStatusCard(),
        const SizedBox(height: AppSpacing.md),
        _modeBannerCard(),
        const SizedBox(height: AppSpacing.md),
        _guardrailCard(),
        const SizedBox(height: AppSpacing.md),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What it will do', style: AppTypography.section),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Plus AI adds optional AI chat. Breakout Plus still gives a strong premium experience without AI.',
                style: AppTypography.muted,
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Open Premium',
                icon: Icons.workspace_premium_outlined,
                onPressed: () => Navigator.pushNamed(context, RouteNames.premium),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    RouteNames.featureControls,
                  ),
                  icon: const Icon(Icons.tune_outlined),
                  label: const Text('Feature Controls'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _unlockedView(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            children: [
              _providerStatusCard(),
              const SizedBox(height: AppSpacing.md),
              _modeBannerCard(),
              const SizedBox(height: AppSpacing.md),
              _guardrailCard(),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _starterPrompts.map(_starterChip).toList(),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _clearLocalChat,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear Local Chat'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: _messages.length,
            itemBuilder: (context, index) => _bubble(_messages[index]),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Type a message for the prototype coach...',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI Recovery Coach')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final canUseAiChat =
        _premiumStatus.hasAiPremium && _featureSettings.aiChatEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Recovery Coach'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, RouteNames.premium),
            icon: const Icon(Icons.workspace_premium_outlined),
          ),
        ],
      ),
      body: canUseAiChat ? _unlockedView(context) : _lockedView(context),
    );
  }
}
EOD

cat > lib/features/premium/presentation/premium_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../ai_chat/data/ai_backend_config_repository.dart';
import '../../ai_chat/data/ai_backend_preflight_service.dart';
import '../../ai_chat/data/ai_chat_settings_repository.dart';
import '../../ai_chat/data/ai_runtime_gate_repository.dart';
import '../../ai_chat/domain/ai_backend_config.dart';
import '../../ai_chat/domain/ai_preflight_status.dart';
import '../../ai_chat/domain/chat_provider_mode.dart';
import '../../settings/data/feature_control_settings_repository.dart';
import '../../settings/domain/feature_control_settings.dart';
import '../data/premium_access_repository.dart';
import '../domain/premium_plan.dart';
import '../domain/premium_status.dart';
import 'widgets/premium_badge.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final PremiumAccessRepository _repository = PremiumAccessRepository();
  final AiChatSettingsRepository _chatSettingsRepository =
      AiChatSettingsRepository();
  final AiBackendConfigRepository _backendRepository =
      AiBackendConfigRepository();
  final AiRuntimeGateRepository _runtimeGateRepository =
      AiRuntimeGateRepository();
  final AiBackendPreflightService _preflightService =
      AiBackendPreflightService();
  final FeatureControlSettingsRepository _featureRepository =
      FeatureControlSettingsRepository();

  PremiumStatus _status = PremiumStatus.defaults();
  ChatProviderMode _providerMode = ChatProviderMode.mock;
  AiBackendConfig _backendConfig = AiBackendConfig.defaults();
  AiPreflightStatus _preflight = AiPreflightStatus.initial();
  FeatureControlSettings _featureSettings =
      FeatureControlSettings.defaults();
  bool _remotePathEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final status = await _repository.getStatus();
    final chatSettings = await _chatSettingsRepository.getSettings();
    final backendConfig = await _backendRepository.getConfig();
    final remotePathEnabled = await _runtimeGateRepository.getRemotePathEnabled();
    final preflight = await _preflightService.run();
    final featureSettings = await _featureRepository.getSettings();

    if (!mounted) {
      return;
    }

    setState(() {
      _status = status;
      _providerMode = chatSettings.providerMode;
      _backendConfig = backendConfig;
      _remotePathEnabled = remotePathEnabled;
      _preflight = preflight;
      _featureSettings = featureSettings;
      _loading = false;
    });
  }

  Future<void> _setPlan(PremiumPlan plan) async {
    await _repository.setPlan(plan);
    await _load();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Premium plan set to ${plan.label}.')),
    );
  }

  Future<void> _togglePrompts(bool value) async {
    await _repository.setUpgradePrompts(value);
    await _load();
  }

  Future<void> _setProviderMode(ChatProviderMode mode) async {
    await _chatSettingsRepository.setProviderMode(mode);
    await _load();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('AI provider mode set to ${mode.label}.')),
    );
  }

  Future<void> _setRemotePathEnabled(bool value) async {
    await _runtimeGateRepository.setRemotePathEnabled(value);
    await _load();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Remote backend path enabled, but still stubbed.'
              : 'Remote backend path disabled.',
        ),
      ),
    );
  }

  Future<void> _showBackendSheet() async {
    final modelController = TextEditingController(text: _backendConfig.modelName);
    final baseUrlController = TextEditingController(text: _backendConfig.apiBaseUrl);
    final apiKeyController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Backend Config', style: AppTypography.title),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'This prepares the future paid backend path. Risky features stay disabled on purpose.',
                style: AppTypography.muted,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: modelController,
                decoration: const InputDecoration(
                  labelText: 'Model Name',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: baseUrlController,
                decoration: const InputDecoration(
                  labelText: 'API Base URL',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: apiKeyController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'API Key (optional for later)',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Forced-off features', style: AppTypography.section),
                    SizedBox(height: AppSpacing.sm),
                    Text('Grounding: off', style: AppTypography.body),
                    SizedBox(height: 4),
                    Text('Maps grounding: off', style: AppTypography.body),
                    SizedBox(height: 4),
                    Text('Session memory: off', style: AppTypography.body),
                    SizedBox(height: 4),
                    Text('File uploads: off', style: AppTypography.body),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Save Backend Config',
                icon: Icons.save_outlined,
                onPressed: () async {
                  final updated = _backendConfig.copyWith(
                    modelName: modelController.text.trim().isEmpty
                        ? _backendConfig.modelName
                        : modelController.text.trim(),
                    apiBaseUrl: baseUrlController.text.trim().isEmpty
                        ? _backendConfig.apiBaseUrl
                        : baseUrlController.text.trim(),
                    allowGrounding: false,
                    allowMapsGrounding: false,
                    allowSessionMemory: false,
                    allowFileUploads: false,
                  );

                  await _backendRepository.saveConfig(updated);

                  final apiKey = apiKeyController.text.trim();
                  if (apiKey.isNotEmpty) {
                    await _backendRepository.saveApiKey(apiKey);
                  }

                  if (sheetContext.mounted) {
                    Navigator.pop(sheetContext);
                  }
                  await _load();

                  if (!mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Backend config saved.')),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await _backendRepository.clearApiKey();
                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                    }
                    await _load();
                    if (!mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved API key removed.')),
                    );
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove Saved API Key'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _featureCard({
    required String title,
    required String subtitle,
  }) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: AppTypography.section),
              const SizedBox(width: 8),
              const PremiumBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(subtitle, style: AppTypography.muted),
        ],
      ),
    );
  }

  Widget _preflightCard() {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Paid Path Preflight', style: AppTypography.section),
          const SizedBox(height: AppSpacing.sm),
          Text('Provider: ${_preflight.providerModeLabel}', style: AppTypography.body),
          const SizedBox(height: 4),
          Text(
            _preflight.remotePathEnabled
                ? 'Remote path: enabled'
                : 'Remote path: disabled',
            style: AppTypography.body,
          ),
          const SizedBox(height: 4),
          Text(
            _preflight.apiKeyPresent ? 'API key: present' : 'API key: missing',
            style: AppTypography.body,
          ),
          const SizedBox(height: 4),
          Text(
            _preflight.riskyFeaturesForcedOff
                ? 'Risky features: forced off'
                : 'Risky features: unsafe',
            style: AppTypography.body,
          ),
          const SizedBox(height: 8),
          Text(_preflight.summaryLine, style: AppTypography.muted),
          if (_preflight.blockerLines.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            for (final line in _preflight.blockerLines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $line', style: AppTypography.body),
              ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Premium')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Premium')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Breakout Premium', style: AppTypography.title),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Choose the tier and feature comfort level that fits you best.',
            style: AppTypography.muted,
          ),
          const SizedBox(height: AppSpacing.lg),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Plan', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<PremiumPlan>(
                  initialValue: _status.plan,
                  decoration: const InputDecoration(
                    labelText: 'Premium Plan',
                  ),
                  items: PremiumPlan.values
                      .map(
                        (plan) => DropdownMenuItem<PremiumPlan>(
                          value: plan,
                          child: Text(plan.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    _setPlan(value);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(_status.plan.subtitle, style: AppTypography.muted),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _status.showUpgradePrompts,
                  onChanged: _togglePrompts,
                  title: const Text('Show Upgrade Prompts'),
                  subtitle: const Text(
                    'Controls whether soft premium prompts appear in the app.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Feature Controls', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'AI chat: ${_featureSettings.aiChatEnabled ? 'on' : 'off'} • '
                  'AI guidance: ${_featureSettings.aiGuidanceEnabled ? 'on' : 'off'} • '
                  'Faith layer: ${_featureSettings.faithLayerEnabled ? 'on' : 'off'}',
                  style: AppTypography.body,
                ),
                const SizedBox(height: 8),
                Text(
                  'Startup notice: ${_featureSettings.showStartupNotice ? 'on' : 'off'} • '
                  'Remote AI features: ${_featureSettings.remoteAiFeaturesEnabled ? 'on' : 'off'}',
                  style: AppTypography.body,
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Open Feature Controls',
                  icon: Icons.tune_outlined,
                  onPressed: () => Navigator.pushNamed(
                    context,
                    RouteNames.featureControls,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Chat Provider Mode', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Choose the prototype provider path. Keep using sanitized dummy prompts only until the real privacy-safe backend is ready.',
                  style: AppTypography.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<ChatProviderMode>(
                  initialValue: _providerMode,
                  decoration: const InputDecoration(
                    labelText: 'Provider Mode',
                  ),
                  items: ChatProviderMode.values
                      .map(
                        (mode) => DropdownMenuItem<ChatProviderMode>(
                          value: mode,
                          child: Text(mode.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    _setProviderMode(value);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _providerMode.description,
                  style: AppTypography.muted,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Remote Path Kill Switch', style: AppTypography.section),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _remotePathEnabled,
                  onChanged: _setRemotePathEnabled,
                  title: const Text('Enable Remote Backend Path'),
                  subtitle: const Text(
                    'This arms the paid backend path only after all preflight checks pass. It still uses a stub transport today.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Paid Backend Readiness', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                Text('Model: ${_backendConfig.modelName}', style: AppTypography.body),
                const SizedBox(height: 4),
                Text('Base URL: ${_backendConfig.apiBaseUrl}', style: AppTypography.body),
                const SizedBox(height: 4),
                Text(
                  _backendConfig.hasApiKey ? 'API key saved securely' : 'No API key saved',
                  style: AppTypography.body,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Grounding, maps grounding, session memory, and file uploads are intentionally forced off.',
                  style: AppTypography.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Open Backend Config',
                  icon: Icons.admin_panel_settings_outlined,
                  onPressed: _showBackendSheet,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _preflightCard(),
          const SizedBox(height: AppSpacing.md),
          const InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prototype AI Guardrails', style: AppTypography.section),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'The current prototype blocks minor sexual content and imminent self-harm or violence language, and scrubs obvious identifying details before prototype processing.',
                  style: AppTypography.muted,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _featureCard(
            title: 'Breakout Plus',
            subtitle:
                'Premium app experience without AI chat. Strong local-first premium path.',
          ),
          const SizedBox(height: AppSpacing.md),
          _featureCard(
            title: 'Breakout Plus AI',
            subtitle:
                'Everything in Plus, plus optional AI guidance and chat features.',
          ),
        ],
      ),
    );
  }
}
EOD

cat > lib/features/support/presentation/support_screen.dart <<'EOD'
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../quotes/data/quote_preferences_repository.dart';
import '../../quotes/domain/daily_quote.dart';
import '../data/support_contact_repository.dart';
import '../domain/support_contact.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final QuotePreferencesRepository _quotePreferences =
      QuotePreferencesRepository();
  final SupportContactRepository _contactRepository =
      SupportContactRepository();

  QuoteMode _mode = QuoteMode.recovery;
  String _religion = 'Christian';
  bool _loading = true;
  SupportContact? _trustedContact;

  static const List<String> _religions = <String>[
    'Christian',
    'General Faith',
    'Secular',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final mode = await _quotePreferences.getMode();
    final religion = await _quotePreferences.getReligionTag();
    final contact = await _contactRepository.getContact();

    if (!mounted) {
      return;
    }

    setState(() {
      _mode = mode;
      _religion = religion;
      _trustedContact = contact;
      _loading = false;
    });
  }

  Future<void> _saveMode(QuoteMode mode) async {
    await _quotePreferences.saveMode(mode);
    if (!mounted) {
      return;
    }
    setState(() => _mode = mode);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved ${mode.name} quote mode.')),
    );
  }

  Future<void> _saveReligion(String value) async {
    await _quotePreferences.saveReligionTag(value);
    if (!mounted) {
      return;
    }
    setState(() => _religion = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved faith preference: $value.')),
    );
  }

  Future<void> _launchUri(Uri uri, String failureMessage) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) {
      return;
    }
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failureMessage)),
      );
    }
  }

  Future<void> _call988() async {
    await _launchUri(
      Uri(scheme: 'tel', path: '988'),
      'Could not open the phone app for 988.',
    );
  }

  Future<void> _text988() async {
    await _launchUri(
      Uri(scheme: 'sms', path: '988'),
      'Could not open the messaging app for 988.',
    );
  }

  Future<void> _callTrustedContact() async {
    final contact = _trustedContact;
    if (contact == null) return;
    await _launchUri(
      Uri(scheme: 'tel', path: contact.phone),
      'Could not open the phone app for ${contact.name}.',
    );
  }

  Future<void> _textTrustedContact() async {
    final contact = _trustedContact;
    if (contact == null) return;
    await _launchUri(
      Uri(
        scheme: 'sms',
        path: contact.phone,
        queryParameters: <String, String>{
          'body': 'I need support right now. Please check on me.',
        },
      ),
      'Could not open messaging for ${contact.name}.',
    );
  }

  Future<void> _showTrustedContactSheet() async {
    final nameController =
        TextEditingController(text: _trustedContact?.name ?? '');
    final phoneController =
        TextEditingController(text: _trustedContact?.phone ?? '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Trusted Contact', style: AppTypography.title),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Add one person you can reach quickly during a hard moment.',
                style: AppTypography.muted,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Save Contact',
                icon: Icons.person_add_alt_1_outlined,
                onPressed: () async {
                  final contact = SupportContact(
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                  );

                  if (!contact.isValid) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      const SnackBar(
                        content: Text('Enter both a name and phone number.'),
                      ),
                    );
                    return;
                  }

                  await _contactRepository.saveContact(contact);

                  if (!mounted) {
                    return;
                  }

                  setState(() => _trustedContact = contact);
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Saved trusted contact: ${contact.name}.'),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _clearTrustedContact() async {
    await _contactRepository.clearContact();
    if (!mounted) {
      return;
    }
    setState(() => _trustedContact = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trusted contact removed.')),
    );
  }

  Widget _modeButton({
    required String label,
    required QuoteMode mode,
  }) {
    final selected = _mode == mode;
    return Expanded(
      child: OutlinedButton(
        onPressed: () => _saveMode(mode),
        child: Text(selected ? '$label ✓' : label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Support')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Emergency Help', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Fast access to crisis support and trusted people.',
                  style: AppTypography.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Call 988',
                  icon: Icons.call_outlined,
                  onPressed: _call988,
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _text988,
                    icon: const Icon(Icons.sms_outlined),
                    label: const Text('Text 988'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trusted Contact', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _trustedContact == null
                      ? 'No trusted contact saved yet.'
                      : 'Saved contact: ${_trustedContact!.name} • ${_trustedContact!.phone}',
                  style: AppTypography.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: _trustedContact == null
                      ? 'Add Trusted Contact'
                      : 'Update Trusted Contact',
                  icon: Icons.person_outline,
                  onPressed: _showTrustedContactSheet,
                ),
                if (_trustedContact != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _callTrustedContact,
                      icon: const Icon(Icons.call_outlined),
                      label: Text('Call ${_trustedContact!.name}'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _textTrustedContact,
                      icon: const Icon(Icons.sms_outlined),
                      label: Text('Text ${_trustedContact!.name}'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _clearTrustedContact,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove Trusted Contact'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Feature Choices', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'You can keep things simple and local, or turn on optional features later. Nothing is forced.',
                  style: AppTypography.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Open Feature Controls',
                  icon: Icons.tune_outlined,
                  onPressed: () => Navigator.pushNamed(
                    context,
                    RouteNames.featureControls,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Premium Options', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Breakout Plus gives a premium app experience without AI chat. Breakout Plus AI adds optional AI features.',
                  style: AppTypography.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Open Premium',
                  icon: Icons.workspace_premium_outlined,
                  onPressed: () => Navigator.pushNamed(
                    context,
                    RouteNames.premium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Encouragement', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Choose the tone and faith layer you want on the Home screen.',
                  style: AppTypography.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _modeButton(
                      label: 'Motivational',
                      mode: QuoteMode.motivational,
                    ),
                    const SizedBox(width: 8),
                    _modeButton(
                      label: 'Recovery',
                      mode: QuoteMode.recovery,
                    ),
                    const SizedBox(width: 8),
                    _modeButton(
                      label: 'Faith',
                      mode: QuoteMode.faith,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _religion,
                  decoration: const InputDecoration(
                    labelText: 'Faith / Religion Preference',
                  ),
                  items: _religions
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    _saveReligion(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Privacy & Lock Mode', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Control who can open the app or view private areas like logs and cycle history.',
                  style: AppTypography.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Open Privacy Settings',
                  icon: Icons.lock_outline,
                  onPressed: () => Navigator.pushNamed(
                    context,
                    RouteNames.privacySettings,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
EOD

cat > lib/app/app_router.dart <<'EOD'
import 'package:flutter/material.dart';

import '../core/constants/route_names.dart';
import '../features/ai_chat/presentation/ai_chat_screen.dart';
import '../features/cycle/domain/cycle_stage.dart';
import '../features/cycle/presentation/cycle_screen.dart';
import '../features/educate/presentation/educate_screen.dart';
import '../features/insights/presentation/insights_screen.dart';
import '../features/log/presentation/cycle_stage_log_screen.dart';
import '../features/log/presentation/log_hub_screen.dart';
import '../features/log/presentation/mood_log_screen.dart';
import '../features/log/presentation/recovery_event_log_screen.dart';
import '../features/onboarding/presentation/home_entry_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/premium/presentation/premium_screen.dart';
import '../features/privacy/domain/lock_scope.dart';
import '../features/privacy/presentation/privacy_settings_screen.dart';
import '../features/privacy/presentation/protected_route_gate.dart';
import '../features/rescue/presentation/rescue_screen.dart';
import '../features/risk/presentation/risk_windows_screen.dart';
import '../features/settings/presentation/feature_controls_screen.dart';
import '../features/support/presentation/recovery_plan_screen.dart';
import '../features/support/presentation/support_screen.dart';
import '../features/widget/presentation/widget_preview_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.home:
        return MaterialPageRoute(
          builder: (_) => const HomeEntryScreen(),
        );
      case RouteNames.onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        );
      case RouteNames.rescue:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.app,
            isRescueRoute: true,
            child: RescueScreen(),
          ),
        );
      case RouteNames.cycle:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.cycle,
            child: CycleScreen(),
          ),
        );
      case RouteNames.logHub:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.logs,
            child: LogHubScreen(),
          ),
        );
      case RouteNames.moodLog:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.logs,
            child: MoodLogScreen(),
          ),
        );
      case RouteNames.cycleStageLog:
        final stage = settings.arguments is CycleStage
            ? settings.arguments as CycleStage
            : CycleStage.triggers;
        return MaterialPageRoute(
          builder: (_) => ProtectedRouteGate(
            scope: LockScope.logs,
            child: CycleStageLogScreen(initialStage: stage),
          ),
        );
      case RouteNames.recoveryEventLog:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.logs,
            child: RecoveryEventLogScreen(),
          ),
        );
      case RouteNames.insights:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.insights,
            child: InsightsScreen(),
          ),
        );
      case RouteNames.educate:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.app,
            child: EducateScreen(),
          ),
        );
      case RouteNames.premium:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.support,
            child: PremiumScreen(),
          ),
        );
      case RouteNames.aiChat:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.support,
            child: AiChatScreen(),
          ),
        );
      case RouteNames.featureControls:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.support,
            child: FeatureControlsScreen(),
          ),
        );
      case RouteNames.riskWindows:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.support,
            child: RiskWindowsScreen(),
          ),
        );
      case RouteNames.recoveryPlan:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.support,
            child: RecoveryPlanScreen(),
          ),
        );
      case RouteNames.widgetPreview:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.support,
            child: WidgetPreviewScreen(),
          ),
        );
      case RouteNames.support:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.support,
            child: SupportScreen(),
          ),
        );
      case RouteNames.privacySettings:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.app,
            child: PrivacySettingsScreen(),
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const HomeEntryScreen(),
        );
    }
  }
}
EOD

cat > tools/verify_ba28.py <<'EOD'
from pathlib import Path
import sys

REQUIRED = [
    'lib/core/constants/route_names.dart',
    'lib/features/premium/domain/premium_plan.dart',
    'lib/features/premium/domain/premium_status.dart',
    'lib/features/premium/data/premium_access_repository.dart',
    'lib/features/settings/domain/feature_control_settings.dart',
    'lib/features/settings/data/feature_control_settings_repository.dart',
    'lib/features/settings/presentation/feature_controls_screen.dart',
    'lib/features/home/presentation/widgets/startup_notice_sheet.dart',
    'lib/features/home/presentation/home_screen.dart',
    'lib/features/ai_chat/presentation/ai_chat_screen.dart',
    'lib/features/premium/presentation/premium_screen.dart',
    'lib/features/support/presentation/support_screen.dart',
    'lib/app/app_router.dart',
]

REQUIRED_TEXT = {
    'lib/core/constants/route_names.dart': "static const featureControls = '/feature-controls';",
    'lib/features/premium/domain/premium_plan.dart': 'Breakout Plus AI',
    'lib/features/premium/domain/premium_status.dart': 'bool get hasAiPremium',
    'lib/features/premium/data/premium_access_repository.dart': 'setPlan(PremiumPlan plan)',
    'lib/features/settings/domain/feature_control_settings.dart': 'showStartupNotice',
    'lib/features/settings/data/feature_control_settings_repository.dart': 'feature_remote_ai_enabled',
    'lib/features/settings/presentation/feature_controls_screen.dart': 'Choose your comfort level.',
    'lib/features/home/presentation/widgets/startup_notice_sheet.dart': 'Welcome to Breakout',
    'lib/features/home/presentation/home_screen.dart': '_startupNoticeHandledThisSession',
    'lib/features/ai_chat/presentation/ai_chat_screen.dart': 'Breakout Plus AI is part of',
    'lib/features/premium/presentation/premium_screen.dart': 'Premium Plan',
    'lib/features/support/presentation/support_screen.dart': 'Feature Choices',
    'lib/app/app_router.dart': 'case RouteNames.featureControls:',
}

def main() -> int:
    root = Path.cwd()

    missing = [path for path in REQUIRED if not (root / path).exists()]
    if missing:
        print('Missing files:')
        for item in missing:
            print(f' - {item}')
        return 1

    bad = []
    for path, needle in REQUIRED_TEXT.items():
        text = (root / path).read_text(encoding='utf-8')
        if needle not in text:
            bad.append((path, needle))

    if bad:
        print('Content checks failed:')
        for path, needle in bad:
            print(f' - {path} missing: {needle}')
        return 1

    print('Breakout Addiction BA-28 notice, tiers, and controls verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
EOD

echo "==> BA-28 notice, tiers, and controls scaffold written."
echo "==> Running Python verification..."
python3 tools/verify_ba28.py
