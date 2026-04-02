from pathlib import Path
import sys

REQUIRED = [
    'lib/core/constants/route_names.dart',
    'lib/features/risk/domain/risk_window.dart',
    'lib/features/risk/domain/reminder_settings.dart',
    'lib/features/risk/data/risk_window_repository.dart',
    'lib/features/risk/presentation/risk_windows_screen.dart',
    'lib/features/support/presentation/support_screen.dart',
    'lib/app/app_router.dart',
]

REQUIRED_TEXT = {
    'lib/core/constants/route_names.dart': "static const riskWindows = '/risk-windows';",
    'lib/features/risk/domain/risk_window.dart': 'class RiskWindow',
    'lib/features/risk/domain/reminder_settings.dart': 'class ReminderSettings',
    'lib/features/risk/data/risk_window_repository.dart': 'class RiskWindowRepository',
    'lib/features/risk/presentation/risk_windows_screen.dart': 'Add Risk Window',
    'lib/features/support/presentation/support_screen.dart': 'Risk Windows & Reminders',
    'lib/app/app_router.dart': 'case RouteNames.riskWindows:',
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

    print('Breakout Addiction BA-15 risk windows verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
