from pathlib import Path
import sys

REQUIRED = [
    'pubspec.yaml',
    'lib/features/notifications/data/breakout_notification_service.dart',
    'lib/features/notifications/data/risk_window_reminder_sync_service.dart',
    'lib/features/risk/presentation/risk_windows_screen.dart',
    'lib/main.dart',
    'lib/features/support/presentation/support_screen.dart',
]

REQUIRED_TEXT = {
    'pubspec.yaml': 'flutter_local_notifications: ^21.0.0',
    'lib/features/notifications/data/breakout_notification_service.dart': 'scheduleDailyReminder',
    'lib/features/notifications/data/risk_window_reminder_sync_service.dart': 'RiskWindowReminderSyncResult',
    'lib/features/risk/presentation/risk_windows_screen.dart': 'Sync Live Reminders',
    'lib/main.dart': 'await BreakoutNotificationService.instance.initialize();',
    'lib/features/support/presentation/support_screen.dart': "label: 'Open Risk Windows'",
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

    print('Breakout Addiction BA-32 live reminders verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
