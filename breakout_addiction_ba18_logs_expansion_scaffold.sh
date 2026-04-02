#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

echo "==> Applying Breakout Addiction BA-18 logs expansion scaffold in: $ROOT_DIR"

mkdir -p \
  lib/features/log/domain \
  lib/features/log/data \
  lib/features/log/presentation \
  tools

cat > lib/core/constants/route_names.dart <<'EOD'
class RouteNames {
  static const home = '/';
  static const onboarding = '/onboarding';
  static const rescue = '/rescue';
  static const logHub = '/log';
  static const moodLog = '/log/mood';
  static const cycleStageLog = '/log/cycle-stage';
  static const recoveryEventLog = '/log/recovery-event';
  static const insights = '/insights';
  static const educate = '/educate';
  static const educateLesson = '/educate/lesson';
  static const support = '/support';
  static const riskWindows = '/risk-windows';
  static const recoveryPlan = '/recovery-plan';
  static const widgetPreview = '/widget-preview';
  static const cycle = '/cycle';
  static const privacySettings = '/privacy';
}
EOD

cat > lib/features/log/domain/recovery_event_entry.dart <<'EOD'
enum RecoveryEventType {
  urge,
  relapse,
  victory,
}

extension RecoveryEventTypeX on RecoveryEventType {
  String get label {
    switch (this) {
      case RecoveryEventType.urge:
        return 'Urge';
      case RecoveryEventType.relapse:
        return 'Relapse';
      case RecoveryEventType.victory:
        return 'Victory';
    }
  }
}

class RecoveryEventEntry {
  final DateTime timestamp;
  final RecoveryEventType type;
  final int intensity;
  final String context;
  final String note;

  const RecoveryEventEntry({
    required this.timestamp,
    required this.type,
    required this.intensity,
    required this.context,
    required this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'intensity': intensity,
      'context': context,
      'note': note,
    };
  }

  factory RecoveryEventEntry.fromMap(Map<String, dynamic> map) {
    return RecoveryEventEntry(
      timestamp: DateTime.tryParse((map['timestamp'] as String?) ?? '') ??
          DateTime.now(),
      type: (map['type'] as String?) != null
          ? RecoveryEventType.values.byName(map['type'] as String)
          : RecoveryEventType.urge,
      intensity: (map['intensity'] as num?)?.toInt() ?? 5,
      context: (map['context'] as String?) ?? '',
      note: (map['note'] as String?) ?? '',
    );
  }
}
EOD

cat > lib/features/log/data/recovery_event_repository.dart <<'EOD'
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/recovery_event_entry.dart';

class RecoveryEventRepository {
  static const String _storageKey = 'recovery_event_logs';

  Future<List<RecoveryEventEntry>> getEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return <RecoveryEventEntry>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (item) => RecoveryEventEntry.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> saveEntry(RecoveryEventEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getEntries();
    final updated = <RecoveryEventEntry>[entry, ...existing];
    final encoded = jsonEncode(updated.map((item) => item.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
EOD
cat > lib/features/log/presentation/recovery_event_log_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/recovery_event_repository.dart';
import '../domain/recovery_event_entry.dart';

class RecoveryEventLogScreen extends StatefulWidget {
  const RecoveryEventLogScreen({super.key});

  @override
  State<RecoveryEventLogScreen> createState() => _RecoveryEventLogScreenState();
}

class _RecoveryEventLogScreenState extends State<RecoveryEventLogScreen> {
  final RecoveryEventRepository _repository = RecoveryEventRepository();
  final TextEditingController _contextController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  RecoveryEventType _type = RecoveryEventType.urge;
  double _intensity = 5;
  bool _saving = false;

  @override
  void dispose() {
    _contextController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final entry = RecoveryEventEntry(
      timestamp: DateTime.now(),
      type: _type,
      intensity: _intensity.round(),
      context: _contextController.text.trim(),
      note: _noteController.text.trim(),
    );

    await _repository.saveEntry(entry);

    if (!mounted) {
      return;
    }

    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved ${entry.type.label.toLowerCase()} log.')),
    );

    Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.logHub,
      (route) => route.settings.name == RouteNames.home || route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recovery Event Log')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Capture the moment honestly.', style: AppTypography.title),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Urges, slips, and wins all teach you something if you name them clearly.',
              style: AppTypography.muted,
            ),
            const SizedBox(height: AppSpacing.lg),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Event Type', style: AppTypography.section),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<RecoveryEventType>(
                    initialValue: _type,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: RecoveryEventType.values
                        .map(
                          (item) => DropdownMenuItem<RecoveryEventType>(
                            value: item,
                            child: Text(item.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _type = value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Intensity', style: AppTypography.section),
                  const SizedBox(height: AppSpacing.sm),
                  Text('${_intensity.round()} / 10', style: AppTypography.body),
                  Slider(
                    value: _intensity,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: _intensity.round().toString(),
                    onChanged: (value) {
                      setState(() => _intensity = value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Context', style: AppTypography.section),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _contextController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Example: alone late at night, stressed after work, bored on couch...',
                      border: OutlineInputBorder(),
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
                  Text('Notes', style: AppTypography.section),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _noteController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'What happened? What did you notice? What helped or failed?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: _saving ? 'Saving...' : 'Save Recovery Event',
              icon: Icons.save_outlined,
              onPressed: _saving ? () {} : _save,
            ),
          ],
        ),
      ),
    );
  }
}
EOD

cat > lib/features/log/presentation/log_hub_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../cycle/domain/cycle_stage.dart';
import '../data/cycle_stage_log_repository.dart';
import '../data/recovery_event_repository.dart';
import '../domain/cycle_stage_log_entry.dart';
import '../domain/recovery_event_entry.dart';

class LogHubScreen extends StatelessWidget {
  const LogHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stageRepository = CycleStageLogRepository();
    final eventRepository = RecoveryEventRepository();

    return Scaffold(
      appBar: AppBar(title: const Text('Log')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Private Logs', style: AppTypography.section),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Use different log types to understand mood, cycle stage, urges, slips, and wins more clearly.',
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
                Text('Quick Log Actions', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                PrimaryButton(
                  label: 'Log Cycle Stage',
                  icon: Icons.add_chart_outlined,
                  onPressed: () => Navigator.pushNamed(
                    context,
                    RouteNames.cycleStageLog,
                    arguments: CycleStage.triggers,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      RouteNames.moodLog,
                    ),
                    icon: const Icon(Icons.mood_outlined),
                    label: const Text('Log Mood'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      RouteNames.recoveryEventLog,
                    ),
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text('Log Urge / Relapse / Victory'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FutureBuilder<List<CycleStageLogEntry>>(
            future: stageRepository.getEntries(),
            builder: (context, snapshot) {
              final entries = snapshot.data ?? <CycleStageLogEntry>[];

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const InfoCard(
                  child: Text('Loading recent stage logs...', style: AppTypography.muted),
                );
              }

              if (entries.isEmpty) {
                return const InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recent Stage Logs', style: AppTypography.section),
                      SizedBox(height: AppSpacing.sm),
                      Text('No saved stage logs yet.', style: AppTypography.muted),
                    ],
                  ),
                );
              }

              return InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent Stage Logs', style: AppTypography.section),
                    const SizedBox(height: AppSpacing.sm),
                    for (final entry in entries.take(4)) ...[
                      _StageRow(entry: entry),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          FutureBuilder<List<RecoveryEventEntry>>(
            future: eventRepository.getEntries(),
            builder: (context, snapshot) {
              final entries = snapshot.data ?? <RecoveryEventEntry>[];

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const InfoCard(
                  child: Text('Loading recent recovery events...', style: AppTypography.muted),
                );
              }

              if (entries.isEmpty) {
                return const InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recent Recovery Events', style: AppTypography.section),
                      SizedBox(height: AppSpacing.sm),
                      Text('No urge, relapse, or victory logs yet.', style: AppTypography.muted),
                    ],
                  ),
                );
              }

              return InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent Recovery Events', style: AppTypography.section),
                    const SizedBox(height: AppSpacing.sm),
                    for (final entry in entries.take(5)) ...[
                      _RecoveryEventRow(entry: entry),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, RouteNames.home);
              break;
            case 1:
              Navigator.pushReplacementNamed(context, RouteNames.rescue);
              break;
            case 2:
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

class _StageRow extends StatelessWidget {
  final CycleStageLogEntry entry;

  const _StageRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final note = entry.note.isEmpty ? 'No note added.' : entry.note;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF263041)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.stage.title, style: AppTypography.section),
          const SizedBox(height: 4),
          Text('Intensity: ${entry.intensity}/10', style: AppTypography.muted),
          const SizedBox(height: 4),
          Text(note, style: AppTypography.body),
        ],
      ),
    );
  }
}

class _RecoveryEventRow extends StatelessWidget {
  final RecoveryEventEntry entry;

  const _RecoveryEventRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final contextLine = entry.context.isEmpty ? 'No context added.' : entry.context;
    final noteLine = entry.note.isEmpty ? 'No note added.' : entry.note;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF263041)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.type.label, style: AppTypography.section),
          const SizedBox(height: 4),
          Text('Intensity: ${entry.intensity}/10', style: AppTypography.muted),
          const SizedBox(height: 4),
          Text(contextLine, style: AppTypography.body),
          const SizedBox(height: 4),
          Text(noteLine, style: AppTypography.muted),
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
import '../features/educate/presentation/educate_screen.dart';
import '../features/insights/presentation/insights_screen.dart';
import '../features/log/presentation/cycle_stage_log_screen.dart';
import '../features/log/presentation/log_hub_screen.dart';
import '../features/log/presentation/mood_log_screen.dart';
import '../features/log/presentation/recovery_event_log_screen.dart';
import '../features/onboarding/presentation/home_entry_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/privacy/domain/lock_scope.dart';
import '../features/privacy/presentation/privacy_settings_screen.dart';
import '../features/privacy/presentation/protected_route_gate.dart';
import '../features/rescue/presentation/rescue_screen.dart';
import '../features/risk/presentation/risk_windows_screen.dart';
import '../features/support/presentation/recovery_plan_screen.dart';
import '../features/support/presentation/support_screen.dart';
import '../features/widget/presentation/widget_preview_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.home:
        return MaterialPageRoute(
          builder: (_) => const HomeEntryScreen(),
        );
      case RouteNames.onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
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
      case RouteNames.moodLog:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.logs,
            child: MoodLogScreen(),
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
      case RouteNames.recoveryEventLog:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.logs,
            child: RecoveryEventLogScreen(),
          ),
        );
      case RouteNames.insights:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.insights,
            child: InsightsScreen(),
          ),
        );
      case RouteNames.educate:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.app,
            child: EducateScreen(),
          ),
        );
      case RouteNames.riskWindows:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.support,
            child: RiskWindowsScreen(),
          ),
        );
      case RouteNames.recoveryPlan:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.support,
            child: RecoveryPlanScreen(),
          ),
        );
      case RouteNames.widgetPreview:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.support,
            child: WidgetPreviewScreen(),
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
          builder: (_) => const HomeEntryScreen(),
        );
    }
  }
}
EOD

cat > tools/verify_ba18.py <<'EOD'
from pathlib import Path
import sys

REQUIRED = [
    'lib/core/constants/route_names.dart',
    'lib/features/log/domain/recovery_event_entry.dart',
    'lib/features/log/data/recovery_event_repository.dart',
    'lib/features/log/presentation/recovery_event_log_screen.dart',
    'lib/features/log/presentation/log_hub_screen.dart',
    'lib/app/app_router.dart',
]

REQUIRED_TEXT = {
    'lib/core/constants/route_names.dart': "static const recoveryEventLog = '/log/recovery-event';",
    'lib/features/log/domain/recovery_event_entry.dart': 'enum RecoveryEventType',
    'lib/features/log/data/recovery_event_repository.dart': 'class RecoveryEventRepository',
    'lib/features/log/presentation/recovery_event_log_screen.dart': 'Save Recovery Event',
    'lib/features/log/presentation/log_hub_screen.dart': 'Log Urge / Relapse / Victory',
    'lib/app/app_router.dart': 'case RouteNames.recoveryEventLog:',
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

    print('Breakout Addiction BA-18 logs expansion verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
EOD

echo "==> BA-18 logs expansion scaffold written."
echo "==> Running Python verification..."
python3 tools/verify_ba18.py
