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
