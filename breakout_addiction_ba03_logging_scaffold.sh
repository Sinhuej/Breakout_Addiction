#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

echo "==> Applying Breakout Addiction BA-03 logging scaffold in: $ROOT_DIR"

mkdir -p \
  lib/features/log/domain \
  lib/features/log/presentation \
  tools

cat > lib/core/constants/route_names.dart <<'EOD'
class RouteNames {
  static const home = '/';
  static const rescue = '/rescue';
  static const logHub = '/log';
  static const cycleStageLog = '/log/cycle-stage';
  static const insights = '/insights';
  static const support = '/support';
  static const cycle = '/cycle';
}
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
      case RouteNames.cycleStageLog:
        final stage = settings.arguments is CycleStage
            ? settings.arguments as CycleStage
            : CycleStage.triggers;
        return MaterialPageRoute(
          builder: (_) => _protect(
            scope: LockScope.logs,
            child: CycleStageLogScreen(initialStage: stage),
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
cat > lib/features/log/presentation/cycle_stage_log_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../cycle/domain/cycle_stage.dart';
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

  void _saveLog() {
    final entry = CycleStageLogEntry(
      timestamp: DateTime.now(),
      stage: _selectedStage,
      intensity: _intensity.round(),
      note: _noteController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Saved ${entry.stage.title} log at intensity ${entry.intensity}. Persistence comes next.',
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
              label: 'Save Stage Log',
              icon: Icons.save_outlined,
              onPressed: _saveLog,
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

class LogHubScreen extends StatelessWidget {
  const LogHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
      builder: (sheetContext) {
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
                    Navigator.pop(sheetContext);
                    Navigator.pushNamed(
                      context,
                      RouteNames.cycleStageLog,
                      arguments: stage,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
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

cat > tools/verify_ba03.py <<'EOD'
from pathlib import Path
import sys

REQUIRED = [
    'lib/core/constants/route_names.dart',
    'lib/app/app_router.dart',
    'lib/features/log/domain/cycle_stage_log_entry.dart',
    'lib/features/log/presentation/cycle_stage_log_screen.dart',
    'lib/features/log/presentation/log_hub_screen.dart',
    'lib/features/cycle/presentation/cycle_screen.dart',
]

REQUIRED_TEXT = {
    'lib/core/constants/route_names.dart': "static const cycleStageLog = '/log/cycle-stage';",
    'lib/app/app_router.dart': 'case RouteNames.cycleStageLog:',
    'lib/features/log/domain/cycle_stage_log_entry.dart': 'class CycleStageLogEntry',
    'lib/features/log/presentation/cycle_stage_log_screen.dart': 'class CycleStageLogScreen extends StatefulWidget',
    'lib/features/log/presentation/log_hub_screen.dart': 'Log Cycle Stage',
    'lib/features/cycle/presentation/cycle_screen.dart': 'RouteNames.cycleStageLog',
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

    print('Breakout Addiction BA-03 logging scaffold verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
EOD

echo "==> BA-03 logging scaffold written."
echo "==> Running Python verification..."
python3 tools/verify_ba03.py
