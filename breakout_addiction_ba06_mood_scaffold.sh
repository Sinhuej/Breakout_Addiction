#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

echo "==> Applying Breakout Addiction BA-06 mood scaffold in: $ROOT_DIR"

mkdir -p \
  lib/features/log/domain \
  lib/features/log/data \
  lib/features/log/presentation \
  tools

cat > lib/core/constants/route_names.dart <<'EOD'
class RouteNames {
  static const home = '/';
  static const rescue = '/rescue';
  static const logHub = '/log';
  static const moodLog = '/log/mood';
  static const cycleStageLog = '/log/cycle-stage';
  static const insights = '/insights';
  static const support = '/support';
  static const cycle = '/cycle';
  static const privacySettings = '/privacy';
}
EOD

cat > lib/features/log/domain/mood_entry.dart <<'EOD'
class MoodEntry {
  final DateTime timestamp;
  final String moodLabel;
  final int stress;
  final int loneliness;
  final int boredom;
  final int energy;
  final String note;

  const MoodEntry({
    required this.timestamp,
    required this.moodLabel,
    required this.stress,
    required this.loneliness,
    required this.boredom,
    required this.energy,
    required this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'moodLabel': moodLabel,
      'stress': stress,
      'loneliness': loneliness,
      'boredom': boredom,
      'energy': energy,
      'note': note,
    };
  }

  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      timestamp: DateTime.parse(map['timestamp'] as String),
      moodLabel: (map['moodLabel'] as String?) ?? 'Neutral',
      stress: (map['stress'] as num).toInt(),
      loneliness: (map['loneliness'] as num).toInt(),
      boredom: (map['boredom'] as num).toInt(),
      energy: (map['energy'] as num).toInt(),
      note: (map['note'] as String?) ?? '',
    );
  }
}
EOD

cat > lib/features/log/data/mood_log_repository.dart <<'EOD'
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/mood_entry.dart';

class MoodLogRepository {
  static const String _storageKey = 'mood_logs';

  Future<List<MoodEntry>> getEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return <MoodEntry>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (item) => MoodEntry.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> saveEntry(MoodEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getEntries();
    final updated = <MoodEntry>[entry, ...existing];
    final encoded = jsonEncode(updated.map((item) => item.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
EOD
cat > lib/features/log/presentation/mood_log_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/mood_log_repository.dart';
import '../domain/mood_entry.dart';

class MoodLogScreen extends StatefulWidget {
  const MoodLogScreen({super.key});

  @override
  State<MoodLogScreen> createState() => _MoodLogScreenState();
}

class _MoodLogScreenState extends State<MoodLogScreen> {
  final MoodLogRepository _repository = MoodLogRepository();
  final TextEditingController _noteController = TextEditingController();

  String _moodLabel = 'Neutral';
  double _stress = 4;
  double _loneliness = 4;
  double _boredom = 4;
  double _energy = 5;
  bool _isSaving = false;

  static const List<String> _moods = <String>[
    'Calm',
    'Neutral',
    'Stressed',
    'Lonely',
    'Bored',
    'Frustrated',
    'Hopeful',
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveMood() async {
    setState(() => _isSaving = true);

    final entry = MoodEntry(
      timestamp: DateTime.now(),
      moodLabel: _moodLabel,
      stress: _stress.round(),
      loneliness: _loneliness.round(),
      boredom: _boredom.round(),
      energy: _energy.round(),
      note: _noteController.text.trim(),
    );

    await _repository.saveEntry(entry);

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved mood log: ${entry.moodLabel}.')),
    );

    Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.home,
      (route) => route.isFirst,
    );
  }

  Widget _buildSlider({
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.section),
          const SizedBox(height: AppSpacing.sm),
          Text('${value.round()} / 10', style: AppTypography.body),
          Slider(
            value: value,
            min: 0,
            max: 10,
            divisions: 10,
            label: value.round().toString(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mood Log')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Check in honestly.', style: AppTypography.title),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Mood logs help the app understand when your risk is rising.',
              style: AppTypography.muted,
            ),
            const SizedBox(height: AppSpacing.lg),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How would you label this moment?', style: AppTypography.section),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    value: _moodLabel,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: _moods
                        .map(
                          (mood) => DropdownMenuItem<String>(
                            value: mood,
                            child: Text(mood),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _moodLabel = value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildSlider(
              title: 'Stress',
              value: _stress,
              onChanged: (value) => setState(() => _stress = value),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildSlider(
              title: 'Loneliness',
              value: _loneliness,
              onChanged: (value) => setState(() => _loneliness = value),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildSlider(
              title: 'Boredom',
              value: _boredom,
              onChanged: (value) => setState(() => _boredom = value),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildSlider(
              title: 'Energy',
              value: _energy,
              onChanged: (value) => setState(() => _energy = value),
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
                      hintText: 'What is going on right now?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: _isSaving ? 'Saving...' : 'Save Mood Log',
              icon: Icons.mood_outlined,
              onPressed: _isSaving ? () {} : _saveMood,
            ),
          ],
        ),
      ),
    );
  }
}
EOD

cat > lib/features/home/presentation/widgets/risk_status_card.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../log/data/mood_log_repository.dart';
import '../../../log/domain/mood_entry.dart';

class RiskStatusCard extends StatelessWidget {
  const RiskStatusCard({super.key});

  String _riskLabel(List<MoodEntry> entries) {
    if (entries.isEmpty) {
      return 'Guarded';
    }

    final recent = entries.take(3).toList();
    final averageStress =
        recent.map((e) => e.stress).reduce((a, b) => a + b) / recent.length;
    final averageLoneliness =
        recent.map((e) => e.loneliness).reduce((a, b) => a + b) / recent.length;
    final averageBoredom =
        recent.map((e) => e.boredom).reduce((a, b) => a + b) / recent.length;

    final pressure = averageStress + averageLoneliness + averageBoredom;

    if (pressure >= 21) {
      return 'High Risk';
    }
    if (pressure >= 16) {
      return 'Elevated';
    }
    if (pressure >= 10) {
      return 'Guarded';
    }
    return 'Low Risk';
  }

  String _supportText(List<MoodEntry> entries) {
    if (entries.isEmpty) {
      return 'Log your mood to help Breakout estimate risk more accurately.';
    }

    final recent = entries.first;
    return 'Most recent mood: ${recent.moodLabel}. '
        'Stress ${recent.stress}/10 • Loneliness ${recent.loneliness}/10 • '
        'Boredom ${recent.boredom}/10.';
  }

  @override
  Widget build(BuildContext context) {
    final repository = MoodLogRepository();

    return FutureBuilder<List<MoodEntry>>(
      future: repository.getEntries(),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? <MoodEntry>[];
        final label = _riskLabel(entries);
        final detail = _supportText(entries);

        return InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Risk Status', style: AppTypography.section),
              const SizedBox(height: AppSpacing.sm),
              Chip(label: Text(label)),
              const SizedBox(height: 8),
              Text(detail, style: AppTypography.muted),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Log Mood Now',
                icon: Icons.mood_outlined,
                onPressed: () => Navigator.pushNamed(context, RouteNames.moodLog),
              ),
            ],
          ),
        );
      },
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
import '../features/log/presentation/mood_log_screen.dart';
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

cat > lib/features/home/presentation/widgets/quick_actions_row.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/widgets/info_card.dart';

class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, RouteNames.rescue),
            icon: const Icon(Icons.health_and_safety_outlined),
            label: const Text('I feel an urge'),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, RouteNames.moodLog),
            icon: const Icon(Icons.mood_outlined),
            label: const Text('Log mood'),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, RouteNames.support),
            icon: const Icon(Icons.call_outlined),
            label: const Text('Call support'),
          ),
        ],
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
import '../domain/cycle_stage_log_entry.dart';

class LogHubScreen extends StatelessWidget {
  const LogHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = CycleStageLogRepository();

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
                  'Mood log, urge log, relapse log, and victory log grow from here. '
                  'This pass adds cycle-stage logging first.',
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
                  label: 'Log Mood',
                  icon: Icons.mood_outlined,
                  onPressed: () => Navigator.pushNamed(
                    context,
                    RouteNames.moodLog,
                  ),
                ),
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
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FutureBuilder<List<CycleStageLogEntry>>(
            future: repository.getEntries(),
            builder: (context, snapshot) {
              final entries = snapshot.data ?? <CycleStageLogEntry>[];

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const InfoCard(
                  child: Text('Loading recent logs...', style: AppTypography.muted),
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
                    for (final entry in entries.take(5)) ...[
                      _LogRow(entry: entry),
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
              Navigator.pushReplacementNamed(context, RouteNames.insights);
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
          BottomNavigationBarItem(icon: Icon(Icons.insights_outlined), label: 'Insights'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent_outlined), label: 'Support'),
        ],
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  final CycleStageLogEntry entry;

  const _LogRow({
    required this.entry,
  });

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
EOD

cat > tools/verify_ba06.py <<'EOD'
from pathlib import Path
import sys

REQUIRED = [
    'lib/core/constants/route_names.dart',
    'lib/features/log/domain/mood_entry.dart',
    'lib/features/log/data/mood_log_repository.dart',
    'lib/features/log/presentation/mood_log_screen.dart',
    'lib/features/home/presentation/widgets/risk_status_card.dart',
    'lib/app/app_router.dart',
    'lib/features/home/presentation/widgets/quick_actions_row.dart',
    'lib/features/log/presentation/log_hub_screen.dart',
]

REQUIRED_TEXT = {
    'lib/core/constants/route_names.dart': "static const moodLog = '/log/mood';",
    'lib/features/log/domain/mood_entry.dart': 'class MoodEntry',
    'lib/features/log/data/mood_log_repository.dart': 'class MoodLogRepository',
    'lib/features/log/presentation/mood_log_screen.dart': 'class MoodLogScreen extends StatefulWidget',
    'lib/features/home/presentation/widgets/risk_status_card.dart': 'MoodLogRepository',
    'lib/app/app_router.dart': 'case RouteNames.moodLog:',
    'lib/features/home/presentation/widgets/quick_actions_row.dart': 'RouteNames.moodLog',
    'lib/features/log/presentation/log_hub_screen.dart': "label: 'Log Mood'",
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

    print('Breakout Addiction BA-06 mood scaffold verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
EOD

echo "==> BA-06 mood scaffold written."
echo "==> Running Python verification..."
python3 tools/verify_ba06.py
