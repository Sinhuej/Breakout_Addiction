from pathlib import Path
import sys

REQUIRED = [
    'lib/features/qa/domain/demo_readiness_snapshot.dart',
    'lib/features/qa/data/demo_readiness_repository.dart',
    'lib/features/home/presentation/widgets/demo_readiness_card.dart',
    'lib/features/home/presentation/home_screen.dart',
    'lib/features/support/presentation/support_screen.dart',
    'test/widget_test.dart',
    'tools/run_demo_quality_checks.sh',
]

REQUIRED_TEXT = {
    'lib/features/qa/domain/demo_readiness_snapshot.dart': 'class DemoReadinessSnapshot',
    'lib/features/qa/data/demo_readiness_repository.dart': 'summaryLine = [',
    'lib/features/home/presentation/widgets/demo_readiness_card.dart': 'Demo Readiness',
    'lib/features/home/presentation/home_screen.dart': 'const DemoReadinessCard()',
    'lib/features/support/presentation/support_screen.dart': "label: 'Open AI Recovery Coach'",
    'test/widget_test.dart': 'BreakoutApp renders polished home shell',
    'tools/run_demo_quality_checks.sh': 'flutter analyze --no-fatal-infos',
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

    print('Breakout Addiction BA-34 demo cleanup and test tightening verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
