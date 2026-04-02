#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

echo "==> Applying Breakout Addiction BA-23 AI chat shell scaffold in: $ROOT_DIR"

mkdir -p \
  lib/features/ai_chat/domain \
  lib/features/ai_chat/data \
  lib/features/ai_chat/presentation \
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
}
EOD

cat > lib/features/ai_chat/domain/chat_message.dart <<'EOD'
enum ChatRole {
  user,
  assistant,
}

class ChatMessage {
  final ChatRole role;
  final String text;
  final DateTime timestamp;

  const ChatMessage({
    required this.role,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'role': role.name,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      role: (map['role'] as String?) != null
          ? ChatRole.values.byName(map['role'] as String)
          : ChatRole.assistant,
      text: (map['text'] as String?) ?? '',
      timestamp: DateTime.tryParse((map['timestamp'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}
EOD

cat > lib/features/ai_chat/domain/chat_provider.dart <<'EOD'
import 'chat_message.dart';

abstract class ChatProvider {
  Future<ChatMessage> generateReply({
    required List<ChatMessage> messages,
    required String userInput,
  });
}
EOD

cat > lib/features/ai_chat/data/ai_chat_repository.dart <<'EOD'
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/chat_message.dart';

class AiChatRepository {
  static const String _storageKey = 'ai_chat_messages';

  Future<List<ChatMessage>> getMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return <ChatMessage>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (item) => ChatMessage.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<void> saveMessages(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(messages.map((item) => item.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> clearMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
EOD

cat > lib/features/ai_chat/data/mock_recovery_coach_provider.dart <<'EOD'
import '../domain/chat_message.dart';
import '../domain/chat_provider.dart';

class MockRecoveryCoachProvider implements ChatProvider {
  String _replyText(String input) {
    final text = input.toLowerCase();

    if (text.contains('suicide') ||
        text.contains('kill myself') ||
        text.contains('hurt myself') ||
        text.contains('self harm')) {
      return 'Prototype response: if you may be in immediate danger or might harm yourself, stop using chat and contact emergency help now. In the U.S., call or text 988 right away, or call emergency services if you are in immediate danger.';
    }

    if (text.contains('night') ||
        text.contains('late') ||
        text.contains('alone')) {
      return 'Prototype response: late-night isolation is a common setup pattern. Your next best move is to reduce privacy fast: change rooms, put the phone farther away, and switch to one simple grounding action.';
    }

    if (text.contains('stress') ||
        text.contains('overwhelmed') ||
        text.contains('anxious')) {
      return 'Prototype response: this sounds more like pressure than desire. Try naming the stressor directly, do one body-level reset, and avoid negotiating with the urge while your stress is high.';
    }

    if (text.contains('lonely') ||
        text.contains('isolated') ||
        text.contains('empty')) {
      return 'Prototype response: loneliness can make the ritual feel like relief. Your strongest move may be contact, not willpower. Consider texting someone, leaving the room, or doing something that breaks isolation quickly.';
    }

    if (text.contains('urge') ||
        text.contains('trigger') ||
        text.contains('slip')) {
      return 'Prototype response: catch the sequence early. Name where you are in the cycle, shorten the decision window, and make your next action physical and specific.';
    }

    return 'Prototype response: pause, name the pattern, and choose one small next step. The goal is not solving everything right now. The goal is interrupting the cycle earlier than usual.';
  }

  @override
  Future<ChatMessage> generateReply({
    required List<ChatMessage> messages,
    required String userInput,
  }) async {
    return ChatMessage(
      role: ChatRole.assistant,
      text: _replyText(userInput),
      timestamp: DateTime.now(),
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
import '../data/mock_recovery_coach_provider.dart';
import '../domain/chat_message.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final PremiumAccessRepository _premiumRepository = PremiumAccessRepository();
  final AiChatRepository _chatRepository = AiChatRepository();
  final MockRecoveryCoachProvider _provider = MockRecoveryCoachProvider();
  final TextEditingController _controller = TextEditingController();

  PremiumStatus _premiumStatus = PremiumStatus.defaults();
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
          'Prototype AI coach ready. This version is local-shell only with mock replies. Do not enter highly sensitive, identifying, or emergency information here yet.',
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

    final userMessage = ChatMessage(
      role: ChatRole.user,
      text: input,
      timestamp: DateTime.now(),
    );

    final updated = <ChatMessage>[..._messages, userMessage];

    setState(() {
      _sending = true;
      _messages = updated;
      _controller.clear();
    });

    await _chatRepository.saveMessages(updated);

    final reply = await _provider.generateReply(
      messages: updated,
      userInput: input,
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
        const InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Prototype guardrail', style: AppTypography.section),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Do not enter highly sensitive, identifying, or emergency information into prototype AI chat.',
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
              Text('What it will do', style: AppTypography.section),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Premium AI chat will help users reflect, interrupt patterns earlier, and use recovery tools more consistently.',
                style: AppTypography.muted,
              ),
              SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Open Premium',
                icon: Icons.workspace_premium_outlined,
                onPressed: null,
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
              const InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Prototype only', style: AppTypography.section),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'This AI coach currently uses mock replies and local saved chat history. Do not enter highly sensitive, identifying, or emergency information.',
                      style: AppTypography.muted,
                    ),
                  ],
                ),
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

python3 - <<'EOD'
from pathlib import Path

support_path = Path('lib/features/support/presentation/support_screen.dart')
support_text = support_path.read_text(encoding='utf-8')

marker = """          const SizedBox(height: AppSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Premium', style: AppTypography.section),
"""

insert = """          const SizedBox(height: AppSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Recovery Coach', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Premium prototype chat shell with local history and mock coaching replies. No cloud calls yet.',
                  style: AppTypography.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Open AI Coach',
                  icon: Icons.smart_toy_outlined,
                  onPressed: () => Navigator.pushNamed(
                    context,
                    RouteNames.aiChat,
                  ),
                ),
              ],
            ),
          ),
""" + marker

if "Text('AI Recovery Coach'" not in support_text:
    support_text = support_text.replace(marker, insert)

support_path.write_text(support_text, encoding='utf-8')
print('Patched support_screen.dart')
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

cat > tools/verify_ba23.py <<'EOD'
from pathlib import Path
import sys

REQUIRED = [
    'lib/core/constants/route_names.dart',
    'lib/features/ai_chat/domain/chat_message.dart',
    'lib/features/ai_chat/domain/chat_provider.dart',
    'lib/features/ai_chat/data/ai_chat_repository.dart',
    'lib/features/ai_chat/data/mock_recovery_coach_provider.dart',
    'lib/features/ai_chat/presentation/ai_chat_screen.dart',
    'lib/features/support/presentation/support_screen.dart',
    'lib/app/app_router.dart',
]

REQUIRED_TEXT = {
    'lib/core/constants/route_names.dart': "static const aiChat = '/ai-chat';",
    'lib/features/ai_chat/domain/chat_message.dart': 'class ChatMessage',
    'lib/features/ai_chat/domain/chat_provider.dart': 'abstract class ChatProvider',
    'lib/features/ai_chat/data/ai_chat_repository.dart': 'class AiChatRepository',
    'lib/features/ai_chat/data/mock_recovery_coach_provider.dart': 'Prototype response:',
    'lib/features/ai_chat/presentation/ai_chat_screen.dart': 'Prototype only',
    'lib/features/support/presentation/support_screen.dart': "Text('AI Recovery Coach'",
    'lib/app/app_router.dart': 'case RouteNames.aiChat:',
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

    print('Breakout Addiction BA-23 AI chat shell verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
EOD

echo "==> BA-23 AI chat shell scaffold written."
echo "==> Running Python verification..."
python3 tools/verify_ba23.py
