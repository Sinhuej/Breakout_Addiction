from pathlib import Path
import sys

REQUIRED = [
    'lib/core/constants/route_names.dart',
    'lib/features/widget/domain/widget_snapshot.dart',
    'lib/features/widget/data/widget_snapshot_repository.dart',
    'lib/features/widget/presentation/widget_preview_screen.dart',
    'lib/features/support/presentation/support_screen.dart',
    'lib/app/app_router.dart',
    'android_widget_overlay/README_WIDGET_SETUP.md',
    'android_widget_overlay/app/src/main/res/layout/breakout_widget_compact.xml',
    'android_widget_overlay/app/src/main/res/xml/breakout_widget_info.xml',
    'android_widget_overlay/app/src/main/kotlin/com/example/breakout_addiction/BreakoutWidgetProvider.kt',
]

REQUIRED_TEXT = {
    'lib/core/constants/route_names.dart': "static const widgetPreview = '/widget-preview';",
    'lib/features/widget/domain/widget_snapshot.dart': 'class WidgetSnapshot',
    'lib/features/widget/data/widget_snapshot_repository.dart': 'class WidgetSnapshotRepository',
    'lib/features/widget/presentation/widget_preview_screen.dart': 'Widget Preview',
    'lib/features/support/presentation/support_screen.dart': 'Home Screen Widget',
    'lib/app/app_router.dart': 'case RouteNames.widgetPreview:',
    'android_widget_overlay/README_WIDGET_SETUP.md': 'Android Widget Overlay',
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

    print('Breakout Addiction BA-17 widget implementation verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
