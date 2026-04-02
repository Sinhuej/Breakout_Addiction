from pathlib import Path
import sys

REQUIRED = [
    'pubspec.yaml',
    'lib/features/ai_chat/data/ai_backend_config_repository.dart',
    'lib/features/ai_chat/data/gemini_http_transport.dart',
    'lib/features/ai_chat/data/gemini_prototype_provider.dart',
    'lib/features/ai_chat/data/chat_provider_factory.dart',
    'lib/features/ai_chat/data/ai_backend_preflight_service.dart',
    'lib/features/ai_chat/presentation/ai_chat_screen.dart',
    'lib/features/premium/presentation/premium_screen.dart',
]

REQUIRED_TEXT = {
    'pubspec.yaml': 'http: ^1.2.2',
    'lib/features/ai_chat/data/ai_backend_config_repository.dart': 'Future<String?> getApiKey() async',
    'lib/features/ai_chat/data/gemini_http_transport.dart': 'x-goog-api-key',
    'lib/features/ai_chat/data/gemini_prototype_provider.dart': 'live prototype path is not armed yet',
    'lib/features/ai_chat/data/chat_provider_factory.dart': 'transport: GeminiHttpTransport()',
    'lib/features/ai_chat/data/ai_backend_preflight_service.dart': 'Gemini prototype remote path is armed.',
    'lib/features/ai_chat/presentation/ai_chat_screen.dart': 'this mode can send a real prototype cloud request',
    'lib/features/premium/presentation/premium_screen.dart': 'Gemini Prototype can make a real cloud prototype call',
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

    print('Breakout Addiction BA-30 Gemini prototype transport verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
