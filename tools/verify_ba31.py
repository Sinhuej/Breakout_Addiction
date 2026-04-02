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
