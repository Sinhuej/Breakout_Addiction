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
