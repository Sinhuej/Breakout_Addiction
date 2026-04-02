from pathlib import Path
import sys

REQUIRED = [
    'lib/features/ai_chat/domain/chat_provider_mode.dart',
    'lib/features/ai_chat/domain/ai_backend_config.dart',
    'lib/features/ai_chat/data/ai_backend_config_repository.dart',
    'lib/features/ai_chat/data/vertex_private_ready_provider.dart',
    'lib/features/ai_chat/data/chat_provider_factory.dart',
    'lib/features/premium/presentation/premium_screen.dart',
]

REQUIRED_TEXT = {
    'lib/features/ai_chat/domain/chat_provider_mode.dart': 'vertexPrivateReady',
    'lib/features/ai_chat/domain/ai_backend_config.dart': 'class AiBackendConfig',
    'lib/features/ai_chat/data/ai_backend_config_repository.dart': 'class AiBackendConfigRepository',
    'lib/features/ai_chat/data/vertex_private_ready_provider.dart': 'Vertex Private Ready mode is configured',
    'lib/features/ai_chat/data/chat_provider_factory.dart': 'case ChatProviderMode.vertexPrivateReady:',
    'lib/features/premium/presentation/premium_screen.dart': 'Paid Backend Readiness',
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

    print('Breakout Addiction BA-26 paid config verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
