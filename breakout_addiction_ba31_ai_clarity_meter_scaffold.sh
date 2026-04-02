#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

echo "==> Applying Breakout Addiction BA-31 AI clarity, usage meter, and emergency fallback scaffold in: $ROOT_DIR"

mkdir -p \
  lib/features/ai_chat/domain \
  lib/features/ai_chat/data \
  lib/features/ai_chat/presentation/widgets \
  tools

cat > lib/features/ai_chat/domain/ai_usage_snapshot.dart <<'EOD'
class AiUsageSnapshot {
  final int promptAttempts;
  final int stoppedAttempts;
  final int livePrototypeCalls;
  final int localOrStubReplies;
  final String lastModeLabel;

  const AiUsageSnapshot({
    required this.promptAttempts,
    required this.stoppedAttempts,
    required this.livePrototypeCalls,
    required this.localOrStubReplies,
    required this.lastModeLabel,
  });

  factory AiUsageSnapshot.empty() {
    return const AiUsageSnapshot(
      promptAttempts: 0,
      stoppedAttempts: 0,
      livePrototypeCalls: 0,
      localOrStubReplies: 0,
      lastModeLabel: 'No activity yet',
    );
  }
}
EOD

cat > lib/features/ai_chat/data/ai_usage_repository.dart <<'EOD'
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/ai_usage_snapshot.dart';

class AiUsageRepository {
  static const String _promptAttemptsKey = 'ai_usage_prompt_attempts';
  static const String _stoppedAttemptsKey = 'ai_usage_stopped_attempts';
  static const String _livePrototypeCallsKey = 'ai_usage_live_prototype_calls';
  static const String _localOrStubRepliesKey = 'ai_usage_local_or_stub_replies';
  static const String _lastModeLabelKey = 'ai_usage_last_mode_label';

  Future<AiUsageSnapshot> getSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    return AiUsageSnapshot(
      promptAttempts: prefs.getInt(_promptAttemptsKey) ?? 0,
      stoppedAttempts: prefs.getInt(_stoppedAttemptsKey) ?? 0,
      livePrototypeCalls: prefs.getInt(_livePrototypeCallsKey) ?? 0,
      localOrStubReplies: prefs.getInt(_localOrStubRepliesKey) ?? 0,
      lastModeLabel: prefs.getString(_lastModeLabelKey) ?? 'No activity yet',
    );
  }

  Future<void> recordStoppedAttempt({
    required String modeLabel,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _promptAttemptsKey,
      (prefs.getInt(_promptAttemptsKey) ?? 0) + 1,
    );
    await prefs.setInt(
      _stoppedAttemptsKey,
      (prefs.getInt(_stoppedAttemptsKey) ?? 0) + 1,
    );
    await prefs.setString(_lastModeLabelKey, modeLabel);
  }

  Future<void> recordSuccessfulReply({
    required String modeLabel,
    required bool livePrototype,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _promptAttemptsKey,
      (prefs.getInt(_promptAttemptsKey) ?? 0) + 1,
    );

    if (livePrototype) {
      await prefs.setInt(
        _livePrototypeCallsKey,
        (prefs.getInt(_livePrototypeCallsKey) ?? 0) + 1,
      );
    } else {
      await prefs.setInt(
        _localOrStubRepliesKey,
        (prefs.getInt(_localOrStubRepliesKey) ?? 0) + 1,
      );
    }

    await prefs.setString(_lastModeLabelKey, modeLabel);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_promptAttemptsKey);
    await prefs.remove(_stoppedAttemptsKey);
    await prefs.remove(_livePrototypeCallsKey);
    await prefs.remove(_localOrStubRepliesKey);
    await prefs.remove(_lastModeLabelKey);
  }
}
EOD
cat > lib/features/ai_chat/presentation/widgets/ai_mode_clarity_card.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/info_card.dart';

class AiModeClarityCard extends StatelessWidget {
  final String modeLabel;
  final String summaryLine;
  final List<String> blockers;

  const AiModeClarityCard({
    super.key,
    required this.modeLabel,
    required this.summaryLine,
    required this.blockers,
  });

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current AI State', style: AppTypography.section),
          const SizedBox(height: AppSpacing.sm),
          Chip(label: Text(modeLabel)),
          const SizedBox(height: AppSpacing.sm),
          Text(summaryLine, style: AppTypography.muted),
          if (blockers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            for (final line in blockers)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $line', style: AppTypography.body),
              ),
          ],
        ],
      ),
    );
  }
}
EOD

cat > lib/features/ai_chat/presentation/widgets/ai_usage_meter_card.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/info_card.dart';
import '../../domain/ai_usage_snapshot.dart';

class AiUsageMeterCard extends StatelessWidget {
  final AiUsageSnapshot snapshot;
  final VoidCallback onReset;

  const AiUsageMeterCard({
    super.key,
    required this.snapshot,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AI Usage Meter', style: AppTypography.section),
          const SizedBox(height: AppSpacing.sm),
          Text('Prompt attempts: ${snapshot.promptAttempts}', style: AppTypography.body),
          const SizedBox(height: 4),
          Text('Stopped attempts: ${snapshot.stoppedAttempts}', style: AppTypography.body),
          const SizedBox(height: 4),
          Text('Live prototype calls: ${snapshot.livePrototypeCalls}', style: AppTypography.body),
          const SizedBox(height: 4),
          Text('Local or stub replies: ${snapshot.localOrStubReplies}', style: AppTypography.body),
          const SizedBox(height: 4),
          Text('Last mode: ${snapshot.lastModeLabel}', style: AppTypography.muted),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh_outlined),
              label: const Text('Reset Usage Meter'),
            ),
          ),
        ],
      ),
    );
  }
}
EOD

cat > lib/features/ai_chat/presentation/widgets/emergency_fallback_card.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../../core/widgets/primary_button.dart';

class EmergencyFallbackCard extends StatelessWidget {
  final VoidCallback onCall988;
  final VoidCallback onText988;
  final VoidCallback onOpenSupport;

  const EmergencyFallbackCard({
    super.key,
    required this.onCall988,
    required this.onText988,
    required this.onOpenSupport,
  });

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Emergency Fallback', style: AppTypography.section),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'AI chat is not the right tool for emergencies. If you might hurt yourself or someone else, leave chat and get human support now.',
            style: AppTypography.muted,
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Call 988',
            icon: Icons.call_outlined,
            onPressed: onCall988,
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onText988,
              icon: const Icon(Icons.sms_outlined),
              label: const Text('Text 988'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpenSupport,
              icon: const Icon(Icons.support_agent_outlined),
              label: const Text('Open Support'),
            ),
          ),
        ],
      ),
    );
  }
}
EOD
cat > lib/features/ai_chat/presentation/ai_chat_screen.dart <<'EOD'
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
import '../data/ai_usage_repository.dart';
import '../data/chat_provider_factory.dart';
import '../domain/ai_chat_settings.dart';
import '../domain/ai_preflight_status.dart';
import '../domain/ai_usage_snapshot.dart';
import '../domain/chat_message.dart';
import '../domain/chat_provider_mode.dart';
import 'widgets/ai_mode_clarity_card.dart';
import 'widgets/ai_usage_meter_card.dart';
import 'widgets/emergency_fallback_card.dart';

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
  final AiUsageRepository _usageRepository = AiUsageRepository();
  final TextEditingController _controller = TextEditingController();

  PremiumStatus _premiumStatus = PremiumStatus.defaults();
  FeatureControlSettings _featureSettings =
      FeatureControlSettings.defaults();
  AiChatSettings _settings = AiChatSettings.defaults();
  AiPreflightStatus _preflightStatus = AiPreflightStatus.initial();
  AiUsageSnapshot _usageSnapshot = AiUsageSnapshot.empty();
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

  String _currentModeLabel(AiPreflightStatus preflight) {
    if (_settings.providerMode == ChatProviderMode.mock) {
      return 'Local Mock';
    }
    if (_settings.providerMode == ChatProviderMode.geminiPrototype) {
      return preflight.readyForRemoteStub
          ? 'Gemini Live Prototype'
          : 'Gemini Prototype Blocked';
    }
    return preflight.readyForRemoteStub
        ? 'Vertex Armed Stub'
        : 'Vertex Private Ready';
  }

  Future<void> _load() async {
    final premium = await _premiumRepository.getStatus();
    final featureSettings = await _featureRepository.getSettings();
    final messages = await _chatRepository.getMessages();
    final settings = await _settingsRepository.getSettings();
    final preflight = await _preflightService.run();
    final usage = await _usageRepository.getSnapshot();

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
      _usageSnapshot = usage;
      _messages = loadedMessages;
      _loading = false;
    });
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

  Future<void> _refreshUsage() async {
    final usage = await _usageRepository.getSnapshot();
    if (!mounted) {
      return;
    }
    setState(() => _usageSnapshot = usage);
  }

  Future<void> _resetUsageMeter() async {
    await _usageRepository.clear();
    await _refreshUsage();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI usage meter reset.')),
    );
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

  Future<void> _send([String? starterText]) async {
    final raw = starterText ?? _controller.text;
    final input = raw.trim();
    if (input.isEmpty || _sending) {
      return;
    }

    final review = _guardrailService.review(input);

    if (review.blocked) {
      final modeLabel = _currentModeLabel(_preflightStatus);
      await _usageRepository.recordStoppedAttempt(modeLabel: modeLabel);
      await _refreshUsage();

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

    if ((_settings.providerMode == ChatProviderMode.vertexPrivateReady ||
            _settings.providerMode == ChatProviderMode.geminiPrototype) &&
        !freshPreflight.readyForRemoteStub &&
        _settings.providerMode != ChatProviderMode.mock) {
      final modeLabel = _currentModeLabel(freshPreflight);
      await _usageRepository.recordStoppedAttempt(modeLabel: modeLabel);
      await _refreshUsage();

      final blockedRemoteMessage = _systemStyleMessage(
        'Remote AI path is not ready yet. ${freshPreflight.summaryLine} ${freshPreflight.blockerLines.join(' ')}',
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
        const SnackBar(content: Text('AI request stopped by safety/preflight checks.')),
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

    final livePrototype = _settings.providerMode == ChatProviderMode.geminiPrototype &&
        freshPreflight.readyForRemoteStub;

    await _usageRepository.recordSuccessfulReply(
      modeLabel: _currentModeLabel(freshPreflight),
      livePrototype: livePrototype,
    );
    await _refreshUsage();

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
            'This screen blocks minor sexual content and imminent self-harm or violence language. It also scrubs obvious identifying details like phone numbers, emails, addresses, names, and exact locations before processing.',
            style: AppTypography.muted,
          ),
        ],
      ),
    );
  }

  Widget _lockedView(BuildContext context) {
    final whyLocked = !_premiumStatus.hasAiPremium
        ? 'Breakout Plus AI is required for AI chat.'
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
        AiModeClarityCard(
          modeLabel: _currentModeLabel(_preflightStatus),
          summaryLine: _preflightStatus.summaryLine,
          blockers: _preflightStatus.blockerLines,
        ),
        const SizedBox(height: AppSpacing.md),
        AiUsageMeterCard(
          snapshot: _usageSnapshot,
          onReset: _resetUsageMeter,
        ),
        const SizedBox(height: AppSpacing.md),
        _guardrailCard(),
        const SizedBox(height: AppSpacing.md),
        EmergencyFallbackCard(
          onCall988: _call988,
          onText988: _text988,
          onOpenSupport: () => Navigator.pushNamed(context, RouteNames.support),
        ),
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
              AiModeClarityCard(
                modeLabel: _currentModeLabel(_preflightStatus),
                summaryLine: _preflightStatus.summaryLine,
                blockers: _preflightStatus.blockerLines,
              ),
              const SizedBox(height: AppSpacing.md),
              AiUsageMeterCard(
                snapshot: _usageSnapshot,
                onReset: _resetUsageMeter,
              ),
              const SizedBox(height: AppSpacing.md),
              _guardrailCard(),
              const SizedBox(height: AppSpacing.md),
              EmergencyFallbackCard(
                onCall988: _call988,
                onText988: _text988,
                onOpenSupport: () => Navigator.pushNamed(context, RouteNames.support),
              ),
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
python3 - <<'EOD'
from pathlib import Path

premium_path = Path('lib/features/premium/presentation/premium_screen.dart')
premium_text = premium_path.read_text(encoding='utf-8')

needle = "Text('Breakout Premium', style: AppTypography.title),"
insert = """Text('Breakout Premium', style: AppTypography.title),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'You will always be able to see whether AI is local, stubbed, or live prototype. Emergencies should leave chat and go to human support immediately.',
            style: AppTypography.muted,
          ),"""

if needle in premium_text:
    premium_text = premium_text.replace(needle, insert, 1)

premium_path.write_text(premium_text, encoding='utf-8')
print('Patched premium_screen.dart')

support_path = Path('lib/features/support/presentation/support_screen.dart')
support_text = support_path.read_text(encoding='utf-8')

anchor = "Text('Emergency Help', style: AppTypography.section),"
replacement = """Text('Emergency Help', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'If AI ever feels confusing, inadequate, or too slow for the moment, leave chat and use human support instead.',
                  style: AppTypography.muted,
                ),
                const SizedBox(height: AppSpacing.sm),"""

if anchor in support_text:
    support_text = support_text.replace(anchor, replacement, 1)

support_path.write_text(support_text, encoding='utf-8')
print('Patched support_screen.dart')
EOD
cat > tools/verify_ba31.py <<'EOD'
from pathlib import Path
import sys

REQUIRED = [
    'lib/features/ai_chat/domain/ai_usage_snapshot.dart',
    'lib/features/ai_chat/data/ai_usage_repository.dart',
    'lib/features/ai_chat/presentation/widgets/ai_mode_clarity_card.dart',
    'lib/features/ai_chat/presentation/widgets/ai_usage_meter_card.dart',
    'lib/features/ai_chat/presentation/widgets/emergency_fallback_card.dart',
    'lib/features/ai_chat/presentation/ai_chat_screen.dart',
    'lib/features/premium/presentation/premium_screen.dart',
    'lib/features/support/presentation/support_screen.dart',
]

REQUIRED_TEXT = {
    'lib/features/ai_chat/domain/ai_usage_snapshot.dart': 'class AiUsageSnapshot',
    'lib/features/ai_chat/data/ai_usage_repository.dart': 'recordSuccessfulReply',
    'lib/features/ai_chat/presentation/widgets/ai_mode_clarity_card.dart': 'Current AI State',
    'lib/features/ai_chat/presentation/widgets/ai_usage_meter_card.dart': 'AI Usage Meter',
    'lib/features/ai_chat/presentation/widgets/emergency_fallback_card.dart': 'Emergency Fallback',
    'lib/features/ai_chat/presentation/ai_chat_screen.dart': 'AI usage meter reset.',
    'lib/features/premium/presentation/premium_screen.dart': 'whether AI is local, stubbed, or live prototype',
    'lib/features/support/presentation/support_screen.dart': 'leave chat and use human support instead',
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

    print('Breakout Addiction BA-31 AI clarity, usage meter, and emergency fallback verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
EOD

echo "==> BA-31 AI clarity, usage meter, and emergency fallback scaffold written."
echo "==> Running Python verification..."
python3 tools/verify_ba31.py
