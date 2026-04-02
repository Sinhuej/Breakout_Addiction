from pathlib import Path
import sys

REQUIRED = [
    'lib/features/widget/domain/app_entry_record.dart',
    'lib/features/widget/data/app_entry_repository.dart',
    'lib/features/home/presentation/widgets/entry_status_card.dart',
    'lib/features/widget/presentation/widget_preview_screen.dart',
    'lib/features/onboarding/presentation/home_entry_screen.dart',
    'lib/features/home/presentation/home_screen.dart',
    'lib/features/support/presentation/support_screen.dart',
]

REQUIRED_TEXT = {
    'lib/features/widget/domain/app_entry_record.dart': 'class AppEntryRecord',
    'lib/features/widget/data/app_entry_repository.dart': 'stageWidgetEntry',
    'lib/features/home/presentation/widgets/entry_status_card.dart': 'Recent App Entry',
    'lib/features/widget/presentation/widget_preview_screen.dart': 'Simulate Widget → Rescue',
    'lib/features/onboarding/presentation/home_entry_screen.dart': 'consumePendingEntry',
    'lib/features/home/presentation/home_screen.dart': 'const EntryStatusCard()',
    'lib/features/support/presentation/support_screen.dart': "label: 'Open Widget Preview'",
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

    print('Breakout Addiction BA-33 widget/app-entry polish verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
