from pathlib import Path
import sys

REQUIRED = [
    'lib/core/constants/route_names.dart',
    'lib/features/support/domain/recovery_plan.dart',
    'lib/features/support/data/recovery_plan_repository.dart',
    'lib/features/support/presentation/recovery_plan_screen.dart',
    'lib/features/support/presentation/support_screen.dart',
    'lib/app/app_router.dart',
]

REQUIRED_TEXT = {
    'lib/core/constants/route_names.dart': "static const recoveryPlan = '/recovery-plan';",
    'lib/features/support/domain/recovery_plan.dart': 'class RecoveryPlan',
    'lib/features/support/data/recovery_plan_repository.dart': 'class RecoveryPlanRepository',
    'lib/features/support/presentation/recovery_plan_screen.dart': 'Save Recovery Plan',
    'lib/features/support/presentation/support_screen.dart': 'Personal Recovery Plan',
    'lib/app/app_router.dart': 'case RouteNames.recoveryPlan:',
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

    print('Breakout Addiction BA-16 recovery plan verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
