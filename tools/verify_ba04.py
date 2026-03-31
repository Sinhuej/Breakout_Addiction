from pathlib import Path
import sys

REQUIRED = [
    'pubspec.yaml',
    'lib/features/log/domain/cycle_stage_log_entry.dart',
    'lib/features/log/data/cycle_stage_log_repository.dart',
    'lib/features/log/presentation/cycle_stage_log_screen.dart',
    'lib/features/log/presentation/log_hub_screen.dart',
]

REQUIRED_TEXT = {
    'pubspec.yaml': 'shared_preferences:',
    'lib/features/log/domain/cycle_stage_log_entry.dart': 'factory CycleStageLogEntry.fromMap',
    'lib/features/log/data/cycle_stage_log_repository.dart': 'class CycleStageLogRepository',
    'lib/features/log/presentation/cycle_stage_log_screen.dart': 'await _repository.saveEntry(entry);',
    'lib/features/log/presentation/log_hub_screen.dart': 'FutureBuilder<List<CycleStageLogEntry>>',
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

    print('Breakout Addiction BA-04 persistence scaffold verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
