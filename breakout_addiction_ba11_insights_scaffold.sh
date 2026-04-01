#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

echo "==> Applying Breakout Addiction BA-11 insights scaffold in: $ROOT_DIR"

mkdir -p \
  lib/features/insights/domain \
  lib/features/insights/data \
  lib/features/insights/presentation \
  tools

cat > lib/features/insights/domain/insight_summary.dart <<'EOD'
class InsightSummary {
  final int moodLogCount;
  final int stageLogCount;
  final String recentRiskLabel;
  final double averageStress;
  final double averageLoneliness;
  final double averageBoredom;
  final String topStageTitle;
  final String summaryLine;
  final String recommendationLine;

  const InsightSummary({
    required this.moodLogCount,
    required this.stageLogCount,
    required this.recentRiskLabel,
    required this.averageStress,
    required this.averageLoneliness,
    required this.averageBoredom,
    required this.topStageTitle,
    required this.summaryLine,
    required this.recommendationLine,
  });

  factory InsightSummary.empty() {
    return const InsightSummary(
      moodLogCount: 0,
      stageLogCount: 0,
      recentRiskLabel: 'Not enough data',
      averageStress: 0,
      averageLoneliness: 0,
      averageBoredom: 0,
      topStageTitle: 'None yet',
      summaryLine: 'Start logging mood and cycle stages to unlock insights.',
      recommendationLine:
          'A few honest check-ins will make this screen useful very quickly.',
    );
  }
}
EOD

cat > lib/features/insights/data/insights_repository.dart <<'EOD'
import '../../log/data/cycle_stage_log_repository.dart';
import '../../log/data/mood_log_repository.dart';
import '../../log/domain/cycle_stage_log_entry.dart';
import '../../log/domain/mood_entry.dart';
import '../domain/insight_summary.dart';

class InsightsRepository {
  final MoodLogRepository _moodRepository = MoodLogRepository();
  final CycleStageLogRepository _stageRepository =
      CycleStageLogRepository();

  Future<InsightSummary> buildSummary() async {
    final List<MoodEntry> moods = await _moodRepository.getEntries();
    final List<CycleStageLogEntry> stages = await _stageRepository.getEntries();

    if (moods.isEmpty && stages.isEmpty) {
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

    final double pressure = averageStress + averageLoneliness + averageBoredom;

    final String recentRiskLabel;
    if (pressure >= 21) {
      recentRiskLabel = 'High Risk';
    } else if (pressure >= 16) {
      recentRiskLabel = 'Elevated';
    } else if (pressure >= 10) {
      recentRiskLabel = 'Guarded';
    } else {
      recentRiskLabel = 'Low Risk';
    }

    final Map<String, int> stageCounts = <String, int>{};
    for (final entry in stages) {
      stageCounts.update(
        entry.stage.title,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    String topStageTitle = 'None yet';
    if (stageCounts.isNotEmpty) {
      final sorted = stageCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topStageTitle = sorted.first.key;
    }

    final String summaryLine;
    if (moods.isEmpty) {
      summaryLine =
          'Stage logs are starting to form a pattern, but mood context is still limited.';
    } else if (stages.isEmpty) {
      summaryLine =
          'Mood logs are building, but cycle-stage logging will sharpen the pattern.';
    } else {
      summaryLine =
          'Your recent pattern points most strongly toward $topStageTitle with a $recentRiskLabel pressure level.';
    }

    final String recommendationLine;
    if (recentRiskLabel == 'High Risk') {
      recommendationLine =
          'Use Rescue sooner, especially during times when stress, loneliness, or boredom are stacking together.';
    } else if (recentRiskLabel == 'Elevated') {
      recommendationLine =
          'Try logging earlier in the cycle so you can catch warning signs before they turn into actions.';
    } else {
      recommendationLine =
          'Keep stacking honest check-ins. Earlier awareness is helping reduce pressure.';
    }

    return InsightSummary(
      moodLogCount: moods.length,
      stageLogCount: stages.length,
      recentRiskLabel: recentRiskLabel,
      averageStress: averageStress,
      averageLoneliness: averageLoneliness,
      averageBoredom: averageBoredom,
      topStageTitle: topStageTitle,
      summaryLine: summaryLine,
      recommendationLine: recommendationLine,
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
        _metricCard(
          title: 'Top Recent Stage',
          value: summary.topStageTitle,
          subtitle: 'The most frequently logged cycle stage so far.',
        ),
        const SizedBox(height: AppSpacing.md),
        _metricCard(
          title: 'Mood Logs',
          value: '${summary.moodLogCount}',
          subtitle: 'Total mood check-ins saved.',
        ),
        const SizedBox(height: AppSpacing.md),
        _metricCard(
          title: 'Cycle Stage Logs',
          value: '${summary.stageLogCount}',
          subtitle: 'Total stage logs saved.',
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
cat > tools/verify_ba11.py <<'EOD'
from pathlib import Path
import sys

REQUIRED = [
    'lib/features/insights/domain/insight_summary.dart',
    'lib/features/insights/data/insights_repository.dart',
    'lib/features/insights/presentation/insights_screen.dart',
]

REQUIRED_TEXT = {
    'lib/features/insights/domain/insight_summary.dart': 'class InsightSummary',
    'lib/features/insights/data/insights_repository.dart': 'class InsightsRepository',
    'lib/features/insights/presentation/insights_screen.dart': 'Recent Risk Summary',
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

    print('Breakout Addiction BA-11 insights verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
EOD

echo "==> BA-11 insights scaffold written."
echo "==> Running Python verification..."
python3 tools/verify_ba11.py
