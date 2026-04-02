from pathlib import Path
import sys

REQUIRED = [
    'lib/features/privacy/domain/privacy_status_snapshot.dart',
    'lib/features/privacy/data/lock_settings_repository.dart',
    'lib/features/privacy/presentation/widgets/privacy_status_card.dart',
    'lib/features/privacy/presentation/widgets/neutral_mode_preview_card.dart',
    'lib/features/privacy/presentation/privacy_settings_screen.dart',
]

REQUIRED_TEXT = {
    'lib/features/privacy/domain/privacy_status_snapshot.dart': 'class PrivacyStatusSnapshot',
    'lib/features/privacy/data/lock_settings_repository.dart': 'Future<void> resetToSafeDefaults() async {',
    'lib/features/privacy/presentation/widgets/privacy_status_card.dart': 'Privacy Status',
    'lib/features/privacy/presentation/widgets/neutral_mode_preview_card.dart': 'Neutral Label Preview',
    'lib/features/privacy/presentation/privacy_settings_screen.dart': 'Reset Privacy Defaults',
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

    print('Breakout Addiction BA-20 privacy polish verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
