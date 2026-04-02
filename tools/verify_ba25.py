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
