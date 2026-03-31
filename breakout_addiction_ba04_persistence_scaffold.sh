#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

echo "==> Applying Breakout Addiction BA-04 persistence scaffold in: $ROOT_DIR"

mkdir -p \
  lib/features/log/data \
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

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
EOD

cat > lib/features/log/domain/cycle_stage_log_entry.dart <<'EOD'
import '../../cycle/domain/cycle_stage.dart';

class CycleStageLogEntry {
  final DateTime timestamp;
  final CycleStage stage;
  final int intensity;
  final String note;

  const CycleStageLogEntry({
    required this.timestamp,
    required this.stage,
    required this.intensity,
    required this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'stage': stage.name,
      'intensity': intensity,
      'note': note,
    };
  }

  factory CycleStageLogEntry.fromMap(Map<String, dynamic> map) {
    return CycleStageLogEntry(
      timestamp: DateTime.parse(map['timestamp'] as String),
      stage: CycleStage.values.byName(map['stage'] as String),
      intensity: (map['intensity'] as num).toInt(),
      note: (map['note'] as String?) ?? '',
    );
  }
}
EOD

cat > lib/features/log/data/cycle_stage_log_repository.dart <<'EOD'
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/cycle_stage_log_entry.dart';

class CycleStageLogRepository {
  static const String _storageKey = 'cycle_stage_logs';

  Future<List<CycleStageLogEntry>> getEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return <CycleStageLogEntry>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (item) => CycleStageLogEntry.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> saveEntry(CycleStageLogEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getEntries();
    final updated = <CycleStageLogEntry>[entry, ...existing];
    final encoded = jsonEncode(updated.map((item) => item.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
EOD
cat > lib/features/log/presentation/cycle_stage_log_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../cycle/domain/cycle_stage.dart';
import '../data/cycle_stage_log_repository.dart';
import '../domain/cycle_stage_log_entry.dart';

class CycleStageLogScreen extends StatefulWidget {
  final CycleStage initialStage;

  const CycleStageLogScreen({
    super.key,
    required this.initialStage,
  });

  @override
  State<CycleStageLogScreen> createState() => _CycleStageLogScreenState();
}

class _CycleStageLogScreenState extends State<CycleStageLogScreen> {
  late CycleStage _selectedStage;
  double _intensity = 5;
  final TextEditingController _noteController = TextEditingController();
  final CycleStageLogRepository _repository = CycleStageLogRepository();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedStage = widget.initialStage;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveLog() async {
    setState(() => _isSaving = true);

    final entry = CycleStageLogEntry(
      timestamp: DateTime.now(),
      stage: _selectedStage,
      intensity: _intensity.round(),
      note: _noteController.text.trim(),
    );

    await _repository.saveEntry(entry);

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Saved ${entry.stage.title} log at intensity ${entry.intensity}.',
        ),
      ),
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
      appBar: AppBar(title: const Text('Cycle Stage Log')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Name the moment clearly.', style: AppTypography.title),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'The goal is not perfection. The goal is to catch the pattern earlier.',
              style: AppTypography.muted,
            ),
            const SizedBox(height: AppSpacing.lg),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Stage', style: AppTypography.section),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<CycleStage>(
                    value: _selectedStage,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: CycleStage.values.map((stage) {
                      return DropdownMenuItem<CycleStage>(
                        value: stage,
                        child: Text(stage.title),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedStage = value);
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
                  Text('Urge Intensity', style: AppTypography.section),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${_intensity.round()} / 10',
                    style: AppTypography.body,
                  ),
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
                  Text('What is happening right now?', style: AppTypography.section),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _noteController,
                    minLines: 4,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText: 'Example: late-night scrolling, stressed, starting to rationalize, feeling isolated...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: _isSaving ? 'Saving...' : 'Save Stage Log',
              icon: Icons.save_outlined,
              onPressed: _isSaving ? () {} : _saveLog,
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, RouteNames.rescue),
                icon: const Icon(Icons.health_and_safety_outlined),
                label: const Text('Open Rescue Instead'),
              ),
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

cat > tools/verify_ba04.py <<'EOD'
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
EOD

echo "==> BA-04 persistence scaffold written."
echo "==> Running Python verification..."
python3 tools/verify_ba04.py
