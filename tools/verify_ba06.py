from pathlib import Path
import sys

REQUIRED = [
    'lib/core/constants/route_names.dart',
    'lib/features/log/domain/mood_entry.dart',
    'lib/features/log/data/mood_log_repository.dart',
    'lib/features/log/presentation/mood_log_screen.dart',
    'lib/features/home/presentation/widgets/risk_status_card.dart',
    'lib/app/app_router.dart',
    'lib/features/home/presentation/widgets/quick_actions_row.dart',
    'lib/features/log/presentation/log_hub_screen.dart',
]

REQUIRED_TEXT = {
    'lib/core/constants/route_names.dart': "static const moodLog = '/log/mood';",
    'lib/features/log/domain/mood_entry.dart': 'class MoodEntry',
    'lib/features/log/data/mood_log_repository.dart': 'class MoodLogRepository',
    'lib/features/log/presentation/mood_log_screen.dart': 'class MoodLogScreen extends StatefulWidget',
    'lib/features/home/presentation/widgets/risk_status_card.dart': 'MoodLogRepository',
    'lib/app/app_router.dart': 'case RouteNames.moodLog:',
    'lib/features/home/presentation/widgets/quick_actions_row.dart': 'RouteNames.moodLog',
    'lib/features/log/presentation/log_hub_screen.dart': "label: 'Log Mood'",
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

    print('Breakout Addiction BA-06 mood scaffold verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
