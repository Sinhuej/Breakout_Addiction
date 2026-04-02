#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

echo "==> Applying Breakout Addiction BA-17 widget implementation scaffold in: $ROOT_DIR"

mkdir -p \
  lib/features/widget/domain \
  lib/features/widget/data \
  lib/features/widget/presentation \
  android_widget_overlay/app/src/main/res/layout \
  android_widget_overlay/app/src/main/res/xml \
  android_widget_overlay/app/src/main/kotlin/com/example/breakout_addiction \
  tools

cat > lib/core/constants/route_names.dart <<'EOD'
class RouteNames {
  static const home = '/';
  static const onboarding = '/onboarding';
  static const rescue = '/rescue';
  static const logHub = '/log';
  static const moodLog = '/log/mood';
  static const cycleStageLog = '/log/cycle-stage';
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

cat > lib/features/widget/domain/widget_snapshot.dart <<'EOD'
class WidgetSnapshot {
  final bool neutralMode;
  final String homeLabel;
  final String rescueLabel;
  final String moodLabel;
  final String dailyFocusTitle;
  final String dailyFocusSubtitle;
  final String riskLabel;

  const WidgetSnapshot({
    required this.neutralMode,
    required this.homeLabel,
    required this.rescueLabel,
    required this.moodLabel,
    required this.dailyFocusTitle,
    required this.dailyFocusSubtitle,
    required this.riskLabel,
  });
}
EOD

cat > lib/features/widget/data/widget_snapshot_repository.dart <<'EOD'
import '../../../core/privacy/neutral_labels.dart';
import '../../home/presentation/widgets/risk_status_card.dart' as risk_helper;
import '../../log/data/mood_log_repository.dart';
import '../../log/domain/mood_entry.dart';
import '../../privacy/data/privacy_label_repository.dart';
import '../../quotes/data/daily_quote_repository.dart';
import '../domain/widget_snapshot.dart';

class WidgetSnapshotRepository {
  final PrivacyLabelRepository _privacyRepository = PrivacyLabelRepository();
  final DailyQuoteRepository _quoteRepository = DailyQuoteRepository();
  final MoodLogRepository _moodRepository = MoodLogRepository();

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
    if (pressure >= 21) return 'High Risk';
    if (pressure >= 16) return 'Elevated';
    if (pressure >= 10) return 'Guarded';
    return 'Low Risk';
  }

  Future<WidgetSnapshot> buildSnapshot() async {
    final neutralMode = await _privacyRepository.isNeutralModeEnabled();
    final quote = await _quoteRepository.getTodayQuote();
    final moods = await _moodRepository.getEntries();

    return WidgetSnapshot(
      neutralMode: neutralMode,
      homeLabel: NeutralLabels.widgetHome(neutralMode),
      rescueLabel: NeutralLabels.widgetRescue(neutralMode),
      moodLabel: NeutralLabels.widgetMood(neutralMode),
      dailyFocusTitle: quote.text,
      dailyFocusSubtitle: quote.focusLine,
      riskLabel: _riskLabel(moods),
    );
  }
}
EOD
cat > lib/features/widget/presentation/widget_preview_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../data/widget_snapshot_repository.dart';
import '../domain/widget_snapshot.dart';

class WidgetPreviewScreen extends StatelessWidget {
  const WidgetPreviewScreen({super.key});

  Widget _actionChip(String label) {
    return Chip(label: Text(label));
  }

  Widget _compactWidgetPreview(WidgetSnapshot snapshot) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF151B23),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF263041)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Breakout', style: AppTypography.section),
          const SizedBox(height: AppSpacing.sm),
          Text(snapshot.dailyFocusTitle, style: AppTypography.body),
          const SizedBox(height: 6),
          Text(snapshot.dailyFocusSubtitle, style: AppTypography.muted),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _actionChip(snapshot.homeLabel),
              _actionChip(snapshot.rescueLabel),
              _actionChip(snapshot.moodLabel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _riskWidgetPreview(WidgetSnapshot snapshot) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF151B23),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF263041)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Risk Snapshot', style: AppTypography.section),
          const SizedBox(height: AppSpacing.sm),
          Chip(label: Text(snapshot.riskLabel)),
          const SizedBox(height: 8),
          Text(
            snapshot.neutralMode
                ? 'Privacy-safe wording is active for widget labels.'
                : 'Standard wording is active for widget labels.',
            style: AppTypography.muted,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = WidgetSnapshotRepository();

    return Scaffold(
      appBar: AppBar(title: const Text('Widget Preview')),
      body: FutureBuilder<WidgetSnapshot>(
        future: repository.buildSnapshot(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(
              child: Text('Unable to load widget preview.'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text('Home Screen Widget', style: AppTypography.title),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Preview the compact widget cards and use the Android overlay pack when you are ready to wire native files.',
                style: AppTypography.muted,
              ),
              const SizedBox(height: AppSpacing.lg),
              const InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How this works', style: AppTypography.section),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'This screen previews the widget content from real app data. The Android-specific files are staged in android_widget_overlay/ so your repo stays safe.',
                      style: AppTypography.muted,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _compactWidgetPreview(data),
              const SizedBox(height: AppSpacing.md),
              _riskWidgetPreview(data),
            ],
          );
        },
      ),
    );
  }
}
EOD

cat > android_widget_overlay/README_WIDGET_SETUP.md <<'EOD'
Breakout Addiction Android Widget Overlay
========================================

This folder contains safe Android widget files staged OUTSIDE the live android/
tree so the repo does not break when local android platform files are absent.

When you are ready and the real android/ folder exists in the repo, copy these
files into the matching android/app/src/main/... paths.

Files included:
- res/layout/breakout_widget_compact.xml
- res/xml/breakout_widget_info.xml
- kotlin/com/example/breakout_addiction/BreakoutWidgetProvider.kt
EOD

cat > android_widget_overlay/app/src/main/res/layout/breakout_widget_compact.xml <<'EOD'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:orientation="vertical"
    android:padding="16dp"
    android:background="#151B23">

    <TextView
        android:id="@+id/widget_title"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Breakout"
        android:textSize="16sp"
        android:textStyle="bold"
        android:textColor="#F5F7FA" />

    <TextView
        android:id="@+id/widget_focus"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginTop="8dp"
        android:text="Daily Focus"
        android:textColor="#F5F7FA" />

    <TextView
        android:id="@+id/widget_subfocus"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginTop="4dp"
        android:text="Catch the cycle earlier."
        android:textColor="#9AA4B2" />
</LinearLayout>
EOD

cat > android_widget_overlay/app/src/main/res/xml/breakout_widget_info.xml <<'EOD'
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="180dp"
    android:minHeight="110dp"
    android:updatePeriodMillis="0"
    android:initialLayout="@layout/breakout_widget_compact"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen" />
EOD

cat > android_widget_overlay/app/src/main/kotlin/com/example/breakout_addiction/BreakoutWidgetProvider.kt <<'EOD'
package com.example.breakout_addiction

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

class BreakoutWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.breakout_widget_compact)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
EOD

python3 - <<'EOD'
from pathlib import Path

support_path = Path('lib/features/support/presentation/support_screen.dart')
support_text = support_path.read_text(encoding='utf-8')

marker = """          const SizedBox(height: AppSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Privacy & Lock Mode', style: AppTypography.section),
"""

insert = """          const SizedBox(height: AppSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Home Screen Widget', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Preview the widget content and keep the Android widget overlay files ready for later native wiring.',
                  style: AppTypography.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Open Widget Preview',
                  icon: Icons.widgets_outlined,
                  onPressed: () => Navigator.pushNamed(
                    context,
                    RouteNames.widgetPreview,
                  ),
                ),
              ],
            ),
          ),
""" + marker

if "Text('Home Screen Widget'" not in support_text:
    support_text = support_text.replace(marker, insert)

support_path.write_text(support_text, encoding='utf-8')
print('Patched support_screen.dart')
EOD
python3 - <<'EOD'
from pathlib import Path

router_path = Path('lib/app/app_router.dart')
router_text = router_path.read_text(encoding='utf-8')

if "import '../features/widget/presentation/widget_preview_screen.dart';" not in router_text:
    router_text = router_text.replace(
        "import '../features/support/presentation/support_screen.dart';\n",
        "import '../features/support/presentation/support_screen.dart';\nimport '../features/widget/presentation/widget_preview_screen.dart';\n",
    )

if "case RouteNames.widgetPreview:" not in router_text:
    router_text = router_text.replace(
        "      case RouteNames.support:\n",
        "      case RouteNames.widgetPreview:\n"
        "        return MaterialPageRoute(\n"
        "          builder: (_) => const ProtectedRouteGate(\n"
        "            scope: LockScope.support,\n"
        "            child: WidgetPreviewScreen(),\n"
        "          ),\n"
        "        );\n"
        "      case RouteNames.support:\n",
    )

router_path.write_text(router_text, encoding='utf-8')
print('Patched app_router.dart')
EOD

cat > tools/verify_ba17.py <<'EOD'
from pathlib import Path
import sys

REQUIRED = [
    'lib/core/constants/route_names.dart',
    'lib/features/widget/domain/widget_snapshot.dart',
    'lib/features/widget/data/widget_snapshot_repository.dart',
    'lib/features/widget/presentation/widget_preview_screen.dart',
    'lib/features/support/presentation/support_screen.dart',
    'lib/app/app_router.dart',
    'android_widget_overlay/README_WIDGET_SETUP.md',
    'android_widget_overlay/app/src/main/res/layout/breakout_widget_compact.xml',
    'android_widget_overlay/app/src/main/res/xml/breakout_widget_info.xml',
    'android_widget_overlay/app/src/main/kotlin/com/example/breakout_addiction/BreakoutWidgetProvider.kt',
]

REQUIRED_TEXT = {
    'lib/core/constants/route_names.dart': "static const widgetPreview = '/widget-preview';",
    'lib/features/widget/domain/widget_snapshot.dart': 'class WidgetSnapshot',
    'lib/features/widget/data/widget_snapshot_repository.dart': 'class WidgetSnapshotRepository',
    'lib/features/widget/presentation/widget_preview_screen.dart': 'Widget Preview',
    'lib/features/support/presentation/support_screen.dart': 'Home Screen Widget',
    'lib/app/app_router.dart': 'case RouteNames.widgetPreview:',
    'android_widget_overlay/README_WIDGET_SETUP.md': 'Android Widget Overlay',
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

    print('Breakout Addiction BA-17 widget implementation verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
EOD

echo "==> BA-17 widget implementation scaffold written."
echo "==> Running Python verification..."
python3 tools/verify_ba17.py
