from pathlib import Path
import sys

REQUIRED = [
    'lib/app/theme/app_theme.dart',
    'lib/features/home/presentation/widgets/home_hero_card.dart',
    'lib/features/home/presentation/widgets/progress_snapshot_card.dart',
    'lib/features/home/presentation/widgets/quick_actions_row.dart',
    'lib/features/home/presentation/home_screen.dart',
]

REQUIRED_TEXT = {
    'lib/app/theme/app_theme.dart': 'filledButtonTheme',
    'lib/features/home/presentation/widgets/home_hero_card.dart': 'Open Cycle Wheel',
    'lib/features/home/presentation/widgets/progress_snapshot_card.dart': 'Progress Snapshot',
    'lib/features/home/presentation/widgets/quick_actions_row.dart': 'Quick Actions',
    'lib/features/home/presentation/home_screen.dart': 'const HomeHeroCard()',
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

    print('Breakout Addiction BA-22 UI polish verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
