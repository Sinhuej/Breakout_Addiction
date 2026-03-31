from pathlib import Path
import sys

REQUIRED = [
    'lib/core/privacy/neutral_labels.dart',
    'lib/features/widget/domain/widget_entry_action.dart',
    'lib/features/widget/domain/widget_display_mode.dart',
    'lib/features/privacy/data/privacy_label_repository.dart',
    'lib/features/home/presentation/widgets/quick_actions_row.dart',
    'lib/features/home/presentation/widgets/risk_status_card.dart',
    'lib/features/home/presentation/home_screen.dart',
]

REQUIRED_TEXT = {
    'lib/core/privacy/neutral_labels.dart': 'class NeutralLabels',
    'lib/features/widget/domain/widget_entry_action.dart': 'enum WidgetEntryAction',
    'lib/features/widget/domain/widget_display_mode.dart': 'enum WidgetDisplayMode',
    'lib/features/privacy/data/privacy_label_repository.dart': 'class PrivacyLabelRepository',
    'lib/features/home/presentation/widgets/quick_actions_row.dart': 'NeutralLabels.rescuePrimary',
    'lib/features/home/presentation/widgets/risk_status_card.dart': 'NeutralLabels.riskCardAction',
    'lib/features/home/presentation/home_screen.dart': 'NeutralLabels.cycleWheelTitle',
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

    print('Breakout Addiction BA-09 widget prep verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
