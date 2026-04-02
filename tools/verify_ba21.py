from pathlib import Path
import sys

REQUIRED = [
    'lib/core/constants/route_names.dart',
    'lib/features/premium/domain/premium_status.dart',
    'lib/features/premium/data/premium_access_repository.dart',
    'lib/features/premium/presentation/widgets/premium_badge.dart',
    'lib/features/premium/presentation/premium_screen.dart',
    'lib/features/educate/presentation/educate_screen.dart',
    'lib/features/support/presentation/support_screen.dart',
    'lib/app/app_router.dart',
]

REQUIRED_TEXT = {
    'lib/core/constants/route_names.dart': "static const premium = '/premium';",
    'lib/features/premium/domain/premium_status.dart': 'class PremiumStatus',
    'lib/features/premium/data/premium_access_repository.dart': 'class PremiumAccessRepository',
    'lib/features/premium/presentation/widgets/premium_badge.dart': 'class PremiumBadge',
    'lib/features/premium/presentation/premium_screen.dart': 'Local Demo Unlock',
    'lib/features/educate/presentation/educate_screen.dart': 'Educate Me Plus',
    'lib/features/support/presentation/support_screen.dart': "Text('Premium'",
    'lib/app/app_router.dart': 'case RouteNames.premium:',
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

    print('Breakout Addiction BA-21 premium hooks verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
