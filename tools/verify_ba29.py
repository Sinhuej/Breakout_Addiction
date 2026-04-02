from pathlib import Path
import sys

REQUIRED = [
    'lib/features/guidance/domain/local_guidance_snapshot.dart',
    'lib/features/guidance/data/local_guidance_repository.dart',
    'lib/features/guidance/data/local_guidance_service.dart',
    'lib/features/home/presentation/widgets/premium_guidance_card.dart',
    'lib/features/home/presentation/home_screen.dart',
    'lib/features/premium/presentation/premium_screen.dart',
    'lib/features/support/presentation/support_screen.dart',
]

REQUIRED_TEXT = {
    'lib/features/guidance/domain/local_guidance_snapshot.dart': 'class LocalGuidanceSnapshot',
    'lib/features/guidance/data/local_guidance_repository.dart': 'Grace is not gone because the day got hard.',
    'lib/features/guidance/data/local_guidance_service.dart': 'premium.hasPremium',
    'lib/features/home/presentation/widgets/premium_guidance_card.dart': 'Local Premium Guidance',
    'lib/features/home/presentation/home_screen.dart': 'const PremiumGuidanceCard()',
    'lib/features/premium/presentation/premium_screen.dart': 'Breakout Plus includes local premium guidance, deeper quotes, and faith-sensitive packs without AI chat.',
    'lib/features/support/presentation/support_screen.dart': 'Breakout Plus gives curated local guidance and faith-sensitive packs without AI chat.',
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

    print('Breakout Addiction BA-29 non-AI premium guidance verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
