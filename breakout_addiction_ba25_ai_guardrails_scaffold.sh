#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

echo "==> Applying Breakout Addiction BA-25 AI guardrails scaffold in: $ROOT_DIR"

mkdir -p \
  lib/features/ai_chat/domain \
  lib/features/ai_chat/data \
  tools

cat > lib/features/ai_chat/domain/guardrail_result.dart <<'EOD'
enum GuardrailBlockReason {
  none,
  minorSexualContent,
  imminentSelfHarm,
  imminentViolence,
}

extension GuardrailBlockReasonX on GuardrailBlockReason {
  String get label {
    switch (this) {
      case GuardrailBlockReason.none:
        return 'None';
      case GuardrailBlockReason.minorSexualContent:
        return 'Minor sexual content';
      case GuardrailBlockReason.imminentSelfHarm:
        return 'Imminent self-harm';
      case GuardrailBlockReason.imminentViolence:
        return 'Imminent violence';
    }
  }

  String get userMessage {
    switch (this) {
      case GuardrailBlockReason.none:
        return '';
      case GuardrailBlockReason.minorSexualContent:
        return 'This prototype AI coach cannot process sexual content involving minors. Do not continue in chat.';
      case GuardrailBlockReason.imminentSelfHarm:
        return 'This prototype AI coach cannot handle imminent self-harm situations. In the U.S., call or text 988 right now, or call emergency services if you are in immediate danger.';
      case GuardrailBlockReason.imminentViolence:
        return 'This prototype AI coach cannot handle imminent violence situations. Step away from chat and contact emergency services if there is immediate danger.';
    }
  }
}

class GuardrailResult {
  final bool blocked;
  final GuardrailBlockReason reason;
  final String sanitizedText;
  final List<String> scrubbedFlags;

  const GuardrailResult({
    required this.blocked,
    required this.reason,
    required this.sanitizedText,
    required this.scrubbedFlags,
  });

  factory GuardrailResult.allowed({
    required String sanitizedText,
    required List<String> scrubbedFlags,
  }) {
    return GuardrailResult(
      blocked: false,
      reason: GuardrailBlockReason.none,
      sanitizedText: sanitizedText,
      scrubbedFlags: scrubbedFlags,
    );
  }

  factory GuardrailResult.blocked(GuardrailBlockReason reason) {
    return GuardrailResult(
      blocked: true,
      reason: reason,
      sanitizedText: '',
      scrubbedFlags: const <String>[],
    );
  }

  bool get wasSanitized => scrubbedFlags.isNotEmpty;
}
EOD

cat > lib/features/ai_chat/data/ai_input_guardrail_service.dart <<'EOD'
import '../domain/guardrail_result.dart';

class AiInputGuardrailService {
  GuardrailResult review(String input) {
    final lowered = input.toLowerCase();

    if (_containsMinorSexualContent(lowered)) {
      return GuardrailResult.blocked(GuardrailBlockReason.minorSexualContent);
    }

    if (_containsImminentSelfHarm(lowered)) {
      return GuardrailResult.blocked(GuardrailBlockReason.imminentSelfHarm);
    }

    if (_containsImminentViolence(lowered)) {
      return GuardrailResult.blocked(GuardrailBlockReason.imminentViolence);
    }

    final flags = <String>[];
    var sanitized = input;

    final emailPattern = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b');
    if (emailPattern.hasMatch(sanitized)) {
      sanitized = sanitized.replaceAll(emailPattern, '[email removed]');
      flags.add('email');
    }

    final phonePattern = RegExp(r'(\+?1[\s\-\.]?)?(\(?\d{3}\)?[\s\-\.]?)\d{3}[\s\-\.]?\d{4}');
    if (phonePattern.hasMatch(sanitized)) {
      sanitized = sanitized.replaceAll(phonePattern, '[phone removed]');
      flags.add('phone');
    }

    final addressPattern = RegExp(
      r'\b\d{1,5}\s+[A-Za-z0-9.\- ]+\s(?:street|st|road|rd|avenue|ave|lane|ln|drive|dr|boulevard|blvd|court|ct)\b',
      caseSensitive: false,
    );
    if (addressPattern.hasMatch(sanitized)) {
      sanitized = sanitized.replaceAll(addressPattern, '[address removed]');
      flags.add('address');
    }

    final fullNamePattern = RegExp(
      r'\bmy name is\s+[A-Z][a-z]+\s+[A-Z][a-z]+\b',
      caseSensitive: false,
    );
    if (fullNamePattern.hasMatch(sanitized)) {
      sanitized = sanitized.replaceAll(fullNamePattern, 'my name is [name removed]');
      flags.add('name');
    }

    final exactLocationPattern = RegExp(
      r'\bi live in\s+[A-Za-z .,-]{3,}\b',
      caseSensitive: false,
    );
    if (exactLocationPattern.hasMatch(sanitized)) {
      sanitized = sanitized.replaceAll(exactLocationPattern, 'I live in [location removed]');
      flags.add('location');
    }

    return GuardrailResult.allowed(
      sanitizedText: sanitized.trim(),
      scrubbedFlags: flags,
    );
  }

  bool _containsMinorSexualContent(String text) {
    final hasMinorWord = text.contains('minor') ||
        text.contains('underage') ||
        text.contains('child') ||
        text.contains('kid') ||
        text.contains('teen') ||
        text.contains('teenager') ||
        text.contains('13 year old') ||
        text.contains('14 year old') ||
        text.contains('15 year old') ||
        text.contains('16 year old') ||
        text.contains('17 year old');

    final hasSexualWord = text.contains('sex') ||
        text.contains('sexual') ||
        text.contains('porn') ||
        text.contains('nude') ||
        text.contains('naked') ||
        text.contains('explicit');

    return hasMinorWord && hasSexualWord;
  }

  bool _containsImminentSelfHarm(String text) {
    return text.contains('kill myself') ||
        text.contains('suicide') ||
        text.contains('end my life') ||
        text.contains('hurt myself tonight') ||
        text.contains('harm myself tonight') ||
        text.contains('i am going to hurt myself') ||
        text.contains('i am going to kill myself');
  }

  bool _containsImminentViolence(String text) {
    return text.contains('kill him') ||
        text.contains('kill her') ||
        text.contains('kill them') ||
        text.contains('shoot him') ||
        text.contains('shoot her') ||
        text.contains('hurt them tonight') ||
        text.contains('i am going to hurt someone') ||
        text.contains('i am going to kill someone');
  }
}
EOD

cat > lib/features/ai_chat/domain/ai_guardrail_status.dart <<'EOD'
class AiGuardrailStatus {
  final bool piiScrubbingEnabled;
  final bool minorContentBlockingEnabled;
  final bool imminentSelfHarmBlockingEnabled;
  final bool imminentViolenceBlockingEnabled;

  const AiGuardrailStatus({
    required this.piiScrubbingEnabled,
    required this.minorContentBlockingEnabled,
    required this.imminentSelfHarmBlockingEnabled,
    required this.imminentViolenceBlockingEnabled,
  });

  factory AiGuardrailStatus.defaults() {
    return const AiGuardrailStatus(
      piiScrubbingEnabled: true,
      minorContentBlockingEnabled: true,
      imminentSelfHarmBlockingEnabled: true,
      imminentViolenceBlockingEnabled: true,
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
import '../data/ai_chat_repository.dart';
import '../data/ai_chat_settings_repository.dart';
import '../data/ai_input_guardrail_service.dart';
import '../data/chat_provider_factory.dart';
import '../domain/ai_chat_settings.dart';
import '../domain/chat_message.dart';
import '../domain/guardrail_result.dart';

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
  final TextEditingController _controller = TextEditingController();

  PremiumStatus _premiumStatus = PremiumStatus.defaults();
  AiChatSettings _settings = AiChatSettings.defaults();
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
import '../../ai_chat/data/ai_chat_settings_repository.dart';
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

  PremiumStatus _status = PremiumStatus.defaults();
  ChatProviderMode _providerMode = ChatProviderMode.mock;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final status = await _repository.getStatus();
    final chatSettings = await _chatSettingsRepository.getSettings();

    if (!mounted) {
      return;
    }

    setState(() {
      _status = status;
      _providerMode = chatSettings.providerMode;
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
cat > tools/verify_ba25.py <<'EOD'
from pathlib import Path
import sys

REQUIRED = [
    'lib/features/ai_chat/domain/guardrail_result.dart',
    'lib/features/ai_chat/data/ai_input_guardrail_service.dart',
    'lib/features/ai_chat/domain/ai_guardrail_status.dart',
    'lib/features/ai_chat/presentation/ai_chat_screen.dart',
    'lib/features/premium/presentation/premium_screen.dart',
]

REQUIRED_TEXT = {
    'lib/features/ai_chat/domain/guardrail_result.dart': 'enum GuardrailBlockReason',
    'lib/features/ai_chat/data/ai_input_guardrail_service.dart': 'class AiInputGuardrailService',
    'lib/features/ai_chat/domain/ai_guardrail_status.dart': 'class AiGuardrailStatus',
    'lib/features/ai_chat/presentation/ai_chat_screen.dart': 'Prototype guardrail: identifying details were scrubbed',
    'lib/features/premium/presentation/premium_screen.dart': 'Prototype AI Guardrails',
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

    print('Breakout Addiction BA-25 AI guardrails verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
EOD

echo "==> BA-25 AI guardrails scaffold written."
echo "==> Running Python verification..."
python3 tools/verify_ba25.py
