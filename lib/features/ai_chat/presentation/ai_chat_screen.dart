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
        ? 'Breakout Plus AI is part of the optional AI layer, not Breakout Plus.'
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
