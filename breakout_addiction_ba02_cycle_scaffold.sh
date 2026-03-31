#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

echo "==> Applying Breakout Addiction BA-02 Cycle Wheel scaffold in: $ROOT_DIR"

mkdir -p \
  lib/features/cycle/domain \
  lib/features/cycle/presentation \
  tools

cat > lib/core/constants/route_names.dart <<'EOD'
class RouteNames {
  static const home = '/';
  static const rescue = '/rescue';
  static const logHub = '/log';
  static const insights = '/insights';
  static const support = '/support';
  static const cycle = '/cycle';
}
EOD

cat > lib/app/app_router.dart <<'EOD'
import 'package:flutter/material.dart';

import '../core/constants/route_names.dart';
import '../features/cycle/presentation/cycle_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/insights/presentation/insights_screen.dart';
import '../features/log/presentation/log_hub_screen.dart';
import '../features/privacy/domain/lock_scope.dart';
import '../features/privacy/domain/lock_settings.dart';
import '../features/privacy/presentation/lock_gate_screen.dart';
import '../features/rescue/presentation/rescue_screen.dart';
import '../features/support/presentation/support_screen.dart';

class AppRouter {
  static final LockSettings _lockSettings = LockSettings.disabled();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case RouteNames.rescue:
        return MaterialPageRoute(builder: (_) => const RescueScreen());
      case RouteNames.cycle:
        return MaterialPageRoute(
          builder: (_) => _protect(
            scope: LockScope.cycle,
            child: const CycleScreen(),
          ),
        );
      case RouteNames.logHub:
        return MaterialPageRoute(
          builder: (_) => _protect(
            scope: LockScope.logs,
            child: const LogHubScreen(),
          ),
        );
      case RouteNames.insights:
        return MaterialPageRoute(
          builder: (_) => _protect(
            scope: LockScope.insights,
            child: const InsightsScreen(),
          ),
        );
      case RouteNames.support:
        return MaterialPageRoute(builder: (_) => const SupportScreen());
      default:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }

  static Widget _protect({
    required LockScope scope,
    required Widget child,
  }) {
    final shouldLock = _lockSettings.shouldLock(scope);
    if (!shouldLock) {
      return child;
    }

    return LockGateScreen(
      title: 'Protected Content',
      subtitle: 'Unlock to continue.',
      onUnlockSuccess: () {},
    );
  }
}
EOD

cat > lib/features/cycle/domain/cycle_stage.dart <<'EOD'
enum CycleStage {
  triggers,
  highRisk,
  warningSigns,
  fantasies,
  actionsBehaviors,
  shortLivedPleasure,
  shortLivedGuiltFear,
  justifyingMakingItOkay,
}

extension CycleStageX on CycleStage {
  String get shortLabel {
    switch (this) {
      case CycleStage.triggers:
        return 'Triggers';
      case CycleStage.highRisk:
        return 'High Risk';
      case CycleStage.warningSigns:
        return 'Warning Signs';
      case CycleStage.fantasies:
        return 'Fantasies';
      case CycleStage.actionsBehaviors:
        return 'Actions';
      case CycleStage.shortLivedPleasure:
        return 'Pleasure';
      case CycleStage.shortLivedGuiltFear:
        return 'Guilt & Fear';
      case CycleStage.justifyingMakingItOkay:
        return 'Justifying';
    }
  }

  String get title {
    switch (this) {
      case CycleStage.triggers:
        return 'Triggers';
      case CycleStage.highRisk:
        return 'High Risk';
      case CycleStage.warningSigns:
        return 'Warning Signs';
      case CycleStage.fantasies:
        return 'Fantasies';
      case CycleStage.actionsBehaviors:
        return 'Actions / Behaviors';
      case CycleStage.shortLivedPleasure:
        return 'Short-Lived Pleasure';
      case CycleStage.shortLivedGuiltFear:
        return 'Short-Lived Guilt & Fear';
      case CycleStage.justifyingMakingItOkay:
        return 'Justifying / Making It Okay';
    }
  }

  String get description {
    switch (this) {
      case CycleStage.triggers:
        return 'The moments, emotions, places, or situations that start the cycle.';
      case CycleStage.highRisk:
        return 'Settings or times when acting out becomes more likely unless interrupted early.';
      case CycleStage.warningSigns:
        return 'The subtle signals that tell you the cycle is gaining momentum.';
      case CycleStage.fantasies:
        return 'Mental drift, urge replay, and imagination patterns that pull attention deeper.';
      case CycleStage.actionsBehaviors:
        return 'The choices, rituals, and behaviors that move from urge toward acting out.';
      case CycleStage.shortLivedPleasure:
        return 'A temporary reward or relief that fades quickly.';
      case CycleStage.shortLivedGuiltFear:
        return 'The emotional crash, shame, fear, or regret that often follows.';
      case CycleStage.justifyingMakingItOkay:
        return 'The internal permission-giving that lowers resistance and restarts the cycle.';
    }
  }

  List<String> get examples {
    switch (this) {
      case CycleStage.triggers:
        return ['Loneliness', 'Stress', 'Boredom', 'Late-night phone use'];
      case CycleStage.highRisk:
        return ['Alone in bed', 'After an argument', 'After alcohol', 'Long scrolling sessions'];
      case CycleStage.warningSigns:
        return ['Restless mood', 'Hiding behavior', 'Rationalizing', '“Just a quick look”'];
      case CycleStage.fantasies:
        return ['Mental replay', 'Escaping into imagination', 'Curiosity building', 'Urge spikes'];
      case CycleStage.actionsBehaviors:
        return ['Searching', 'Scrolling', 'Opening risky apps', 'Extending the ritual'];
      case CycleStage.shortLivedPleasure:
        return ['Relief', 'Escape', 'Numbing out', 'Temporary calm'];
      case CycleStage.shortLivedGuiltFear:
        return ['Shame', 'Regret', 'Fear of being caught', 'Feeling stuck'];
      case CycleStage.justifyingMakingItOkay:
        return ['“I already messed up”', '“One last time”', '“I’ll restart tomorrow”', '“It’s not a big deal”'];
    }
  }
}
EOD
cat > lib/features/cycle/presentation/cycle_screen.dart <<'EOD'
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../domain/cycle_stage.dart';

class CycleScreen extends StatelessWidget {
  const CycleScreen({super.key});

  void _showStageSheet(BuildContext context, CycleStage stage) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stage.title, style: AppTypography.title),
                const SizedBox(height: AppSpacing.sm),
                Text(stage.description, style: AppTypography.muted),
                const SizedBox(height: AppSpacing.lg),
                Text('Examples', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: stage.examples
                      .map((item) => Chip(label: Text(item)))
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: 'Log This Stage',
                  icon: Icons.add_task_outlined,
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${stage.title} log flow comes next.')),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, RouteNames.rescue);
                    },
                    icon: const Icon(Icons.health_and_safety_outlined),
                    label: const Text('Open Rescue'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cycle Wheel')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Recognize the cycle earlier.', style: AppTypography.title),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Tap any stage to explore it, reflect on it, and interrupt it faster.',
              style: AppTypography.muted,
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: _CycleWheel(
                onStageTap: (stage) => _showStageSheet(context, stage),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How to use this', style: AppTypography.section),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Use the wheel to name where you are before the cycle speeds up. '
                    'The earlier you spot the pattern, the easier it is to interrupt.',
                    style: AppTypography.muted,
                  ),
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

class _CycleWheel extends StatelessWidget {
  final ValueChanged<CycleStage> onStageTap;

  const _CycleWheel({
    required this.onStageTap,
  });

  @override
  Widget build(BuildContext context) {
    const double wheelSize = 360;
    const double bubbleSize = 84;
    const double radius = 128;
    const double center = wheelSize / 2;

    return SizedBox(
      width: wheelSize,
      height: wheelSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceAlt,
              border: Border.all(color: AppColors.divider),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: const Text(
              'Recovery\nCycle',
              textAlign: TextAlign.center,
              style: AppTypography.section,
            ),
          ),
          for (int index = 0; index < CycleStage.values.length; index++)
            _buildStageBubble(
              stage: CycleStage.values[index],
              index: index,
              bubbleSize: bubbleSize,
              center: center,
              radius: radius,
            ),
        ],
      ),
    );
  }

  Widget _buildStageBubble({
    required CycleStage stage,
    required int index,
    required double bubbleSize,
    required double center,
    required double radius,
  }) {
    final angle = (-math.pi / 2) + ((2 * math.pi) / CycleStage.values.length) * index;
    final left = center + radius * math.cos(angle) - (bubbleSize / 2);
    final top = center + radius * math.sin(angle) - (bubbleSize / 2);

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () => onStageTap(stage),
        child: Container(
          width: bubbleSize,
          height: bubbleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: AppColors.accent),
            boxShadow: const [
              BoxShadow(
                blurRadius: 10,
                spreadRadius: 0,
                offset: Offset(0, 4),
                color: Color(0x22000000),
              ),
            ],
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8),
          child: Text(
            stage.shortLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }
}
EOD

cat > lib/features/home/presentation/home_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import 'widgets/daily_quote_card.dart';
import 'widgets/quick_actions_row.dart';
import 'widgets/risk_status_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  Text('Recovery Cycle Wheel', style: AppTypography.section),
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
                      label: const Text('Open Rescue Now'),
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
  }
}
EOD
cat > tools/verify_ba02.py <<'EOD'
from pathlib import Path
import sys

REQUIRED = [
    'lib/core/constants/route_names.dart',
    'lib/app/app_router.dart',
    'lib/features/cycle/domain/cycle_stage.dart',
    'lib/features/cycle/presentation/cycle_screen.dart',
    'lib/features/home/presentation/home_screen.dart',
]

REQUIRED_TEXT = {
    'lib/core/constants/route_names.dart': "static const cycle = '/cycle';",
    'lib/app/app_router.dart': 'case RouteNames.cycle:',
    'lib/features/cycle/domain/cycle_stage.dart': 'enum CycleStage',
    'lib/features/cycle/presentation/cycle_screen.dart': 'class CycleScreen extends StatelessWidget',
    'lib/features/home/presentation/home_screen.dart': 'Open Cycle Wheel',
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

    print('Breakout Addiction BA-02 cycle scaffold verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
EOD

echo "==> BA-02 cycle scaffold written."
echo "==> Running Python verification..."
python3 tools/verify_ba02.py
