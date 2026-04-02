#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

echo "==> Applying Breakout Addiction BA-22 UI polish scaffold in: $ROOT_DIR"

mkdir -p \
  lib/features/home/presentation/widgets \
  tools

cat > lib/app/theme/app_theme.dart <<'EOD'
import 'package:flutter/material.dart';

import 'app_colors.dart';

ThemeData buildBreakoutTheme() {
  final base = ThemeData.dark(useMaterial3: true);

  OutlineInputBorder border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color),
    );
  }

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: base.colorScheme.copyWith(
      surface: AppColors.surface,
      primary: AppColors.accent,
      secondary: AppColors.accentSoft,
      error: AppColors.danger,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.divider),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceAlt,
      border: border(AppColors.divider),
      enabledBorder: border(AppColors.divider),
      focusedBorder: border(AppColors.accent),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textSecondary),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.divider),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.surfaceAlt,
      side: const BorderSide(color: AppColors.divider),
      labelStyle: const TextStyle(color: AppColors.textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    ),
  );
}
EOD

cat > lib/features/home/presentation/widgets/home_hero_card.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/privacy/neutral_labels.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../privacy/data/privacy_label_repository.dart';

class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = PrivacyLabelRepository();

    return FutureBuilder<bool>(
      future: repository.isNeutralModeEnabled(),
      builder: (context, snapshot) {
        final neutralMode = snapshot.data ?? true;

        return InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Break the cycle earlier.', style: AppTypography.title),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'The goal is not perfection. The goal is to recognize the pattern sooner and interrupt it faster.',
                style: AppTypography.muted,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  Chip(label: Text('Private')),
                  Chip(label: Text('Action-focused')),
                  Chip(label: Text('Recovery-first')),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: NeutralLabels.rescuePrimary(neutralMode),
                icon: Icons.health_and_safety_outlined,
                onPressed: () => Navigator.pushNamed(context, RouteNames.rescue),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, RouteNames.cycle),
                  icon: const Icon(Icons.donut_large_outlined),
                  label: const Text('Open Cycle Wheel'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
EOD
cat > lib/features/home/presentation/widgets/progress_snapshot_card.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../log/data/cycle_stage_log_repository.dart';
import '../../../log/data/mood_log_repository.dart';
import '../../../log/data/recovery_event_repository.dart';
import '../../../log/domain/recovery_event_entry.dart';

class ProgressSnapshotCard extends StatelessWidget {
  const ProgressSnapshotCard({super.key});

  Future<Map<String, int>> _load() async {
    final moods = await MoodLogRepository().getEntries();
    final stages = await CycleStageLogRepository().getEntries();
    final events = await RecoveryEventRepository().getEntries();

    final victories = events.where((e) => e.type == RecoveryEventType.victory).length;
    final urges = events.where((e) => e.type == RecoveryEventType.urge).length;

    return <String, int>{
      'moods': moods.length,
      'stages': stages.length,
      'urges': urges,
      'victories': victories,
    };
  }

  Widget _chip(String label) {
    return Chip(label: Text(label));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _load(),
      builder: (context, snapshot) {
        final data = snapshot.data ??
            <String, int>{
              'moods': 0,
              'stages': 0,
              'urges': 0,
              'victories': 0,
            };

        return InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Progress Snapshot', style: AppTypography.section),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Small honest check-ins make the whole app smarter.',
                style: AppTypography.muted,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip('Mood logs: ${data['moods']}'),
                  _chip('Stage logs: ${data['stages']}'),
                  _chip('Urges: ${data['urges']}'),
                  _chip('Victories: ${data['victories']}'),
                ],
              ),
            ],
          ),
        );
      },
    );
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

  Widget _fullButton({
    required Widget child,
  }) {
    return SizedBox(
      width: double.infinity,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = PrivacyLabelRepository();

    return FutureBuilder<bool>(
      future: repository.isNeutralModeEnabled(),
      builder: (context, snapshot) {
        final neutralMode = snapshot.data ?? true;

        return InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Quick Actions'),
              const SizedBox(height: 12),
              _fullButton(
                child: FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(context, RouteNames.rescue),
                  icon: const Icon(Icons.health_and_safety_outlined),
                  label: Text(NeutralLabels.rescuePrimary(neutralMode)),
                ),
              ),
              const SizedBox(height: 12),
              _fullButton(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, RouteNames.moodLog),
                  icon: const Icon(Icons.mood_outlined),
                  label: Text(NeutralLabels.moodLog(neutralMode)),
                ),
              ),
              const SizedBox(height: 12),
              _fullButton(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, RouteNames.support),
                  icon: const Icon(Icons.support_agent_outlined),
                  label: Text(NeutralLabels.supportAction(neutralMode)),
                ),
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
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
import 'widgets/daily_quote_card.dart';
import 'widgets/home_hero_card.dart';
import 'widgets/progress_snapshot_card.dart';
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
            const HomeHeroCard(),
            const SizedBox(height: AppSpacing.md),
            const DailyQuoteCard(),
            const SizedBox(height: AppSpacing.md),
            const RiskStatusCard(),
            const SizedBox(height: AppSpacing.md),
            const QuickActionsRow(),
            const SizedBox(height: AppSpacing.md),
            const ProgressSnapshotCard(),
            const SizedBox(height: AppSpacing.md),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Keep Building'),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Use Learn for deeper understanding and Support for your personal plan, privacy settings, and risk windows.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    label: 'Open Learn',
                    icon: Icons.menu_book_outlined,
                    onPressed: () => Navigator.pushNamed(context, RouteNames.educate),
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
cat > tools/verify_ba22.py <<'EOD'
from pathlib import Path
import sys

REQUIRED = [
    'lib/app/theme/app_theme.dart',
    'lib/features/home/presentation/widgets/home_hero_card.dart',
    'lib/features/home/presentation/widgets/progress_snapshot_card.dart',
    'lib/features/home/presentation/widgets/quick_actions_row.dart',
    'lib/features/home/presentation/home_screen.dart',
]

REQUIRED_TEXT = {
    'lib/app/theme/app_theme.dart': 'filledButtonTheme',
    'lib/features/home/presentation/widgets/home_hero_card.dart': 'Open Cycle Wheel',
    'lib/features/home/presentation/widgets/progress_snapshot_card.dart': 'Progress Snapshot',
    'lib/features/home/presentation/widgets/quick_actions_row.dart': 'Quick Actions',
    'lib/features/home/presentation/home_screen.dart': 'const HomeHeroCard()',
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

    print('Breakout Addiction BA-22 UI polish verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
EOD

echo "==> BA-22 UI polish scaffold written."
echo "==> Running Python verification..."
python3 tools/verify_ba22.py
