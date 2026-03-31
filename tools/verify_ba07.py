from pathlib import Path
import sys

REQUIRED = [
    'lib/features/quotes/domain/daily_quote.dart',
    'lib/features/quotes/data/quote_preferences_repository.dart',
    'lib/features/quotes/data/daily_quote_repository.dart',
    'lib/features/home/presentation/widgets/daily_quote_card.dart',
    'lib/features/support/presentation/support_screen.dart',
]

REQUIRED_TEXT = {
    'lib/features/quotes/domain/daily_quote.dart': 'enum QuoteMode',
    'lib/features/quotes/data/quote_preferences_repository.dart': 'class QuotePreferencesRepository',
    'lib/features/quotes/data/daily_quote_repository.dart': 'class DailyQuoteRepository',
    'lib/features/home/presentation/widgets/daily_quote_card.dart': 'DailyQuoteRepository',
    'lib/features/support/presentation/support_screen.dart': 'Daily Encouragement',
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

    print('Breakout Addiction BA-07 quotes scaffold verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
