from pathlib import Path
import sys

REQUIRED = [
    'lib/core/constants/route_names.dart',
    'lib/app/app_router.dart',
    'lib/features/log/domain/cycle_stage_log_entry.dart',
    'lib/features/log/presentation/cycle_stage_log_screen.dart',
    'lib/features/log/presentation/log_hub_screen.dart',
    'lib/features/cycle/presentation/cycle_screen.dart',
]

REQUIRED_TEXT = {
    'lib/core/constants/route_names.dart': "static const cycleStageLog = '/log/cycle-stage';",
    'lib/app/app_router.dart': 'case RouteNames.cycleStageLog:',
    'lib/features/log/domain/cycle_stage_log_entry.dart': 'class CycleStageLogEntry',
    'lib/features/log/presentation/cycle_stage_log_screen.dart': 'class CycleStageLogScreen extends StatefulWidget',
    'lib/features/log/presentation/log_hub_screen.dart': 'Log Cycle Stage',
    'lib/features/cycle/presentation/cycle_screen.dart': 'RouteNames.cycleStageLog',
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

    print('Breakout Addiction BA-03 logging scaffold verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
