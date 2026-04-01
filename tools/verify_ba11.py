from pathlib import Path
import sys

REQUIRED = [
    'lib/features/insights/domain/insight_summary.dart',
    'lib/features/insights/data/insights_repository.dart',
    'lib/features/insights/presentation/insights_screen.dart',
]

REQUIRED_TEXT = {
    'lib/features/insights/domain/insight_summary.dart': 'class InsightSummary',
    'lib/features/insights/data/insights_repository.dart': 'class InsightsRepository',
    'lib/features/insights/presentation/insights_screen.dart': 'Recent Risk Summary',
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

    print('Breakout Addiction BA-11 insights verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
