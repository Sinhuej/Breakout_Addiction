#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

echo "==> Applying Breakout Addiction BA-15 risk windows scaffold in: $ROOT_DIR"

mkdir -p \
  lib/features/risk/domain \
  lib/features/risk/data \
  lib/features/risk/presentation \
  tools

cat > lib/core/constants/route_names.dart <<'EOD'
class RouteNames {
  static const home = '/';
  static const onboarding = '/onboarding';
  static const rescue = '/rescue';
  static const logHub = '/log';
  static const moodLog = '/log/mood';
  static const cycleStageLog = '/log/cycle-stage';
  static const insights = '/insights';
  static const educate = '/educate';
  static const educateLesson = '/educate/lesson';
  static const support = '/support';
  static const riskWindows = '/risk-windows';
  static const cycle = '/cycle';
  static const privacySettings = '/privacy';
}
EOD

cat > lib/features/risk/domain/risk_window.dart <<'EOD'
class RiskWindow {
  final String id;
  final String label;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final bool isEnabled;

  const RiskWindow({
    required this.id,
    required this.label,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.isEnabled,
  });

  RiskWindow copyWith({
    String? id,
    String? label,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    bool? isEnabled,
  }) {
    return RiskWindow(
      id: id ?? this.id,
      label: label ?? this.label,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'isEnabled': isEnabled,
    };
  }

  factory RiskWindow.fromMap(Map<String, dynamic> map) {
    return RiskWindow(
      id: (map['id'] as String?) ?? '',
      label: (map['label'] as String?) ?? 'Risk Window',
      startHour: (map['startHour'] as num?)?.toInt() ?? 22,
      startMinute: (map['startMinute'] as num?)?.toInt() ?? 0,
      endHour: (map['endHour'] as num?)?.toInt() ?? 23,
      endMinute: (map['endMinute'] as num?)?.toInt() ?? 0,
      isEnabled: (map['isEnabled'] as bool?) ?? true,
    );
  }

  String get timeRange {
    return '${_fmt(startHour)}:${_fmt(startMinute)} - ${_fmt(endHour)}:${_fmt(endMinute)}';
  }

  static String _fmt(int value) => value.toString().padLeft(2, '0');
}
EOD

cat > lib/features/risk/domain/reminder_settings.dart <<'EOD'
class ReminderSettings {
  final bool remindersEnabled;
  final int leadMinutes;

  const ReminderSettings({
    required this.remindersEnabled,
    required this.leadMinutes,
  });

  factory ReminderSettings.defaults() {
    return const ReminderSettings(
      remindersEnabled: true,
      leadMinutes: 10,
    );
  }

  ReminderSettings copyWith({
    bool? remindersEnabled,
    int? leadMinutes,
  }) {
    return ReminderSettings(
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      leadMinutes: leadMinutes ?? this.leadMinutes,
    );
  }
}
EOD

cat > lib/features/risk/data/risk_window_repository.dart <<'EOD'
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/reminder_settings.dart';
import '../domain/risk_window.dart';

class RiskWindowRepository {
  static const String _riskWindowsKey = 'risk_windows';
  static const String _remindersEnabledKey = 'risk_window_reminders_enabled';
  static const String _leadMinutesKey = 'risk_window_lead_minutes';

  Future<List<RiskWindow>> getRiskWindows() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_riskWindowsKey);
    if (raw == null || raw.isEmpty) {
      return <RiskWindow>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => RiskWindow.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> saveRiskWindows(List<RiskWindow> windows) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(windows.map((item) => item.toMap()).toList());
    await prefs.setString(_riskWindowsKey, encoded);
  }

  Future<void> upsertRiskWindow(RiskWindow window) async {
    final existing = await getRiskWindows();
    final index = existing.indexWhere((item) => item.id == window.id);

    if (index >= 0) {
      existing[index] = window;
    } else {
      existing.add(window);
    }

    await saveRiskWindows(existing);
  }

  Future<void> deleteRiskWindow(String id) async {
    final existing = await getRiskWindows();
    existing.removeWhere((item) => item.id == id);
    await saveRiskWindows(existing);
  }

  Future<ReminderSettings> getReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return ReminderSettings(
      remindersEnabled: prefs.getBool(_remindersEnabledKey) ?? true,
      leadMinutes: prefs.getInt(_leadMinutesKey) ?? 10,
    );
  }

  Future<void> saveReminderSettings(ReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_remindersEnabledKey, settings.remindersEnabled);
    await prefs.setInt(_leadMinutesKey, settings.leadMinutes);
  }
}
EOD
cat > lib/features/risk/presentation/risk_windows_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/risk_window_repository.dart';
import '../domain/reminder_settings.dart';
import '../domain/risk_window.dart';

class RiskWindowsScreen extends StatefulWidget {
  const RiskWindowsScreen({super.key});

  @override
  State<RiskWindowsScreen> createState() => _RiskWindowsScreenState();
}

class _RiskWindowsScreenState extends State<RiskWindowsScreen> {
  final RiskWindowRepository _repository = RiskWindowRepository();

  List<RiskWindow> _windows = <RiskWindow>[];
  ReminderSettings _settings = ReminderSettings.defaults();
  bool _loading = true;

  static const List<int> _minuteOptions = <int>[0, 15, 30, 45];
  static const List<int> _leadOptions = <int>[5, 10, 15, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final windows = await _repository.getRiskWindows();
    final settings = await _repository.getReminderSettings();

    if (!mounted) {
      return;
    }

    setState(() {
      _windows = windows;
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _saveSettings(ReminderSettings settings) async {
    await _repository.saveReminderSettings(settings);
    if (!mounted) {
      return;
    }
    setState(() => _settings = settings);
  }

  Future<void> _deleteWindow(String id) async {
    await _repository.deleteRiskWindow(id);
    await _load();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Risk window removed.')),
    );
  }

  Future<void> _showWindowSheet({RiskWindow? existing}) async {
    final labelController = TextEditingController(
      text: existing?.label ?? '',
    );

    int startHour = existing?.startHour ?? 22;
    int startMinute = existing?.startMinute ?? 0;
    int endHour = existing?.endHour ?? 23;
    int endMinute = existing?.endMinute ?? 0;
    bool enabled = existing?.isEnabled ?? true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existing == null ? 'Add Risk Window' : 'Edit Risk Window',
                    style: AppTypography.title,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: labelController,
                    decoration: const InputDecoration(
                      labelText: 'Label',
                      hintText: 'Example: Late Night',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: startHour,
                          decoration: const InputDecoration(
                            labelText: 'Start Hour',
                            border: OutlineInputBorder(),
                          ),
                          items: List.generate(
                            24,
                            (index) => DropdownMenuItem<int>(
                              value: index,
                              child: Text(index.toString().padLeft(2, '0')),
                            ),
                          ),
                          onChanged: (value) {
                            if (value == null) return;
                            setSheetState(() => startHour = value);
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: startMinute,
                          decoration: const InputDecoration(
                            labelText: 'Start Min',
                            border: OutlineInputBorder(),
                          ),
                          items: _minuteOptions
                              .map(
                                (value) => DropdownMenuItem<int>(
                                  value: value,
                                  child: Text(value.toString().padLeft(2, '0')),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setSheetState(() => startMinute = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: endHour,
                          decoration: const InputDecoration(
                            labelText: 'End Hour',
                            border: OutlineInputBorder(),
                          ),
                          items: List.generate(
                            24,
                            (index) => DropdownMenuItem<int>(
                              value: index,
                              child: Text(index.toString().padLeft(2, '0')),
                            ),
                          ),
                          onChanged: (value) {
                            if (value == null) return;
                            setSheetState(() => endHour = value);
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: endMinute,
                          decoration: const InputDecoration(
                            labelText: 'End Min',
                            border: OutlineInputBorder(),
                          ),
                          items: _minuteOptions
                              .map(
                                (value) => DropdownMenuItem<int>(
                                  value: value,
                                  child: Text(value.toString().padLeft(2, '0')),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setSheetState(() => endMinute = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: enabled,
                    onChanged: (value) => setSheetState(() => enabled = value),
                    title: const Text('Enabled'),
                    subtitle: const Text('Use this window for proactive reminders later.'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    label: existing == null ? 'Save Risk Window' : 'Update Risk Window',
                    icon: Icons.schedule_outlined,
                    onPressed: () async {
                      final label = labelController.text.trim();
                      if (label.isEmpty) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          const SnackBar(content: Text('Add a label for this risk window.')),
                        );
                        return;
                      }

                      final window = RiskWindow(
                        id: existing?.id ??
                            DateTime.now().microsecondsSinceEpoch.toString(),
                        label: label,
                        startHour: startHour,
                        startMinute: startMinute,
                        endHour: endHour,
                        endMinute: endMinute,
                        isEnabled: enabled,
                      );

                      await _repository.upsertRiskWindow(window);
                      if (!mounted) {
                        return;
                      }

                      await _load();
                      if (!mounted || !sheetContext.mounted) {
                        return;
                      }

                      Navigator.of(sheetContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(existing == null
                              ? 'Risk window saved.'
                              : 'Risk window updated.'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _windowCard(RiskWindow window) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(window.label, style: AppTypography.section),
          const SizedBox(height: AppSpacing.sm),
          Text(window.timeRange, style: AppTypography.body),
          const SizedBox(height: 6),
          Text(
            window.isEnabled ? 'Enabled' : 'Disabled',
            style: AppTypography.muted,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showWindowSheet(existing: window),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deleteWindow(window.id),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Risk Windows')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Risk Windows')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Get ahead of the risky moments.', style: AppTypography.title),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Define the times when you are more vulnerable so the app can become more proactive.',
            style: AppTypography.muted,
          ),
          const SizedBox(height: AppSpacing.lg),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reminder Settings', style: AppTypography.section),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _settings.remindersEnabled,
                  onChanged: (value) {
                    _saveSettings(
                      _settings.copyWith(remindersEnabled: value),
                    );
                  },
                  title: const Text('Enable Reminder Prep'),
                  subtitle: const Text(
                    'Stores your preference now so notification wiring can be added cleanly later.',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<int>(
                  initialValue: _settings.leadMinutes,
                  decoration: const InputDecoration(
                    labelText: 'Lead Time',
                    border: OutlineInputBorder(),
                  ),
                  items: _leadOptions
                      .map(
                        (value) => DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value minutes before'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    _saveSettings(
                      _settings.copyWith(leadMinutes: value),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Add Risk Window',
            icon: Icons.add_alert_outlined,
            onPressed: () => _showWindowSheet(),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_windows.isEmpty)
            const InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No Risk Windows Yet', style: AppTypography.section),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Add a few recurring high-risk times like late night, after work, or weekends.',
                    style: AppTypography.muted,
                  ),
                ],
              ),
            )
          else
            for (final window in _windows) ...[
              _windowCard(window),
              const SizedBox(height: AppSpacing.md),
            ],
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
              Navigator.pushReplacementNamed(context, RouteNames.educate);
              break;
            case 4:
              Navigator.pushReplacementNamed(context, RouteNames.support);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.flash_on_outlined), label: 'Rescue'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_note_outlined), label: 'Log'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: 'Learn'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent_outlined), label: 'Support'),
        ],
      ),
    );
  }
}
EOD
python3 - <<'EOD'
from pathlib import Path

support_path = Path('lib/features/support/presentation/support_screen.dart')
support_text = support_path.read_text(encoding='utf-8')

insert_after = """          const SizedBox(height: AppSpacing.md),
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
"""

replacement = """          const SizedBox(height: AppSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Risk Windows & Reminders', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Define high-risk time windows and reminder lead times so the app can become more proactive.',
                  style: AppTypography.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Open Risk Windows',
                  icon: Icons.schedule_outlined,
                  onPressed: () => Navigator.pushNamed(
                    context,
                    RouteNames.riskWindows,
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
"""

if "Text('Risk Windows & Reminders'" not in support_text:
    support_text = support_text.replace(insert_after, replacement)

support_path.write_text(support_text, encoding='utf-8')
print('Patched support_screen.dart')

router_path = Path('lib/app/app_router.dart')
router_text = router_path.read_text(encoding='utf-8')

if "import '../features/risk/presentation/risk_windows_screen.dart';" not in router_text:
    router_text = router_text.replace(
        "import '../features/rescue/presentation/rescue_screen.dart';\n",
        "import '../features/rescue/presentation/rescue_screen.dart';\nimport '../features/risk/presentation/risk_windows_screen.dart';\n",
    )

if "case RouteNames.riskWindows:" not in router_text:
    router_text = router_text.replace(
        "      case RouteNames.support:\n",
        "      case RouteNames.riskWindows:\n"
        "        return MaterialPageRoute(\n"
        "          builder: (_) => const ProtectedRouteGate(\n"
        "            scope: LockScope.support,\n"
        "            child: RiskWindowsScreen(),\n"
        "          ),\n"
        "        );\n"
        "      case RouteNames.support:\n",
    )

router_path.write_text(router_text, encoding='utf-8')
print('Patched app_router.dart')
EOD

cat > tools/verify_ba15.py <<'EOD'
from pathlib import Path
import sys

REQUIRED = [
    'lib/core/constants/route_names.dart',
    'lib/features/risk/domain/risk_window.dart',
    'lib/features/risk/domain/reminder_settings.dart',
    'lib/features/risk/data/risk_window_repository.dart',
    'lib/features/risk/presentation/risk_windows_screen.dart',
    'lib/features/support/presentation/support_screen.dart',
    'lib/app/app_router.dart',
]

REQUIRED_TEXT = {
    'lib/core/constants/route_names.dart': "static const riskWindows = '/risk-windows';",
    'lib/features/risk/domain/risk_window.dart': 'class RiskWindow',
    'lib/features/risk/domain/reminder_settings.dart': 'class ReminderSettings',
    'lib/features/risk/data/risk_window_repository.dart': 'class RiskWindowRepository',
    'lib/features/risk/presentation/risk_windows_screen.dart': 'Add Risk Window',
    'lib/features/support/presentation/support_screen.dart': 'Risk Windows & Reminders',
    'lib/app/app_router.dart': 'case RouteNames.riskWindows:',
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

    print('Breakout Addiction BA-15 risk windows verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
EOD

echo "==> BA-15 risk windows scaffold written."
echo "==> Running Python verification..."
python3 tools/verify_ba15.py
