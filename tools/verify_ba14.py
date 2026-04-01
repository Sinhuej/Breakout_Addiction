from pathlib import Path
import sys

REQUIRED = [
    'lib/features/quotes/domain/daily_quote.dart',
    'lib/features/quotes/data/daily_quote_repository.dart',
    'lib/features/home/presentation/widgets/daily_quote_card.dart',
    'lib/features/support/presentation/support_screen.dart',
]

REQUIRED_TEXT = {
    'lib/features/quotes/domain/daily_quote.dart': 'final String? wisdomLine;',
    'lib/features/quotes/data/daily_quote_repository.dart': 'Mercy is not permission to quit trying.',
    'lib/features/home/presentation/widgets/daily_quote_card.dart': 'quote.wisdomLine',
    'lib/features/support/presentation/support_screen.dart': 'Choose the tone and faith layer you want on the Home screen.',
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

    print('Breakout Addiction BA-14 quote expansion verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
