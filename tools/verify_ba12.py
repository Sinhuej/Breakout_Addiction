from pathlib import Path
import sys

REQUIRED = [
    'lib/core/constants/route_names.dart',
    'lib/features/educate/domain/lesson.dart',
    'lib/features/educate/domain/lesson_track.dart',
    'lib/features/educate/data/lesson_repository.dart',
    'lib/features/educate/presentation/educate_screen.dart',
    'lib/features/educate/presentation/lesson_detail_screen.dart',
    'lib/app/app_router.dart',
]

REQUIRED_TEXT = {
    'lib/core/constants/route_names.dart': "static const educate = '/educate';",
    'lib/features/educate/domain/lesson.dart': 'class Lesson',
    'lib/features/educate/domain/lesson_track.dart': 'class LessonTrack',
    'lib/features/educate/data/lesson_repository.dart': 'class LessonRepository',
    'lib/features/educate/presentation/educate_screen.dart': 'Educate Me',
    'lib/features/educate/presentation/lesson_detail_screen.dart': 'Takeaway',
    'lib/app/app_router.dart': 'case RouteNames.educate:',
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

    print('Breakout Addiction BA-12 educate verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
