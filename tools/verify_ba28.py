from pathlib import Path
import sys

REQUIRED = [
    'lib/core/constants/route_names.dart',
    'lib/features/premium/domain/premium_plan.dart',
    'lib/features/premium/domain/premium_status.dart',
    'lib/features/premium/data/premium_access_repository.dart',
    'lib/features/settings/domain/feature_control_settings.dart',
    'lib/features/settings/data/feature_control_settings_repository.dart',
    'lib/features/settings/presentation/feature_controls_screen.dart',
    'lib/features/home/presentation/widgets/startup_notice_sheet.dart',
    'lib/features/home/presentation/home_screen.dart',
    'lib/features/ai_chat/presentation/ai_chat_screen.dart',
    'lib/features/premium/presentation/premium_screen.dart',
    'lib/features/support/presentation/support_screen.dart',
    'lib/app/app_router.dart',
]

REQUIRED_TEXT = {
    'lib/core/constants/route_names.dart': "static const featureControls = '/feature-controls';",
    'lib/features/premium/domain/premium_plan.dart': 'Breakout Plus AI',
    'lib/features/premium/domain/premium_status.dart': 'bool get hasAiPremium',
    'lib/features/premium/data/premium_access_repository.dart': 'setPlan(PremiumPlan plan)',
    'lib/features/settings/domain/feature_control_settings.dart': 'showStartupNotice',
    'lib/features/settings/data/feature_control_settings_repository.dart': 'feature_remote_ai_enabled',
    'lib/features/settings/presentation/feature_controls_screen.dart': 'Choose your comfort level.',
    'lib/features/home/presentation/widgets/startup_notice_sheet.dart': 'Welcome to Breakout',
    'lib/features/home/presentation/home_screen.dart': '_startupNoticeHandledThisSession',
    'lib/features/ai_chat/presentation/ai_chat_screen.dart': 'Breakout Plus AI is part of',
    'lib/features/premium/presentation/premium_screen.dart': 'Premium Plan',
    'lib/features/support/presentation/support_screen.dart': 'Feature Choices',
    'lib/app/app_router.dart': 'case RouteNames.featureControls:',
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

    print('Breakout Addiction BA-28 notice, tiers, and controls verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
