from pathlib import Path
import sys

REQUIRED = [
    'lib/features/ai_chat/domain/chat_provider_mode.dart',
    'lib/features/ai_chat/domain/ai_chat_settings.dart',
    'lib/features/ai_chat/data/ai_chat_settings_repository.dart',
    'lib/features/ai_chat/data/gemini_prototype_provider.dart',
    'lib/features/ai_chat/data/chat_provider_factory.dart',
    'lib/features/ai_chat/presentation/ai_chat_screen.dart',
    'lib/features/premium/presentation/premium_screen.dart',
]

REQUIRED_TEXT = {
    'lib/features/ai_chat/domain/chat_provider_mode.dart': 'enum ChatProviderMode',
    'lib/features/ai_chat/domain/ai_chat_settings.dart': 'class AiChatSettings',
    'lib/features/ai_chat/data/ai_chat_settings_repository.dart': 'class AiChatSettingsRepository',
    'lib/features/ai_chat/data/gemini_prototype_provider.dart': 'Gemini prototype mode is not wired',
    'lib/features/ai_chat/data/chat_provider_factory.dart': 'class ChatProviderFactory',
    'lib/features/ai_chat/presentation/ai_chat_screen.dart': 'Current Provider',
    'lib/features/premium/presentation/premium_screen.dart': 'AI Chat Provider Mode',
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

    print('Breakout Addiction BA-24 AI provider abstraction verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
