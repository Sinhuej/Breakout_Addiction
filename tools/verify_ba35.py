from pathlib import Path
import sys

REQUIRED = [
    'lib/features/about/domain/demo_showcase_item.dart',
    'lib/features/about/data/demo_showcase_repository.dart',
    'lib/features/about/presentation/about_breakout_screen.dart',
    'lib/core/constants/route_names.dart',
    'lib/app/app_router.dart',
    'lib/features/home/presentation/home_screen.dart',
    'lib/features/support/presentation/support_screen.dart',
    'docs/DEMO_HANDOFF.md',
    'tools/run_final_demo_readiness.sh',
]

REQUIRED_TEXT = {
    'lib/features/about/domain/demo_showcase_item.dart': 'class DemoShowcaseItem',
    'lib/features/about/data/demo_showcase_repository.dart': 'Breakout Plus Without AI',
    'lib/features/about/presentation/about_breakout_screen.dart': 'What Breakout is built to do.',
    'lib/core/constants/route_names.dart': "static const aboutBreakout = '/about-breakout';",
    'lib/app/app_router.dart': 'case RouteNames.aboutBreakout:',
    'lib/features/home/presentation/home_screen.dart': "label: const Text('About Breakout')",
    'lib/features/support/presentation/support_screen.dart': "label: 'About Breakout'",
    'docs/DEMO_HANDOFF.md': 'Suggested Sparkles demo script',
    'tools/run_final_demo_readiness.sh': 'Breakout final demo readiness',
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

    print('Breakout Addiction BA-35 finish pass verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
