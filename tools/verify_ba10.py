from pathlib import Path
import sys

REQUIRED = [
    'lib/core/constants/route_names.dart',
    'lib/features/onboarding/domain/onboarding_state.dart',
    'lib/features/onboarding/data/onboarding_repository.dart',
    'lib/features/onboarding/presentation/home_entry_screen.dart',
    'lib/features/onboarding/presentation/onboarding_screen.dart',
    'lib/app/app_router.dart',
]

REQUIRED_TEXT = {
    'lib/core/constants/route_names.dart': "static const onboarding = '/onboarding';",
    'lib/features/onboarding/domain/onboarding_state.dart': 'class OnboardingState',
    'lib/features/onboarding/data/onboarding_repository.dart': 'class OnboardingRepository',
    'lib/features/onboarding/presentation/home_entry_screen.dart': 'class HomeEntryScreen extends StatelessWidget',
    'lib/features/onboarding/presentation/onboarding_screen.dart': 'Step ${_stepIndex + 1} of 6',
    'lib/app/app_router.dart': 'case RouteNames.onboarding:',
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

    print('Breakout Addiction BA-10 onboarding verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
