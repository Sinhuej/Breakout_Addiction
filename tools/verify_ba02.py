from pathlib import Path
import sys

REQUIRED = [
    'lib/core/constants/route_names.dart',
    'lib/app/app_router.dart',
    'lib/features/cycle/domain/cycle_stage.dart',
    'lib/features/cycle/presentation/cycle_screen.dart',
    'lib/features/home/presentation/home_screen.dart',
]

REQUIRED_TEXT = {
    'lib/core/constants/route_names.dart': "static const cycle = '/cycle';",
    'lib/app/app_router.dart': 'case RouteNames.cycle:',
    'lib/features/cycle/domain/cycle_stage.dart': 'enum CycleStage',
    'lib/features/cycle/presentation/cycle_screen.dart': 'class CycleScreen extends StatelessWidget',
    'lib/features/home/presentation/home_screen.dart': 'Open Cycle Wheel',
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

    print('Breakout Addiction BA-02 cycle scaffold verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
