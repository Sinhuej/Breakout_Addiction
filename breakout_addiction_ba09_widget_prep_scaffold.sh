#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

echo "==> Applying Breakout Addiction BA-09 widget prep scaffold in: $ROOT_DIR"

mkdir -p \
  lib/core/privacy \
  lib/features/widget/domain \
  lib/features/privacy/data \
  tools

cat > lib/core/privacy/neutral_labels.dart <<'EOD'
class NeutralLabels {
  static String rescuePrimary(bool neutralMode) {
    return neutralMode ? 'Daily Reset' : 'I feel an urge';
  }

  static String moodLog(bool neutralMode) {
    return neutralMode ? 'Log Check-In' : 'Log mood';
  }

  static String supportAction(bool neutralMode) {
    return neutralMode ? 'Contact Support' : 'Call support';
  }

  static String riskCardAction(bool neutralMode) {
    return neutralMode ? 'Log Check-In Now' : 'Log Mood Now';
  }

  static String widgetHome(bool neutralMode) {
    return neutralMode ? 'Open Breakout' : 'Open Breakout';
  }

  static String widgetRescue(bool neutralMode) {
    return neutralMode ? 'Daily Reset' : 'Open Rescue';
  }

  static String widgetMood(bool neutralMode) {
    return neutralMode ? 'Log Check-In' : 'Log Mood';
  }

  static String cycleWheelTitle(bool neutralMode) {
    return neutralMode ? 'Pattern Wheel' : 'Recovery Cycle Wheel';
  }

  static String logHubTitle(bool neutralMode) {
    return neutralMode ? 'Private Check-Ins' : 'Private Logs';
  }
}
EOD

cat > lib/features/widget/domain/widget_entry_action.dart <<'EOD'
import '../../../core/constants/route_names.dart';

enum WidgetEntryAction {
  openHome,
  openRescue,
  openMoodLog,
}

extension WidgetEntryActionX on WidgetEntryAction {
  String get routeName {
    switch (this) {
      case WidgetEntryAction.openHome:
        return RouteNames.home;
      case WidgetEntryAction.openRescue:
        return RouteNames.rescue;
      case WidgetEntryAction.openMoodLog:
        return RouteNames.moodLog;
    }
  }

  String get deepLinkKey {
    switch (this) {
      case WidgetEntryAction.openHome:
        return 'home';
      case WidgetEntryAction.openRescue:
        return 'rescue';
      case WidgetEntryAction.openMoodLog:
        return 'mood';
    }
  }
}
EOD

cat > lib/features/widget/domain/widget_display_mode.dart <<'EOD'
enum WidgetDisplayMode {
  standard,
  neutral,
}
EOD

cat > lib/features/privacy/data/privacy_label_repository.dart <<'EOD'
import '../domain/lock_settings.dart';
import 'lock_settings_repository.dart';

class PrivacyLabelRepository {
  final LockSettingsRepository _lockRepository = LockSettingsRepository();

  Future<bool> isNeutralModeEnabled() async {
    final LockSettings settings = await _lockRepository.getSettings();
    return settings.neutralPrivacyMode;
  }
}
EOD
cat > lib/features/home/presentation/widgets/quick_actions_row.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/privacy/neutral_labels.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../privacy/data/privacy_label_repository.dart';

class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = PrivacyLabelRepository();

    return FutureBuilder<bool>(
      future: repository.isNeutralModeEnabled(),
      builder: (context, snapshot) {
        final neutralMode = snapshot.data ?? true;

        return InfoCard(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, RouteNames.rescue),
                icon: const Icon(Icons.health_and_safety_outlined),
                label: Text(NeutralLabels.rescuePrimary(neutralMode)),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, RouteNames.moodLog),
                icon: const Icon(Icons.mood_outlined),
                label: Text(NeutralLabels.moodLog(neutralMode)),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, RouteNames.support),
                icon: const Icon(Icons.call_outlined),
                label: Text(NeutralLabels.supportAction(neutralMode)),
              ),
            ],
          ),
        );
      },
    );
  }
}
EOD

cat > lib/features/home/presentation/widgets/risk_status_card.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/privacy/neutral_labels.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../log/data/mood_log_repository.dart';
import '../../../log/domain/mood_entry.dart';
import '../../../privacy/data/privacy_label_repository.dart';

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
    final moodRepository = MoodLogRepository();
    final labelRepository = PrivacyLabelRepository();

    return FutureBuilder<List<dynamic>>(
      future: Future.wait<dynamic>([
        moodRepository.getEntries(),
        labelRepository.isNeutralModeEnabled(),
      ]),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final entries =
            data != null && data.isNotEmpty ? data[0] as List<MoodEntry> : <MoodEntry>[];
        final neutralMode =
            data != null && data.length > 1 ? data[1] as bool : true;

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
                label: NeutralLabels.riskCardAction(neutralMode),
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

cat > lib/features/home/presentation/home_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/privacy/neutral_labels.dart';
import '../../../core/widgets/info_card.dart';
import '../../../features/privacy/data/privacy_label_repository.dart';
import 'widgets/daily_quote_card.dart';
import 'widgets/quick_actions_row.dart';
import 'widgets/risk_status_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final labelRepository = PrivacyLabelRepository();

    return FutureBuilder<bool>(
      future: labelRepository.isNeutralModeEnabled(),
      builder: (context, snapshot) {
        final neutralMode = snapshot.data ?? true;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Breakout Addiction'),
            actions: [
              IconButton(
                onPressed: () => Navigator.pushNamed(context, RouteNames.support),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text('Break the cycle earlier.', style: AppTypography.title),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Catch the urge before it becomes behavior.',
                  style: AppTypography.muted,
                ),
                const SizedBox(height: AppSpacing.lg),
                const DailyQuoteCard(),
                const SizedBox(height: AppSpacing.md),
                const RiskStatusCard(),
                const SizedBox(height: AppSpacing.md),
                const QuickActionsRow(),
                const SizedBox(height: AppSpacing.md),
                InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        NeutralLabels.cycleWheelTitle(neutralMode),
                        style: AppTypography.section,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Triggers → High Risk → Warning Signs → Fantasies → '
                        'Actions / Behaviors → Short-Lived Pleasure → '
                        'Short-Lived Guilt & Fear → Justifying / Making It Okay',
                        style: AppTypography.muted,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => Navigator.pushNamed(context, RouteNames.cycle),
                          icon: const Icon(Icons.donut_large_outlined),
                          label: const Text('Open Cycle Wheel'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, RouteNames.rescue),
                          icon: const Icon(Icons.health_and_safety_outlined),
                          label: Text(NeutralLabels.rescuePrimary(neutralMode)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Progress Snapshot', style: AppTypography.section),
                      SizedBox(height: AppSpacing.sm),
                      Text('Current streak: 0 days', style: AppTypography.body),
                      SizedBox(height: 6),
                      Text('Urges this week: 0', style: AppTypography.body),
                      SizedBox(height: 6),
                      Text('Rescues completed: 0', style: AppTypography.body),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 0,
            onTap: (index) {
              switch (index) {
                case 0:
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
      },
    );
  }
}
EOD
cat > tools/verify_ba09.py <<'EOD'
from pathlib import Path
import sys

REQUIRED = [
    'lib/core/privacy/neutral_labels.dart',
    'lib/features/widget/domain/widget_entry_action.dart',
    'lib/features/widget/domain/widget_display_mode.dart',
    'lib/features/privacy/data/privacy_label_repository.dart',
    'lib/features/home/presentation/widgets/quick_actions_row.dart',
    'lib/features/home/presentation/widgets/risk_status_card.dart',
    'lib/features/home/presentation/home_screen.dart',
]

REQUIRED_TEXT = {
    'lib/core/privacy/neutral_labels.dart': 'class NeutralLabels',
    'lib/features/widget/domain/widget_entry_action.dart': 'enum WidgetEntryAction',
    'lib/features/widget/domain/widget_display_mode.dart': 'enum WidgetDisplayMode',
    'lib/features/privacy/data/privacy_label_repository.dart': 'class PrivacyLabelRepository',
    'lib/features/home/presentation/widgets/quick_actions_row.dart': 'NeutralLabels.rescuePrimary',
    'lib/features/home/presentation/widgets/risk_status_card.dart': 'NeutralLabels.riskCardAction',
    'lib/features/home/presentation/home_screen.dart': 'NeutralLabels.cycleWheelTitle',
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

    print('Breakout Addiction BA-09 widget prep verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
EOD

echo "==> BA-09 widget prep scaffold written."
echo "==> Running Python verification..."
python3 tools/verify_ba09.py
