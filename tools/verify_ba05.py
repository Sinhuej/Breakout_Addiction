from pathlib import Path
import sys

REQUIRED = [
    'pubspec.yaml',
    'lib/core/constants/route_names.dart',
    'lib/features/privacy/domain/lock_settings.dart',
    'lib/features/privacy/data/lock_settings_repository.dart',
    'lib/features/privacy/presentation/lock_gate_screen.dart',
    'lib/features/privacy/presentation/protected_route_gate.dart',
    'lib/features/privacy/presentation/privacy_settings_screen.dart',
    'lib/app/app_router.dart',
    'lib/features/support/presentation/support_screen.dart',
]

REQUIRED_TEXT = {
    'pubspec.yaml': 'flutter_secure_storage:',
    'lib/core/constants/route_names.dart': "static const privacySettings = '/privacy';",
    'lib/features/privacy/domain/lock_settings.dart': 'enabledScopes.contains(LockScope.app)',
    'lib/features/privacy/data/lock_settings_repository.dart': 'class LockSettingsRepository',
    'lib/features/privacy/presentation/lock_gate_screen.dart': 'Future<bool> Function(String passcode)',
    'lib/features/privacy/presentation/protected_route_gate.dart': 'class ProtectedRouteGate extends StatefulWidget',
    'lib/features/privacy/presentation/privacy_settings_screen.dart': 'class PrivacySettingsScreen extends StatefulWidget',
    'lib/app/app_router.dart': 'RouteNames.privacySettings',
    'lib/features/support/presentation/support_screen.dart': 'Open Privacy Settings',
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

    print('Breakout Addiction BA-05 privacy scaffold verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
