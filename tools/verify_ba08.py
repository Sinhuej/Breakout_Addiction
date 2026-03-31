from pathlib import Path
import sys

REQUIRED = [
    'pubspec.yaml',
    'lib/features/support/domain/support_contact.dart',
    'lib/features/support/data/support_contact_repository.dart',
    'lib/features/support/presentation/support_screen.dart',
]

REQUIRED_TEXT = {
    'pubspec.yaml': 'url_launcher:',
    'lib/features/support/domain/support_contact.dart': 'class SupportContact',
    'lib/features/support/data/support_contact_repository.dart': 'class SupportContactRepository',
    'lib/features/support/presentation/support_screen.dart': 'Call 988',
    'lib/features/support/presentation/support_screen.dart::__trusted': 'Trusted Contact',
    'lib/features/support/presentation/support_screen.dart::__text': 'Text 988',
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

    for key, needle in REQUIRED_TEXT.items():
        path = key.split('::__')[0]
        text = (root / path).read_text(encoding='utf-8')
        if needle not in text:
            bad.append((path, needle))

    if bad:
        print('Content checks failed:')
        for path, needle in bad:
            print(f' - {path} missing: {needle}')
        return 1

    print('Breakout Addiction BA-08 support scaffold verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
