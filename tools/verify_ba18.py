from pathlib import Path
import sys

REQUIRED = [
    'lib/core/constants/route_names.dart',
    'lib/features/log/domain/recovery_event_entry.dart',
    'lib/features/log/data/recovery_event_repository.dart',
    'lib/features/log/presentation/recovery_event_log_screen.dart',
    'lib/features/log/presentation/log_hub_screen.dart',
    'lib/app/app_router.dart',
]

REQUIRED_TEXT = {
    'lib/core/constants/route_names.dart': "static const recoveryEventLog = '/log/recovery-event';",
    'lib/features/log/domain/recovery_event_entry.dart': 'enum RecoveryEventType',
    'lib/features/log/data/recovery_event_repository.dart': 'class RecoveryEventRepository',
    'lib/features/log/presentation/recovery_event_log_screen.dart': 'Save Recovery Event',
    'lib/features/log/presentation/log_hub_screen.dart': 'Log Urge / Relapse / Victory',
    'lib/app/app_router.dart': 'case RouteNames.recoveryEventLog:',
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

    print('Breakout Addiction BA-18 logs expansion verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
