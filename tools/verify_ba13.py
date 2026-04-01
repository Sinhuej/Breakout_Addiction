from pathlib import Path
import sys

REQUIRED = [
    'lib/features/rescue/data/reasons_to_stop_repository.dart',
    'lib/features/rescue/presentation/widgets/breathing_card.dart',
    'lib/features/rescue/presentation/widgets/reasons_to_stop_card.dart',
    'lib/features/rescue/presentation/widgets/delay_actions_card.dart',
    'lib/features/rescue/presentation/widgets/stage_aware_suggestion_card.dart',
    'lib/features/rescue/presentation/rescue_screen.dart',
]

REQUIRED_TEXT = {
    'lib/features/rescue/data/reasons_to_stop_repository.dart': 'class ReasonsToStopRepository',
    'lib/features/rescue/presentation/widgets/breathing_card.dart': 'Breathe With Me',
    'lib/features/rescue/presentation/widgets/reasons_to_stop_card.dart': 'Reasons to Stop',
    'lib/features/rescue/presentation/widgets/delay_actions_card.dart': 'Delay Actions',
    'lib/features/rescue/presentation/widgets/stage_aware_suggestion_card.dart': 'Stage-Aware Suggestion',
    'lib/features/rescue/presentation/rescue_screen.dart': 'const StageAwareSuggestionCard()',
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

    print('Breakout Addiction BA-13 rescue verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
