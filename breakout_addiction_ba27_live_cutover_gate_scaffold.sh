#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

echo "==> Applying Breakout Addiction BA-27 live cutover gate scaffold in: $ROOT_DIR"

mkdir -p \
  lib/features/ai_chat/domain \
  lib/features/ai_chat/data \
  tools

cat > lib/features/ai_chat/domain/ai_preflight_status.dart <<'EOD'
class AiPreflightStatus {
  final bool premiumUnlocked;
  final String providerModeLabel;
  final bool providerIsVertexPrivateReady;
  final bool remotePathEnabled;
  final bool apiKeyPresent;
  final bool riskyFeaturesForcedOff;
  final bool readyForRemoteStub;
  final String summaryLine;
  final List<String> blockerLines;

  const AiPreflightStatus({
    required this.premiumUnlocked,
    required this.providerModeLabel,
    required this.providerIsVertexPrivateReady,
    required this.remotePathEnabled,
    required this.apiKeyPresent,
    required this.riskyFeaturesForcedOff,
    required this.readyForRemoteStub,
    required this.summaryLine,
    required this.blockerLines,
  });

  factory AiPreflightStatus.initial() {
    return const AiPreflightStatus(
      premiumUnlocked: false,
      providerModeLabel: 'Mock',
      providerIsVertexPrivateReady: false,
      remotePathEnabled: false,
      apiKeyPresent: false,
      riskyFeaturesForcedOff: true,
      readyForRemoteStub: false,
      summaryLine: 'Preflight not loaded yet.',
      blockerLines: <String>[],
    );
  }
}
EOD

cat > lib/features/ai_chat/data/ai_runtime_gate_repository.dart <<'EOD'
import 'package:shared_preferences/shared_preferences.dart';

class AiRuntimeGateRepository {
  static const String _remotePathEnabledKey = 'ai_remote_path_enabled';

  Future<bool> getRemotePathEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_remotePathEnabledKey) ?? false;
  }

  Future<void> setRemotePathEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_remotePathEnabledKey, value);
  }
}
EOD

cat > lib/features/ai_chat/data/ai_backend_preflight_service.dart <<'EOD'
import '../../premium/data/premium_access_repository.dart';
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

  Future<AiPreflightStatus> run() async {
    final premium = await _premiumRepository.getStatus();
    final settings = await _settingsRepository.getSettings();
    final backend = await _backendRepository.getConfig();
    final remoteEnabled = await _runtimeGateRepository.getRemotePathEnabled();

    final providerIsVertex =
        settings.providerMode == ChatProviderMode.vertexPrivateReady;

    final riskyFeaturesForcedOff = !backend.allowGrounding &&
        !backend.allowMapsGrounding &&
        !backend.allowSessionMemory &&
        !backend.allowFileUploads;

    final blockers = <String>[];

    if (!premium.isUnlocked) {
      blockers.add('Premium is locked.');
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

    final readyForRemoteStub = premium.isUnlocked &&
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
      premiumUnlocked: premium.isUnlocked,
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

cat > lib/features/ai_chat/data/ai_remote_transport.dart <<'EOD'
import '../domain/ai_backend_config.dart';
import '../domain/chat_message.dart';

abstract class AiRemoteTransport {
  Future<String> send({
    required List<ChatMessage> messages,
    required String userInput,
    required AiBackendConfig config,
  });
}
EOD

cat > lib/features/ai_chat/data/vertex_transport_stub.dart <<'EOD'
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
EOD
cat > lib/features/ai_chat/data/vertex_private_ready_provider.dart <<'EOD'
import '../domain/chat_message.dart';
import '../domain/chat_provider.dart';
import 'ai_backend_config_repository.dart';
import 'ai_remote_transport.dart';

class VertexPrivateReadyProvider implements ChatProvider {
  final AiRemoteTransport transport;
  final AiBackendConfigRepository _configRepository =
      AiBackendConfigRepository();

  VertexPrivateReadyProvider({
    required this.transport,
  });

  @override
  Future<ChatMessage> generateReply({
    required List<ChatMessage> messages,
    required String userInput,
  }) async {
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
EOD

python3 - <<'EOD'
from pathlib import Path

factory_path = Path('lib/features/ai_chat/data/chat_provider_factory.dart')
factory_text = factory_path.read_text(encoding='utf-8')

if "import 'vertex_transport_stub.dart';" not in factory_text:
    factory_text = factory_text.replace(
        "import 'vertex_private_ready_provider.dart';\n",
        "import 'vertex_private_ready_provider.dart';\nimport 'vertex_transport_stub.dart';\n",
    )

factory_text = factory_text.replace(
"""      case ChatProviderMode.vertexPrivateReady:
        return VertexPrivateReadyProvider();
""",
"""      case ChatProviderMode.vertexPrivateReady:
        return VertexPrivateReadyProvider(
          transport: VertexTransportStub(),
        );
""")

factory_path.write_text(factory_text, encoding='utf-8')
print('Patched chat_provider_factory.dart')
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
  final AiInputGuardrailService _guardrailService = AiInputGuardrailService();
  final AiBackendPreflightService _preflightService =
      AiBackendPreflightService();
  final TextEditingController _controller = TextEditingController();

  PremiumStatus _premiumStatus = PremiumStatus.defaults();
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
    final messages = await _chatRepository.getMessages();
    final settings = await _settingsRepository.getSettings();
    final preflight = await _preflightService.run();

    if (!mounted) {
      return;
    }

    final loadedMessages = <ChatMessage>[...messages];
    if (premium.isUnlocked && loadedMessages.isEmpty) {
      loadedMessages.add(_welcomeMessage());
      await _chatRepository.saveMessages(loadedMessages);
    }

    setState(() {
      _premiumStatus = premium;
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
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('AI Recovery Coach', style: AppTypography.title),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'This is a premium prototype feature. The paid version will be privacy-first, but this shell does not make confidentiality promises.',
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
                'Premium AI chat will help users reflect, interrupt patterns earlier, and use recovery tools more consistently.',
                style: AppTypography.muted,
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Open Premium',
                icon: Icons.workspace_premium_outlined,
                onPressed: () => Navigator.pushNamed(context, RouteNames.premium),
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
      body: _premiumStatus.isUnlocked
          ? _unlockedView(context)
          : _lockedView(context),
    );
  }
}
EOD

cat > lib/features/premium/presentation/premium_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../ai_chat/data/ai_backend_config_repository.dart';
import '../../ai_chat/data/ai_backend_preflight_service.dart';
import '../../ai_chat/data/ai_chat_settings_repository.dart';
import '../../ai_chat/data/ai_runtime_gate_repository.dart';
import '../../ai_chat/domain/ai_backend_config.dart';
import '../../ai_chat/domain/ai_preflight_status.dart';
import '../../ai_chat/domain/chat_provider_mode.dart';
import '../data/premium_access_repository.dart';
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

  PremiumStatus _status = PremiumStatus.defaults();
  ChatProviderMode _providerMode = ChatProviderMode.mock;
  AiBackendConfig _backendConfig = AiBackendConfig.defaults();
  AiPreflightStatus _preflight = AiPreflightStatus.initial();
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

    if (!mounted) {
      return;
    }

    setState(() {
      _status = status;
      _providerMode = chatSettings.providerMode;
      _backendConfig = backendConfig;
      _remotePathEnabled = remotePathEnabled;
      _preflight = preflight;
      _loading = false;
    });
  }

  Future<void> _toggleDemoUnlock(bool value) async {
    await _repository.setUnlocked(value);
    await _load();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value
            ? 'Premium demo unlocked locally.'
            : 'Premium demo returned to locked state.'),
      ),
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
          Text('Breakout Plus', style: AppTypography.title),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Core recovery help stays free. Premium is for deeper guidance, richer learning, and future advanced tools.',
            style: AppTypography.muted,
          ),
          const SizedBox(height: AppSpacing.lg),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Access', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _status.isUnlocked ? 'Premium unlocked' : 'Premium locked',
                  style: AppTypography.body,
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _status.isUnlocked,
                  onChanged: _toggleDemoUnlock,
                  title: const Text('Local Demo Unlock'),
                  subtitle: const Text(
                    'Safe dev toggle for local testing until real billing is wired later.',
                  ),
                ),
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
            title: 'Educate Me Plus',
            subtitle:
                'Deeper pattern breakdowns, topic tracks, and richer learning modules.',
          ),
          const SizedBox(height: AppSpacing.md),
          _featureCard(
            title: 'Advanced Insights',
            subtitle:
                'Longer pattern history, stronger summaries, and more detailed behavior trends.',
          ),
          const SizedBox(height: AppSpacing.md),
          _featureCard(
            title: 'Future Coaching Layer',
            subtitle:
                'Reserved space for later premium guidance and expanded support tools.',
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: _status.isUnlocked ? 'Premium Active' : 'Upgrade Hooks Ready',
            icon: Icons.workspace_premium_outlined,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
EOD
cat > tools/verify_ba27.py <<'EOD'
from pathlib import Path
import sys

REQUIRED = [
    'lib/features/ai_chat/domain/ai_preflight_status.dart',
    'lib/features/ai_chat/data/ai_runtime_gate_repository.dart',
    'lib/features/ai_chat/data/ai_backend_preflight_service.dart',
    'lib/features/ai_chat/data/ai_remote_transport.dart',
    'lib/features/ai_chat/data/vertex_transport_stub.dart',
    'lib/features/ai_chat/data/vertex_private_ready_provider.dart',
    'lib/features/ai_chat/presentation/ai_chat_screen.dart',
    'lib/features/premium/presentation/premium_screen.dart',
]

REQUIRED_TEXT = {
    'lib/features/ai_chat/domain/ai_preflight_status.dart': 'class AiPreflightStatus',
    'lib/features/ai_chat/data/ai_runtime_gate_repository.dart': 'getRemotePathEnabled',
    'lib/features/ai_chat/data/ai_backend_preflight_service.dart': 'class AiBackendPreflightService',
    'lib/features/ai_chat/data/ai_remote_transport.dart': 'abstract class AiRemoteTransport',
    'lib/features/ai_chat/data/vertex_transport_stub.dart': 'Vertex transport stub only',
    'lib/features/ai_chat/data/vertex_private_ready_provider.dart': 'required this.transport',
    'lib/features/ai_chat/presentation/ai_chat_screen.dart': 'Paid backend path blocked by preflight checks.',
    'lib/features/premium/presentation/premium_screen.dart': 'Remote Path Kill Switch',
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

    print('Breakout Addiction BA-27 live cutover gate verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
EOD

echo "==> BA-27 live cutover gate scaffold written."
echo "==> Running Python verification..."
python3 tools/verify_ba27.py
