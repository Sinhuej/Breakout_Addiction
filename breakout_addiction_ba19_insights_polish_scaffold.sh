#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

echo "==> Applying Breakout Addiction BA-19 insights polish scaffold in: $ROOT_DIR"

mkdir -p \
  lib/features/insights/domain \
  lib/features/insights/data \
  lib/features/insights/presentation \
  tools

cat > lib/features/insights/domain/insight_summary.dart <<'EOD'
class InsightSummary {
  final int moodLogCount;
  final int stageLogCount;
  final int urgeCount;
  final int relapseCount;
  final int victoryCount;
  final String recentRiskLabel;
  final double averageStress;
  final double averageLoneliness;
  final double averageBoredom;
  final String topStageTitle;
  final String mostCommonMoodLabel;
  final String strongestPressureDriver;
  final String summaryLine;
  final String recommendationLine;
  final String nextBestAction;

  const InsightSummary({
    required this.moodLogCount,
    required this.stageLogCount,
    required this.urgeCount,
    required this.relapseCount,
    required this.victoryCount,
    required this.recentRiskLabel,
    required this.averageStress,
    required this.averageLoneliness,
    required this.averageBoredom,
    required this.topStageTitle,
    required this.mostCommonMoodLabel,
    required this.strongestPressureDriver,
    required this.summaryLine,
    required this.recommendationLine,
    required this.nextBestAction,
  });

  factory InsightSummary.empty() {
    return const InsightSummary(
      moodLogCount: 0,
      stageLogCount: 0,
      urgeCount: 0,
      relapseCount: 0,
      victoryCount: 0,
      recentRiskLabel: 'Not enough data',
      averageStress: 0,
      averageLoneliness: 0,
      averageBoredom: 0,
      topStageTitle: 'None yet',
      mostCommonMoodLabel: 'Unknown',
      strongestPressureDriver: 'Unknown',
      summaryLine: 'Start logging mood, stages, and recovery events to unlock stronger insights.',
      recommendationLine: 'A few honest check-ins will make this screen much smarter.',
      nextBestAction: 'Log a mood or cycle stage today.',
    );
  }
}
EOD

cat > lib/features/insights/data/insights_repository.dart <<'EOD'
import '../../cycle/domain/cycle_stage.dart';
import '../../log/data/cycle_stage_log_repository.dart';
import '../../log/data/mood_log_repository.dart';
import '../../log/data/recovery_event_repository.dart';
import '../../log/domain/cycle_stage_log_entry.dart';
import '../../log/domain/mood_entry.dart';
import '../../log/domain/recovery_event_entry.dart';
import '../domain/insight_summary.dart';

class InsightsRepository {
  final MoodLogRepository _moodRepository = MoodLogRepository();
  final CycleStageLogRepository _stageRepository =
      CycleStageLogRepository();
  final RecoveryEventRepository _eventRepository =
      RecoveryEventRepository();

  String _recentRiskLabel(
    double averageStress,
    double averageLoneliness,
    double averageBoredom,
  ) {
    final pressure = averageStress + averageLoneliness + averageBoredom;
    if (pressure >= 21) return 'High Risk';
    if (pressure >= 16) return 'Elevated';
    if (pressure >= 10) return 'Guarded';
    return 'Low Risk';
  }

  String _strongestDriver(
    double averageStress,
    double averageLoneliness,
    double averageBoredom,
  ) {
    final values = <String, double>{
      'Stress': averageStress,
      'Loneliness': averageLoneliness,
      'Boredom': averageBoredom,
    };

    final sorted = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.isEmpty ? 'Unknown' : sorted.first.key;
  }

  String _mostCommonMood(List<MoodEntry> moods) {
    if (moods.isEmpty) return 'Unknown';

    final counts = <String, int>{};
    for (final mood in moods) {
      counts.update(mood.moodLabel, (value) => value + 1, ifAbsent: () => 1);
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.key;
  }

  String _topStage(List<CycleStageLogEntry> stages) {
    if (stages.isEmpty) return 'None yet';

    final counts = <String, int>{};
    for (final entry in stages) {
      counts.update(entry.stage.title, (value) => value + 1, ifAbsent: () => 1);
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.key;
  }

  int _countEvents(List<RecoveryEventEntry> entries, RecoveryEventType type) {
    return entries.where((entry) => entry.type == type).length;
  }

  String _summaryLine({
    required bool hasMoods,
    required bool hasStages,
    required bool hasEvents,
    required String topStageTitle,
    required String recentRiskLabel,
    required String strongestPressureDriver,
  }) {
    if (!hasMoods && !hasStages && !hasEvents) {
      return 'You need a little more logging before clear patterns can emerge.';
    }
    if (!hasMoods) {
      return 'Stage and recovery event logs are forming a pattern, but mood context is still limited.';
    }
    if (!hasStages) {
      return 'Mood logs are building, but stage logging will sharpen where the cycle speeds up.';
    }
    return 'Your recent pattern points most strongly toward $topStageTitle with $strongestPressureDriver as the biggest pressure driver and a $recentRiskLabel overall level.';
  }

  String _recommendationLine({
    required String recentRiskLabel,
    required String strongestPressureDriver,
    required int victoryCount,
    required int relapseCount,
  }) {
    if (recentRiskLabel == 'High Risk') {
      return 'Reduce friction fast around $strongestPressureDriver-heavy moments and use Rescue earlier.';
    }
    if (relapseCount > victoryCount && relapseCount >= 2) {
      return 'Review your recovery plan and tighten your first-action step so it is easier to do automatically.';
    }
    if (victoryCount >= relapseCount && victoryCount > 0) {
      return 'Your wins show that interruption is working. Study what happened before those better moments.';
    }
    return 'Keep logging earlier in the cycle so your patterns become easier to interrupt.';
  }

  String _nextBestAction({
    required String strongestPressureDriver,
    required String topStageTitle,
    required String recentRiskLabel,
  }) {
    if (recentRiskLabel == 'High Risk') {
      return 'Set up a risk window around your most vulnerable time and prepare your first action in advance.';
    }
    if (topStageTitle == 'Warning Signs' || topStageTitle == 'Fantasies') {
      return 'Focus on faster interruption when you notice mental drift or early ritual behavior.';
    }
    if (strongestPressureDriver == 'Loneliness') {
      return 'Build one human-contact action into your plan before high-risk windows start.';
    }
    if (strongestPressureDriver == 'Stress') {
      return 'Use a grounding action before the urge has time to turn into a ritual.';
    }
    return 'Keep building early awareness with mood and stage logging.';
  }

  Future<InsightSummary> buildSummary() async {
    final List<MoodEntry> moods = await _moodRepository.getEntries();
    final List<CycleStageLogEntry> stages = await _stageRepository.getEntries();
    final List<RecoveryEventEntry> events = await _eventRepository.getEntries();

    if (moods.isEmpty && stages.isEmpty && events.isEmpty) {
      return InsightSummary.empty();
    }

    final List<MoodEntry> recentMoods = moods.take(7).toList();

    final double averageStress = recentMoods.isEmpty
        ? 0
        : recentMoods.map((e) => e.stress).reduce((a, b) => a + b) /
            recentMoods.length;

    final double averageLoneliness = recentMoods.isEmpty
        ? 0
        : recentMoods
                .map((e) => e.loneliness)
                .reduce((a, b) => a + b) /
            recentMoods.length;

    final double averageBoredom = recentMoods.isEmpty
        ? 0
        : recentMoods.map((e) => e.boredom).reduce((a, b) => a + b) /
            recentMoods.length;

    final recentRiskLabel = _recentRiskLabel(
      averageStress,
      averageLoneliness,
      averageBoredom,
    );

    final topStageTitle = _topStage(stages);
    final mostCommonMoodLabel = _mostCommonMood(moods);
    final strongestPressureDriver = _strongestDriver(
      averageStress,
      averageLoneliness,
      averageBoredom,
    );

    final urgeCount = _countEvents(events, RecoveryEventType.urge);
    final relapseCount = _countEvents(events, RecoveryEventType.relapse);
    final victoryCount = _countEvents(events, RecoveryEventType.victory);

    final summaryLine = _summaryLine(
      hasMoods: moods.isNotEmpty,
      hasStages: stages.isNotEmpty,
      hasEvents: events.isNotEmpty,
      topStageTitle: topStageTitle,
      recentRiskLabel: recentRiskLabel,
      strongestPressureDriver: strongestPressureDriver,
    );

    final recommendationLine = _recommendationLine(
      recentRiskLabel: recentRiskLabel,
      strongestPressureDriver: strongestPressureDriver,
      victoryCount: victoryCount,
      relapseCount: relapseCount,
    );

    final nextBestAction = _nextBestAction(
      strongestPressureDriver: strongestPressureDriver,
      topStageTitle: topStageTitle,
      recentRiskLabel: recentRiskLabel,
    );

    return InsightSummary(
      moodLogCount: moods.length,
      stageLogCount: stages.length,
      urgeCount: urgeCount,
      relapseCount: relapseCount,
      victoryCount: victoryCount,
      recentRiskLabel: recentRiskLabel,
      averageStress: averageStress,
      averageLoneliness: averageLoneliness,
      averageBoredom: averageBoredom,
      topStageTitle: topStageTitle,
      mostCommonMoodLabel: mostCommonMoodLabel,
      strongestPressureDriver: strongestPressureDriver,
      summaryLine: summaryLine,
      recommendationLine: recommendationLine,
      nextBestAction: nextBestAction,
    );
  }
}
EOD
cat > lib/features/insights/presentation/insights_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../data/insights_repository.dart';
import '../domain/insight_summary.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  Widget _metricCard({
    required String title,
    required String value,
    required String subtitle,
  }) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.section),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTypography.title),
          const SizedBox(height: 6),
          Text(subtitle, style: AppTypography.muted),
        ],
      ),
    );
  }

  Widget _eventCard({
    required String title,
    required int count,
    required String subtitle,
  }) {
    return Expanded(
      child: InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.section),
            const SizedBox(height: AppSpacing.sm),
            Text('$count', style: AppTypography.title),
            const SizedBox(height: 6),
            Text(subtitle, style: AppTypography.muted),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(InsightSummary summary) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('Insights', style: AppTypography.title),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Patterns become easier to interrupt when they are easier to read.',
          style: AppTypography.muted,
        ),
        const SizedBox(height: AppSpacing.lg),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recent Risk Summary', style: AppTypography.section),
              const SizedBox(height: AppSpacing.sm),
              Chip(label: Text(summary.recentRiskLabel)),
              const SizedBox(height: AppSpacing.sm),
              Text(summary.summaryLine, style: AppTypography.body),
              const SizedBox(height: AppSpacing.sm),
              Text(summary.recommendationLine, style: AppTypography.muted),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            _eventCard(
              title: 'Urges',
              count: summary.urgeCount,
              subtitle: 'Logged urge events',
            ),
            const SizedBox(width: AppSpacing.md),
            _eventCard(
              title: 'Relapses',
              count: summary.relapseCount,
              subtitle: 'Logged slips',
            ),
            const SizedBox(width: AppSpacing.md),
            _eventCard(
              title: 'Victories',
              count: summary.victoryCount,
              subtitle: 'Logged wins',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _metricCard(
          title: 'Top Recent Stage',
          value: summary.topStageTitle,
          subtitle: 'Where the cycle most often shows up in your logs.',
        ),
        const SizedBox(height: AppSpacing.md),
        _metricCard(
          title: 'Most Common Mood',
          value: summary.mostCommonMoodLabel,
          subtitle: 'The mood label you log most often.',
        ),
        const SizedBox(height: AppSpacing.md),
        _metricCard(
          title: 'Strongest Pressure Driver',
          value: summary.strongestPressureDriver,
          subtitle: 'The heaviest average pressure in recent mood logs.',
        ),
        const SizedBox(height: AppSpacing.md),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mood Pressure Averages', style: AppTypography.section),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Stress: ${summary.averageStress.toStringAsFixed(1)}/10',
                style: AppTypography.body,
              ),
              const SizedBox(height: 6),
              Text(
                'Loneliness: ${summary.averageLoneliness.toStringAsFixed(1)}/10',
                style: AppTypography.body,
              ),
              const SizedBox(height: 6),
              Text(
                'Boredom: ${summary.averageBoredom.toStringAsFixed(1)}/10',
                style: AppTypography.body,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Next Best Action', style: AppTypography.section),
              const SizedBox(height: AppSpacing.sm),
              Text(summary.nextBestAction, style: AppTypography.body),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = InsightsRepository();

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: FutureBuilder<InsightSummary>(
        future: repository.buildSummary(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final summary = snapshot.data ?? InsightSummary.empty();
          return _buildBody(summary);
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
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
cat > tools/verify_ba19.py <<'EOD'
from pathlib import Path
import sys

REQUIRED = [
    'lib/features/insights/domain/insight_summary.dart',
    'lib/features/insights/data/insights_repository.dart',
    'lib/features/insights/presentation/insights_screen.dart',
]

REQUIRED_TEXT = {
    'lib/features/insights/domain/insight_summary.dart': 'final int victoryCount;',
    'lib/features/insights/data/insights_repository.dart': 'String _nextBestAction',
    'lib/features/insights/presentation/insights_screen.dart': 'Next Best Action',
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

    print('Breakout Addiction BA-19 insights polish verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
EOD

echo "==> BA-19 insights polish scaffold written."
echo "==> Running Python verification..."
python3 tools/verify_ba19.py
