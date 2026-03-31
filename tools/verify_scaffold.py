from pathlib import Path
import sys

REQUIRED = [
    'pubspec.yaml',
    'analysis_options.yaml',
    'lib/main.dart',
    'lib/app/breakout_app.dart',
    'lib/app/app_router.dart',
    'lib/app/theme/app_colors.dart',
    'lib/app/theme/app_theme.dart',
    'lib/core/constants/route_names.dart',
    'lib/core/widgets/info_card.dart',
    'lib/core/widgets/primary_button.dart',
    'lib/features/home/presentation/home_screen.dart',
    'lib/features/rescue/presentation/rescue_screen.dart',
    'lib/features/log/presentation/log_hub_screen.dart',
    'lib/features/insights/presentation/insights_screen.dart',
    'lib/features/support/presentation/support_screen.dart',
    'lib/features/privacy/domain/lock_scope.dart',
    'lib/features/privacy/domain/lock_settings.dart',
    'lib/features/privacy/presentation/lock_gate_screen.dart',
]

def main() -> int:
    root = Path.cwd()
    missing = [path for path in REQUIRED if not (root / path).exists()]
    if missing:
        print('Missing files:')
        for item in missing:
            print(f' - {item}')
        return 1

    print('Breakout Addiction BA-01 scaffold verification passed.')
    print(f'Checked {len(REQUIRED)} required files.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
