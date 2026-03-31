#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

echo "==> Applying Breakout Addiction BA-05 privacy scaffold in: $ROOT_DIR"

mkdir -p \
  lib/features/privacy/data \
  lib/features/privacy/presentation \
  tools

cat > pubspec.yaml <<'EOD'
name: breakout_addiction
description: Android-first recovery app for compulsive pornography use.
publish_to: "none"

version: 0.1.0+1

environment:
  sdk: ">=3.3.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.2.3
  flutter_secure_storage: ^9.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
EOD

cat > lib/core/constants/route_names.dart <<'EOD'
class RouteNames {
  static const home = '/';
  static const rescue = '/rescue';
  static const logHub = '/log';
  static const cycleStageLog = '/log/cycle-stage';
  static const insights = '/insights';
  static const support = '/support';
  static const cycle = '/cycle';
  static const privacySettings = '/privacy';
}
EOD

cat > lib/features/privacy/domain/lock_scope.dart <<'EOD'
enum LockScope {
  app,
  logs,
  cycle,
  support,
  insights,
}
EOD

cat > lib/features/privacy/domain/lock_settings.dart <<'EOD'
import 'lock_scope.dart';

class LockSettings {
  final bool isEnabled;
  final Set<LockScope> enabledScopes;
  final bool allowRescueWithoutUnlock;
  final bool useBiometrics;
  final bool hasPasscode;
  final bool neutralPrivacyMode;

  const LockSettings({
    required this.isEnabled,
    required this.enabledScopes,
    required this.allowRescueWithoutUnlock,
    required this.useBiometrics,
    required this.hasPasscode,
    required this.neutralPrivacyMode,
  });

  factory LockSettings.disabled() {
    return const LockSettings(
      isEnabled: false,
      enabledScopes: <LockScope>{},
      allowRescueWithoutUnlock: true,
      useBiometrics: false,
      hasPasscode: false,
      neutralPrivacyMode: true,
    );
  }

  LockSettings copyWith({
    bool? isEnabled,
    Set<LockScope>? enabledScopes,
    bool? allowRescueWithoutUnlock,
    bool? useBiometrics,
    bool? hasPasscode,
    bool? neutralPrivacyMode,
  }) {
    return LockSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      enabledScopes: enabledScopes ?? this.enabledScopes,
      allowRescueWithoutUnlock:
          allowRescueWithoutUnlock ?? this.allowRescueWithoutUnlock,
      useBiometrics: useBiometrics ?? this.useBiometrics,
      hasPasscode: hasPasscode ?? this.hasPasscode,
      neutralPrivacyMode: neutralPrivacyMode ?? this.neutralPrivacyMode,
    );
  }

  bool shouldLock(LockScope scope) {
    return isEnabled &&
        (enabledScopes.contains(LockScope.app) || enabledScopes.contains(scope));
  }
}
EOD

cat > lib/features/privacy/data/lock_settings_repository.dart <<'EOD'
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/lock_scope.dart';
import '../domain/lock_settings.dart';

class LockSettingsRepository {
  static const String _enabledKey = 'privacy_enabled';
  static const String _scopesKey = 'privacy_scopes';
  static const String _rescueBypassKey = 'privacy_rescue_bypass';
  static const String _biometricKey = 'privacy_biometrics';
  static const String _neutralModeKey = 'privacy_neutral_mode';
  static const String _passcodeKey = 'privacy_passcode';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<LockSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final scopeNames = prefs.getStringList(_scopesKey) ?? <String>[];
    final hasPasscode = await _secureStorage.read(key: _passcodeKey) != null;

    return LockSettings(
      isEnabled: prefs.getBool(_enabledKey) ?? false,
      enabledScopes: scopeNames
          .map((name) => LockScope.values.byName(name))
          .toSet(),
      allowRescueWithoutUnlock: prefs.getBool(_rescueBypassKey) ?? true,
      useBiometrics: prefs.getBool(_biometricKey) ?? false,
      hasPasscode: hasPasscode,
      neutralPrivacyMode: prefs.getBool(_neutralModeKey) ?? true,
    );
  }

  Future<void> saveSettings(LockSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, settings.isEnabled);
    await prefs.setStringList(
      _scopesKey,
      settings.enabledScopes.map((scope) => scope.name).toList(),
    );
    await prefs.setBool(_rescueBypassKey, settings.allowRescueWithoutUnlock);
    await prefs.setBool(_biometricKey, settings.useBiometrics);
    await prefs.setBool(_neutralModeKey, settings.neutralPrivacyMode);
  }

  Future<void> savePasscode(String passcode) async {
    await _secureStorage.write(key: _passcodeKey, value: passcode);
  }

  Future<bool> verifyPasscode(String passcode) async {
    final saved = await _secureStorage.read(key: _passcodeKey);
    return saved != null && saved == passcode;
  }

  Future<void> clearPasscode() async {
    await _secureStorage.delete(key: _passcodeKey);
  }
}
EOD
cat > lib/features/privacy/presentation/lock_gate_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';

class LockGateScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final Future<bool> Function(String passcode) onUnlockAttempt;
  final VoidCallback onUnlockSuccess;

  const LockGateScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onUnlockAttempt,
    required this.onUnlockSuccess,
  });

  @override
  State<LockGateScreen> createState() => _LockGateScreenState();
}

class _LockGateScreenState extends State<LockGateScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isBusy = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    setState(() {
      _isBusy = true;
      _errorText = null;
    });

    final ok = await widget.onUnlockAttempt(_controller.text.trim());

    if (!mounted) {
      return;
    }

    setState(() => _isBusy = false);

    if (ok) {
      widget.onUnlockSuccess();
      return;
    }

    setState(() => _errorText = 'That code does not match.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Protected')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: InfoCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: AppTypography.title),
                  const SizedBox(height: AppSpacing.sm),
                  Text(widget.subtitle, style: AppTypography.muted),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _controller,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Passcode',
                      border: const OutlineInputBorder(),
                      errorText: _errorText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    label: _isBusy ? 'Unlocking...' : 'Unlock',
                    icon: Icons.lock_open,
                    onPressed: _isBusy ? () {} : _unlock,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
EOD

cat > lib/features/privacy/presentation/protected_route_gate.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../data/lock_settings_repository.dart';
import '../domain/lock_scope.dart';
import '../domain/lock_settings.dart';
import 'lock_gate_screen.dart';

class ProtectedRouteGate extends StatefulWidget {
  final LockScope scope;
  final Widget child;
  final bool isRescueRoute;

  const ProtectedRouteGate({
    super.key,
    required this.scope,
    required this.child,
    this.isRescueRoute = false,
  });

  @override
  State<ProtectedRouteGate> createState() => _ProtectedRouteGateState();
}

class _ProtectedRouteGateState extends State<ProtectedRouteGate> {
  final LockSettingsRepository _repository = LockSettingsRepository();

  LockSettings? _settings;
  bool _loading = true;
  bool _sessionUnlocked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _repository.getSettings();
    if (!mounted) {
      return;
    }
    setState(() {
      _settings = settings;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _settings == null) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final settings = _settings!;

    final rescueBypass = widget.isRescueRoute && settings.allowRescueWithoutUnlock;
    final shouldLock = settings.shouldLock(widget.scope);

    if (_sessionUnlocked || rescueBypass || !shouldLock || !settings.hasPasscode) {
      return widget.child;
    }

    return LockGateScreen(
      title: 'Protected Content',
      subtitle: 'Unlock to continue.',
      onUnlockAttempt: _repository.verifyPasscode,
      onUnlockSuccess: () {
        setState(() => _sessionUnlocked = true);
      },
    );
  }
}
EOD

cat > lib/features/privacy/presentation/privacy_settings_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/lock_settings_repository.dart';
import '../domain/lock_scope.dart';
import '../domain/lock_settings.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final LockSettingsRepository _repository = LockSettingsRepository();

  LockSettings _settings = LockSettings.disabled();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = await _repository.getSettings();
    if (!mounted) {
      return;
    }
    setState(() {
      _settings = loaded;
      _loading = false;
    });
  }

  Future<void> _saveSettings(LockSettings updated) async {
    await _repository.saveSettings(updated);
    if (!mounted) {
      return;
    }
    setState(() => _settings = updated);
  }

  Set<LockScope> _toggleScope(Set<LockScope> scopes, LockScope scope, bool enabled) {
    final next = <LockScope>{...scopes};
    if (enabled) {
      next.add(scope);
    } else {
      next.remove(scope);
    }
    return next;
  }

  Future<void> _showPasscodeSheet() async {
    final controller = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Set Passcode', style: AppTypography.title),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Choose a simple 4-digit or longer passcode.',
                style: AppTypography.muted,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Passcode',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Save Passcode',
                icon: Icons.lock_outline,
                onPressed: () async {
                  final value = controller.text.trim();
                  if (value.length < 4) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Use at least 4 digits or characters.')),
                    );
                    return;
                  }

                  await _repository.savePasscode(value);
                  if (!mounted) {
                    return;
                  }

                  await _saveSettings(_settings.copyWith(hasPasscode: true));
                  if (!mounted) {
                    return;
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Passcode saved.')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _removePasscode() async {
    await _repository.clearPasscode();
    final cleared = _settings.copyWith(
      hasPasscode: false,
      isEnabled: false,
      enabledScopes: <LockScope>{},
    );
    await _saveSettings(cleared);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Passcode removed and locks disabled.')),
    );
  }

  Widget _buildScopeTile({
    required String title,
    required String subtitle,
    required LockScope scope,
  }) {
    final enabled = _settings.enabledScopes.contains(scope);

    return SwitchListTile(
      value: enabled,
      onChanged: !_settings.hasPasscode
          ? null
          : (value) => _saveSettings(
                _settings.copyWith(
                  enabledScopes: _toggleScope(_settings.enabledScopes, scope, value),
                ),
              ),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        appBar: AppBar(title: Text('Privacy Lock Mode')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Lock Mode')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Layered Privacy', style: AppTypography.section),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Choose whether to lock the whole app or only the private areas.',
                  style: AppTypography.muted,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Passcode', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _settings.hasPasscode
                      ? 'A passcode is currently set.'
                      : 'No passcode set yet.',
                  style: AppTypography.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: _settings.hasPasscode ? 'Update Passcode' : 'Set Passcode',
                  icon: Icons.password_outlined,
                  onPressed: _showPasscodeSheet,
                ),
                if (_settings.hasPasscode) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _removePasscode,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove Passcode'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lock Master Switch', style: AppTypography.section),
                SwitchListTile(
                  value: _settings.isEnabled,
                  onChanged: !_settings.hasPasscode
                      ? null
                      : (value) => _saveSettings(
                            _settings.copyWith(isEnabled: value),
                          ),
                  title: const Text('Enable Privacy Lock'),
                  subtitle: Text(
                    _settings.hasPasscode
                        ? 'Turn lock protection on or off.'
                        : 'Set a passcode first to enable lock protection.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Protected Areas', style: AppTypography.section),
                _buildScopeTile(
                  title: 'Lock Entire App',
                  subtitle: 'Require unlock across the whole app.',
                  scope: LockScope.app,
                ),
                _buildScopeTile(
                  title: 'Lock Private Logs',
                  subtitle: 'Protect stage logs and future journal entries.',
                  scope: LockScope.logs,
                ),
                _buildScopeTile(
                  title: 'Lock Cycle / History',
                  subtitle: 'Protect the recovery cycle area.',
                  scope: LockScope.cycle,
                ),
                _buildScopeTile(
                  title: 'Lock Insights',
                  subtitle: 'Protect pattern and analytics screens.',
                  scope: LockScope.insights,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Privacy Options', style: AppTypography.section),
                SwitchListTile(
                  value: _settings.allowRescueWithoutUnlock,
                  onChanged: (value) => _saveSettings(
                    _settings.copyWith(allowRescueWithoutUnlock: value),
                  ),
                  title: const Text('Allow Rescue Without Unlock'),
                  subtitle: const Text('Keep fast access to support during an urge.'),
                ),
                SwitchListTile(
                  value: _settings.neutralPrivacyMode,
                  onChanged: (value) => _saveSettings(
                    _settings.copyWith(neutralPrivacyMode: value),
                  ),
                  title: const Text('Neutral Privacy Mode'),
                  subtitle: const Text('Use discreet wording for sensitive areas later.'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
EOD
cat > lib/app/app_router.dart <<'EOD'
import 'package:flutter/material.dart';

import '../core/constants/route_names.dart';
import '../features/cycle/domain/cycle_stage.dart';
import '../features/cycle/presentation/cycle_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/insights/presentation/insights_screen.dart';
import '../features/log/presentation/cycle_stage_log_screen.dart';
import '../features/log/presentation/log_hub_screen.dart';
import '../features/privacy/domain/lock_scope.dart';
import '../features/privacy/presentation/privacy_settings_screen.dart';
import '../features/privacy/presentation/protected_route_gate.dart';
import '../features/rescue/presentation/rescue_screen.dart';
import '../features/support/presentation/support_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.home:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.app,
            child: HomeScreen(),
          ),
        );
      case RouteNames.rescue:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.app,
            isRescueRoute: true,
            child: RescueScreen(),
          ),
        );
      case RouteNames.cycle:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.cycle,
            child: CycleScreen(),
          ),
        );
      case RouteNames.logHub:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.logs,
            child: LogHubScreen(),
          ),
        );
      case RouteNames.cycleStageLog:
        final stage = settings.arguments is CycleStage
            ? settings.arguments as CycleStage
            : CycleStage.triggers;
        return MaterialPageRoute(
          builder: (_) => ProtectedRouteGate(
            scope: LockScope.logs,
            child: CycleStageLogScreen(initialStage: stage),
          ),
        );
      case RouteNames.insights:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.insights,
            child: InsightsScreen(),
          ),
        );
      case RouteNames.support:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.support,
            child: SupportScreen(),
          ),
        );
      case RouteNames.privacySettings:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.app,
            child: PrivacySettingsScreen(),
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.app,
            child: HomeScreen(),
          ),
        );
    }
  }
}
EOD

cat > lib/features/support/presentation/support_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Emergency Help', style: AppTypography.section),
                SizedBox(height: AppSpacing.sm),
                Text(
                  '988, trusted contacts, and recovery plan shortcuts will live here.',
                  style: AppTypography.muted,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Privacy & Lock Mode', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Control who can open the app or view private areas like logs and cycle history.',
                  style: AppTypography.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Open Privacy Settings',
                  icon: Icons.lock_outline,
                  onPressed: () => Navigator.pushNamed(
                    context,
                    RouteNames.privacySettings,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, RouteNames.home);
              break;
            case 1:
              Navigator.pushReplacementNamed(context, RouteNames.rescue);
              break;
            case 2:
              Navigator.pushReplacementNamed(context, RouteNames.logHub);
              break;
            case 3:
              Navigator.pushReplacementNamed(context, RouteNames.insights);
              break;
            case 4:
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.flash_on_outlined), label: 'Rescue'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_note_outlined), label: 'Log'),
          BottomNavigationBarItem(icon: Icon(Icons.insights_outlined), label: 'Insights'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent_outlined), label: 'Support'),
        ],
      ),
    );
  }
}
EOD

cat > tools/verify_ba05.py <<'EOD'
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
EOD

echo "==> BA-05 privacy scaffold written."
echo "==> Running Python verification..."
python3 tools/verify_ba05.py
