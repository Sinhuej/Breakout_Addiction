#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

echo "==> Applying Breakout Addiction BA-13 rescue scaffold in: $ROOT_DIR"

mkdir -p \
  lib/features/rescue/data \
  lib/features/rescue/presentation/widgets \
  tools

cat > lib/features/rescue/data/reasons_to_stop_repository.dart <<'EOD'
import 'package:shared_preferences/shared_preferences.dart';

class ReasonsToStopRepository {
  static const String _storageKey = 'reasons_to_stop';

  static const List<String> _defaultReasons = <String>[
    'Self-respect',
    'Mental clarity',
    'Relationships',
    'Peace',
  ];

  Future<List<String>> getReasons() async {
    final prefs = await SharedPreferences.getInstance();
    final reasons = prefs.getStringList(_storageKey);
    if (reasons == null || reasons.isEmpty) {
      return _defaultReasons;
    }
    return reasons;
  }

  Future<void> saveReasons(List<String> reasons) async {
    final prefs = await SharedPreferences.getInstance();
    final cleaned = reasons
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    await prefs.setStringList(_storageKey, cleaned);
  }
}
EOD

cat > lib/features/rescue/presentation/widgets/breathing_card.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/info_card.dart';

class BreathingCard extends StatelessWidget {
  const BreathingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Breathe With Me', style: AppTypography.section),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Inhale for 4 • hold for 4 • exhale for 6. Repeat 3 times.',
            style: AppTypography.body,
          ),
          SizedBox(height: 8),
          Text(
            'You are trying to slow the cycle down, not solve your whole life in one minute.',
            style: AppTypography.muted,
          ),
        ],
      ),
    );
  }
}
EOD

cat > lib/features/rescue/presentation/widgets/reasons_to_stop_card.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/info_card.dart';
import '../../data/reasons_to_stop_repository.dart';

class ReasonsToStopCard extends StatelessWidget {
  const ReasonsToStopCard({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = ReasonsToStopRepository();

    return FutureBuilder<List<String>>(
      future: repository.getReasons(),
      builder: (context, snapshot) {
        final reasons = snapshot.data ?? <String>[];

        return InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reasons to Stop', style: AppTypography.section),
              const SizedBox(height: AppSpacing.sm),
              if (reasons.isEmpty)
                const Text(
                  'No reasons saved yet.',
                  style: AppTypography.muted,
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: reasons.map((item) => Chip(label: Text(item))).toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}
EOD
cat > lib/features/rescue/presentation/widgets/delay_actions_card.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/info_card.dart';

class DelayActionsCard extends StatelessWidget {
  const DelayActionsCard({super.key});

  void _announce(BuildContext context, int minutes) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Good call. Delay for $minutes minutes and re-check your state.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Delay Actions', style: AppTypography.section),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton(
                onPressed: () => _announce(context, 3),
                child: const Text('Delay 3 min'),
              ),
              OutlinedButton(
                onPressed: () => _announce(context, 10),
                child: const Text('Delay 10 min'),
              ),
              OutlinedButton(
                onPressed: () => _announce(context, 15),
                child: const Text('Delay 15 min'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
EOD

cat > lib/features/rescue/presentation/widgets/stage_aware_suggestion_card.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../log/data/cycle_stage_log_repository.dart';
import '../../../log/domain/cycle_stage_log_entry.dart';

class StageAwareSuggestionCard extends StatelessWidget {
  const StageAwareSuggestionCard({super.key});

  String _messageForStage(CycleStageLogEntry? entry) {
    if (entry == null) {
      return 'Log a cycle stage to get smarter rescue suggestions here.';
    }

    final title = entry.stage.title;

    if (title == 'Triggers') {
      return 'You are early enough to change location, put the phone down, or text someone now.';
    }
    if (title == 'High Risk') {
      return 'This is a strong moment to leave the current setting and reduce privacy or isolation fast.';
    }
    if (title == 'Warning Signs') {
      return 'Your best move is to interrupt the ritual early: stand up, move rooms, and shorten the decision window.';
    }
    if (title == 'Fantasies') {
      return 'Shift your attention physically. Do not keep negotiating mentally with the urge.';
    }
    if (title == 'Actions / Behaviors') {
      return 'Stop the sequence. Close the app, change environments, and create friction immediately.';
    }
    if (title == 'Short-Lived Pleasure') {
      return 'This is a good time to reflect honestly, log what happened, and keep the spiral from deepening.';
    }
    if (title == 'Short-Lived Guilt & Fear') {
      return 'Do not waste energy hiding. Use honesty and a small reset step right now.';
    }
    if (title == 'Justifying / Making It Okay') {
      return 'Watch permission-giving thoughts closely. Delay, breathe, and do not trust “just once” logic.';
    }

    return 'Use Rescue early and keep the next action simple.';
  }

  @override
  Widget build(BuildContext context) {
    final repository = CycleStageLogRepository();

    return FutureBuilder<List<CycleStageLogEntry>>(
      future: repository.getEntries(),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? <CycleStageLogEntry>[];
        final latest = entries.isEmpty ? null : entries.first;

        return InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stage-Aware Suggestion', style: AppTypography.section),
              const SizedBox(height: AppSpacing.sm),
              if (latest != null) ...[
                Text('Latest stage: ${latest.stage.title}', style: AppTypography.body),
                const SizedBox(height: 8),
              ],
              Text(
                _messageForStage(latest),
                style: AppTypography.muted,
              ),
            ],
          ),
        );
      },
    );
  }
}
EOD

cat > lib/features/rescue/presentation/rescue_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
import 'widgets/breathing_card.dart';
import 'widgets/delay_actions_card.dart';
import 'widgets/reasons_to_stop_card.dart';
import 'widgets/stage_aware_suggestion_card.dart';

class RescueScreen extends StatelessWidget {
  const RescueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rescue')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Pause. You still have a choice.', style: AppTypography.title),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Interrupt the cycle before it gains momentum.',
              style: AppTypography.muted,
            ),
            const SizedBox(height: AppSpacing.lg),
            const InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Urge Intensity', style: AppTypography.section),
                  SizedBox(height: AppSpacing.sm),
                  Slider(value: 4, min: 0, max: 10, onChanged: null),
                  Text('A live slider will be wired in next.', style: AppTypography.muted),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const DelayActionsCard(),
            const SizedBox(height: AppSpacing.md),
            const BreathingCard(),
            const SizedBox(height: AppSpacing.md),
            const StageAwareSuggestionCard(),
            const SizedBox(height: AppSpacing.md),
            const ReasonsToStopCard(),
            const SizedBox(height: AppSpacing.md),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Support Actions', style: AppTypography.section),
                  const SizedBox(height: AppSpacing.sm),
                  PrimaryButton(
                    label: 'Open Support',
                    icon: Icons.support_agent_outlined,
                    onPressed: () => Navigator.pushNamed(context, RouteNames.support),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, RouteNames.home);
              break;
            case 1:
              break;
            case 2:
              Navigator.pushReplacementNamed(context, RouteNames.logHub);
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
EOD
cat > tools/verify_ba13.py <<'EOD'
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
EOD

echo "==> BA-13 rescue scaffold written."
echo "==> Running Python verification..."
python3 tools/verify_ba13.py
