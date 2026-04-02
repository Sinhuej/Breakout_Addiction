#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

echo "==> Applying Breakout Addiction BA-33 widget/app-entry polish scaffold in: $ROOT_DIR"

mkdir -p \
  lib/features/widget/domain \
  lib/features/widget/data \
  lib/features/home/presentation/widgets \
  tools

cat > lib/features/widget/domain/app_entry_record.dart <<'EOD'
class AppEntryRecord {
  final String sourceKey;
  final String routeName;
  final String title;
  final String subtitle;
  final DateTime timestamp;

  const AppEntryRecord({
    required this.sourceKey,
    required this.routeName,
    required this.title,
    required this.subtitle,
    required this.timestamp,
  });

  factory AppEntryRecord.normal() {
    return AppEntryRecord(
      sourceKey: 'normal_open',
      routeName: '/',
      title: 'Normal App Open',
      subtitle: 'The app was opened normally.',
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'sourceKey': sourceKey,
      'routeName': routeName,
      'title': title,
      'subtitle': subtitle,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AppEntryRecord.fromMap(Map<String, dynamic> map) {
    return AppEntryRecord(
      sourceKey: (map['sourceKey'] as String?) ?? 'normal_open',
      routeName: (map['routeName'] as String?) ?? '/',
      title: (map['title'] as String?) ?? 'Normal App Open',
      subtitle: (map['subtitle'] as String?) ?? 'The app was opened normally.',
      timestamp: DateTime.tryParse((map['timestamp'] as String?) ?? '') ??
          DateTime.now(),
    );
  }

  bool get isWidgetEntry => sourceKey.startsWith('widget_');
}
EOD

cat > lib/features/widget/data/app_entry_repository.dart <<'EOD'
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/route_names.dart';
import '../domain/app_entry_record.dart';
import '../domain/widget_entry_action.dart';

class AppEntryRepository {
  static const String _pendingKey = 'pending_app_entry';
  static const String _lastKey = 'last_app_entry';

  AppEntryRecord _recordForAction(WidgetEntryAction action) {
    switch (action) {
      case WidgetEntryAction.openHome:
        return AppEntryRecord(
          sourceKey: 'widget_home',
          routeName: RouteNames.home,
          title: 'Widget Home Entry',
          subtitle: 'Opened Breakout from the home widget.',
          timestamp: DateTime.now(),
        );
      case WidgetEntryAction.openRescue:
        return AppEntryRecord(
          sourceKey: 'widget_rescue',
          routeName: RouteNames.rescue,
          title: 'Widget Rescue Entry',
          subtitle: 'Jumped straight into Rescue from the home widget.',
          timestamp: DateTime.now(),
        );
      case WidgetEntryAction.openMoodLog:
        return AppEntryRecord(
          sourceKey: 'widget_mood',
          routeName: RouteNames.moodLog,
          title: 'Widget Check-In Entry',
          subtitle: 'Started a quick mood check-in from the home widget.',
          timestamp: DateTime.now(),
        );
    }
  }

  Future<void> stageWidgetEntry(WidgetEntryAction action) async {
    final prefs = await SharedPreferences.getInstance();
    final record = _recordForAction(action);
    await prefs.setString(_pendingKey, jsonEncode(record.toMap()));
  }

  Future<AppEntryRecord?> consumePendingEntry() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final record = AppEntryRecord.fromMap(decoded);

    await prefs.remove(_pendingKey);
    await prefs.setString(_lastKey, jsonEncode(record.toMap()));

    return record;
  }

  Future<AppEntryRecord?> getLastEntry() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return AppEntryRecord.fromMap(decoded);
  }

  Future<void> clearLastEntry() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastKey);
  }
}
EOD
cat > lib/features/home/presentation/widgets/entry_status_card.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../widget/data/app_entry_repository.dart';
import '../../../widget/domain/app_entry_record.dart';

class EntryStatusCard extends StatefulWidget {
  const EntryStatusCard({super.key});

  @override
  State<EntryStatusCard> createState() => _EntryStatusCardState();
}

class _EntryStatusCardState extends State<EntryStatusCard> {
  final AppEntryRepository _repository = AppEntryRepository();
  AppEntryRecord? _entry;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entry = await _repository.getLastEntry();
    if (!mounted) {
      return;
    }
    setState(() {
      _entry = entry;
      _loading = false;
    });
  }

  Future<void> _dismiss() async {
    await _repository.clearLastEntry();
    if (!mounted) {
      return;
    }
    setState(() => _entry = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _entry == null || !_entry!.isWidgetEntry) {
      return const SizedBox.shrink();
    }

    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent App Entry', style: AppTypography.section),
          const SizedBox(height: AppSpacing.sm),
          Text(_entry!.title, style: AppTypography.body),
          const SizedBox(height: 6),
          Text(_entry!.subtitle, style: AppTypography.muted),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _dismiss,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Dismiss Entry Status'),
            ),
          ),
        ],
      ),
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
import '../data/app_entry_repository.dart';
import '../data/widget_snapshot_repository.dart';
import '../domain/widget_entry_action.dart';
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

  Future<void> _simulateEntry(
    BuildContext context,
    WidgetEntryAction action,
  ) async {
    final repository = AppEntryRepository();
    await repository.stageWidgetEntry(action);

    if (!context.mounted) {
      return;
    }

    Navigator.pushNamed(context, RouteNames.home);
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
                'Preview the widget content and simulate a tap path so app entry feels like a real quick-action flow.',
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
                      'This screen previews widget content from real app data. The simulate buttons stage a pending app-entry action and reopen the app flow through Home Entry.',
                      style: AppTypography.muted,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _compactWidgetPreview(data),
              const SizedBox(height: AppSpacing.md),
              _riskWidgetPreview(data),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () => _simulateEntry(context, WidgetEntryAction.openHome),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Simulate Widget → Open Breakout'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => _simulateEntry(context, WidgetEntryAction.openRescue),
                icon: const Icon(Icons.health_and_safety_outlined),
                label: const Text('Simulate Widget → Rescue'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => _simulateEntry(context, WidgetEntryAction.openMoodLog),
                icon: const Icon(Icons.mood_outlined),
                label: const Text('Simulate Widget → Log Check-In'),
              ),
            ],
          );
        },
      ),
    );
  }
}
EOD
cat > lib/features/onboarding/presentation/home_entry_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../core/constants/route_names.dart';
import '../../home/presentation/home_screen.dart';
import '../../widget/data/app_entry_repository.dart';
import '../data/onboarding_repository.dart';

class HomeEntryScreen extends StatefulWidget {
  const HomeEntryScreen({super.key});

  @override
  State<HomeEntryScreen> createState() => _HomeEntryScreenState();
}

class _HomeEntryScreenState extends State<HomeEntryScreen> {
  final OnboardingRepository _onboardingRepository = OnboardingRepository();
  final AppEntryRepository _appEntryRepository = AppEntryRepository();

  Widget? _child;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final state = await _onboardingRepository.getState();

    if (!mounted) {
      return;
    }

    if (!state.completed) {
      setState(() {
        _child = null;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        Navigator.pushReplacementNamed(context, RouteNames.onboarding);
      });
      return;
    }

    final pending = await _appEntryRepository.consumePendingEntry();

    if (!mounted) {
      return;
    }

    if (pending == null || pending.routeName == RouteNames.home) {
      setState(() {
        _child = const HomeScreen();
      });
      return;
    }

    setState(() {
      _child = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(context, pending.routeName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _child ??
        const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
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
import '../../settings/data/feature_control_settings_repository.dart';
import 'widgets/daily_quote_card.dart';
import 'widgets/entry_status_card.dart';
import 'widgets/home_hero_card.dart';
import 'widgets/premium_guidance_card.dart';
import 'widgets/progress_snapshot_card.dart';
import 'widgets/quick_actions_row.dart';
import 'widgets/risk_status_card.dart';
import 'widgets/startup_notice_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static bool _startupNoticeHandledThisSession = false;
  final FeatureControlSettingsRepository _settingsRepository =
      FeatureControlSettingsRepository();

  @override
  void initState() {
    super.initState();
    _maybeShowStartupNotice();
  }

  Future<void> _maybeShowStartupNotice() async {
    final settings = await _settingsRepository.getSettings();
    if (!mounted) {
      return;
    }

    if (!settings.showStartupNotice || _startupNoticeHandledThisSession) {
      return;
    }

    _startupNoticeHandledThisSession = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      var currentSettings = settings;

      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              return StartupNoticeSheet(
                showOnStartup: currentSettings.showStartupNotice,
                onShowOnStartupChanged: (value) async {
                  currentSettings =
                      currentSettings.copyWith(showStartupNotice: value);
                  await _settingsRepository.saveSettings(currentSettings);
                  setSheetState(() {});
                },
                onContinue: () {
                  Navigator.pop(sheetContext);
                },
                onOpenFeatureChoices: () {
                  Navigator.pop(sheetContext);
                  Navigator.pushNamed(context, RouteNames.featureControls);
                },
                onOpenSupport: () {
                  Navigator.pop(sheetContext);
                  Navigator.pushNamed(context, RouteNames.support);
                },
              );
            },
          );
        },
      );
    });
  }

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
            const EntryStatusCard(),
            const SizedBox(height: AppSpacing.md),
            const DailyQuoteCard(),
            const SizedBox(height: AppSpacing.md),
            const PremiumGuidanceCard(),
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
                    'Use Learn for deeper understanding, Support for your personal plan, and Widget Preview to test quick app-entry flows.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    label: 'Open Learn',
                    icon: Icons.menu_book_outlined,
                    onPressed: () => Navigator.pushNamed(
                      context,
                      RouteNames.educate,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        RouteNames.widgetPreview,
                      ),
                      icon: const Icon(Icons.widgets_outlined),
                      label: const Text('Open Widget Preview'),
                    ),
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

python3 - <<'EOD'
from pathlib import Path

support_path = Path('lib/features/support/presentation/support_screen.dart')
text = support_path.read_text(encoding='utf-8')

anchor = "PrimaryButton(\n                  label: 'Open Risk Windows',"
insert = """PrimaryButton(
                  label: 'Open Widget Preview',
                  icon: Icons.widgets_outlined,
                  onPressed: () => Navigator.pushNamed(
                    context,
                    RouteNames.widgetPreview,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                PrimaryButton(
                  label: 'Open Risk Windows',"""

if "label: 'Open Widget Preview'" not in text and anchor in text:
    text = text.replace(anchor, insert, 1)

support_path.write_text(text, encoding='utf-8')
print('Patched support_screen.dart')
EOD
cat > tools/verify_ba33.py <<'EOD'
from pathlib import Path
import sys

REQUIRED = [
    'lib/features/widget/domain/app_entry_record.dart',
    'lib/features/widget/data/app_entry_repository.dart',
    'lib/features/home/presentation/widgets/entry_status_card.dart',
    'lib/features/widget/presentation/widget_preview_screen.dart',
    'lib/features/onboarding/presentation/home_entry_screen.dart',
    'lib/features/home/presentation/home_screen.dart',
    'lib/features/support/presentation/support_screen.dart',
]

REQUIRED_TEXT = {
    'lib/features/widget/domain/app_entry_record.dart': 'class AppEntryRecord',
    'lib/features/widget/data/app_entry_repository.dart': 'stageWidgetEntry',
    'lib/features/home/presentation/widgets/entry_status_card.dart': 'Recent App Entry',
    'lib/features/widget/presentation/widget_preview_screen.dart': 'Simulate Widget → Rescue',
    'lib/features/onboarding/presentation/home_entry_screen.dart': 'consumePendingEntry',
    'lib/features/home/presentation/home_screen.dart': 'const EntryStatusCard()',
    'lib/features/support/presentation/support_screen.dart': "label: 'Open Widget Preview'",
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

    print('Breakout Addiction BA-33 widget/app-entry polish verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
EOD

echo "==> BA-33 widget/app-entry polish scaffold written."
echo "==> Running Python verification..."
python3 tools/verify_ba33.py
