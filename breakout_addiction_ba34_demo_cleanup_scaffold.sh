#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

echo "==> Applying Breakout Addiction BA-34 demo cleanup + test tightening scaffold in: $ROOT_DIR"

mkdir -p \
  lib/features/qa/domain \
  lib/features/qa/data \
  lib/features/home/presentation/widgets \
  tools

cat > lib/features/qa/domain/demo_readiness_snapshot.dart <<'EOD'
class DemoReadinessSnapshot {
  final String premiumPlanLabel;
  final bool remindersEnabled;
  final int riskWindowCount;
  final String aiModeLabel;
  final bool startupNoticeEnabled;
  final bool faithLayerEnabled;
  final String summaryLine;

  const DemoReadinessSnapshot({
    required this.premiumPlanLabel,
    required this.remindersEnabled,
    required this.riskWindowCount,
    required this.aiModeLabel,
    required this.startupNoticeEnabled,
    required this.faithLayerEnabled,
    required this.summaryLine,
  });
}
EOD

cat > lib/features/qa/data/demo_readiness_repository.dart <<'EOD'
import '../../ai_chat/data/ai_chat_settings_repository.dart';
import '../../premium/data/premium_access_repository.dart';
import '../../risk/data/risk_window_repository.dart';
import '../../settings/data/feature_control_settings_repository.dart';
import '../domain/demo_readiness_snapshot.dart';

class DemoReadinessRepository {
  final PremiumAccessRepository _premiumRepository =
      PremiumAccessRepository();
  final RiskWindowRepository _riskRepository = RiskWindowRepository();
  final AiChatSettingsRepository _aiSettingsRepository =
      AiChatSettingsRepository();
  final FeatureControlSettingsRepository _featureRepository =
      FeatureControlSettingsRepository();

  Future<DemoReadinessSnapshot> build() async {
    final premium = await _premiumRepository.getStatus();
    final riskWindows = await _riskRepository.getRiskWindows();
    final reminderSettings = await _riskRepository.getReminderSettings();
    final aiSettings = await _aiSettingsRepository.getSettings();
    final featureSettings = await _featureRepository.getSettings();

    final summaryLine = [
      premium.isUnlocked
          ? 'Premium active: ${premium.plan.label}.'
          : 'Free tier active.',
      reminderSettings.remindersEnabled
          ? 'Live reminders enabled.'
          : 'Live reminders disabled.',
      'AI mode: ${aiSettings.providerMode.label}.',
    ].join(' ');

    return DemoReadinessSnapshot(
      premiumPlanLabel: premium.plan.label,
      remindersEnabled: reminderSettings.remindersEnabled,
      riskWindowCount: riskWindows.length,
      aiModeLabel: aiSettings.providerMode.label,
      startupNoticeEnabled: featureSettings.showStartupNotice,
      faithLayerEnabled: featureSettings.faithLayerEnabled,
      summaryLine: summaryLine,
    );
  }
}
EOD
cat > lib/features/home/presentation/widgets/demo_readiness_card.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../qa/data/demo_readiness_repository.dart';
import '../../../qa/domain/demo_readiness_snapshot.dart';

class DemoReadinessCard extends StatelessWidget {
  const DemoReadinessCard({super.key});

  Widget _chip(String label) {
    return Chip(label: Text(label));
  }

  @override
  Widget build(BuildContext context) {
    final repository = DemoReadinessRepository();

    return FutureBuilder<DemoReadinessSnapshot>(
      future: repository.build(),
      builder: (context, snapshot) {
        final data = snapshot.data;

        if (data == null) {
          return const InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Demo Readiness', style: AppTypography.section),
                SizedBox(height: AppSpacing.sm),
                Text('Loading app state...', style: AppTypography.muted),
              ],
            ),
          );
        }

        return InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Demo Readiness', style: AppTypography.section),
              const SizedBox(height: AppSpacing.sm),
              Text(data.summaryLine, style: AppTypography.muted),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip('Plan: ${data.premiumPlanLabel}'),
                  _chip('Risk windows: ${data.riskWindowCount}'),
                  _chip(data.remindersEnabled ? 'Reminders on' : 'Reminders off'),
                  _chip('AI: ${data.aiModeLabel}'),
                  _chip(data.startupNoticeEnabled
                      ? 'Startup notice on'
                      : 'Startup notice off'),
                  _chip(data.faithLayerEnabled
                      ? 'Faith layer on'
                      : 'Faith layer off'),
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
cat > lib/features/home/presentation/home_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../settings/data/feature_control_settings_repository.dart';
import 'widgets/daily_quote_card.dart';
import 'widgets/demo_readiness_card.dart';
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
            const DemoReadinessCard(),
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
                    'Use Learn for deeper understanding, Support for your plan, and Widget Preview for quick-entry demo flows.',
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

needle = "Text('Feature Choices', style: AppTypography.section),"
replacement = """Text('Feature Choices', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'These controls make it easy to demo local-only behavior, reminders, widget entry, or the optional AI layer without guessing what is turned on.',
                  style: AppTypography.muted,
                ),
                const SizedBox(height: AppSpacing.sm),"""

if needle in text and 'These controls make it easy to demo local-only behavior' not in text:
    text = text.replace(needle, replacement, 1)

if "label: 'Open AI Recovery Coach'" not in text and "label: 'Open Widget Preview'" in text:
    text = text.replace(
        "PrimaryButton(\n                  label: 'Open Widget Preview',",
        "PrimaryButton(\n                  label: 'Open AI Recovery Coach',\n                  icon: Icons.psychology_outlined,\n                  onPressed: () => Navigator.pushNamed(\n                    context,\n                    RouteNames.aiChat,\n                  ),\n                ),\n                const SizedBox(height: AppSpacing.sm),\n                PrimaryButton(\n                  label: 'Open Widget Preview',",
        1,
    )

support_path.write_text(text, encoding='utf-8')
print('Patched support_screen.dart')
EOD
cat > test/widget_test.dart <<'EOD'
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakout_addiction/app/breakout_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  final Map<String, String> secureStorage = <String, String>{};

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'feature_show_startup_notice': false,
      'premium_plan': 'plus',
      'premium_upgrade_prompts': true,
      'feature_faith_layer_enabled': true,
      'feature_ai_chat_enabled': true,
      'feature_ai_guidance_enabled': true,
      'feature_remote_ai_enabled': false,
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (MethodCall call) async {
      switch (call.method) {
        case 'read':
          final String key = call.arguments['key'] as String;
          return secureStorage[key];
        case 'write':
          final String key = call.arguments['key'] as String;
          final String value = call.arguments['value'] as String;
          secureStorage[key] = value;
          return null;
        case 'delete':
          final String key = call.arguments['key'] as String;
          secureStorage.remove(key);
          return null;
        case 'deleteAll':
          secureStorage.clear();
          return null;
        case 'containsKey':
          final String key = call.arguments['key'] as String;
          return secureStorage.containsKey(key);
        case 'readAll':
          return secureStorage;
        default:
          return null;
      }
    });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
    secureStorage.clear();
  });

  testWidgets('BreakoutApp renders polished home shell', (WidgetTester tester) async {
    await tester.pumpWidget(const BreakoutApp());
    await tester.pumpAndSettle();

    expect(find.text('Breakout Addiction'), findsOneWidget);
    expect(find.text('Break the cycle earlier.'), findsOneWidget);
    expect(find.text('Demo Readiness'), findsOneWidget);
    expect(find.text('Local Premium Guidance'), findsOneWidget);
  });
}
EOD

cat > tools/run_demo_quality_checks.sh <<'EOD'
#!/usr/bin/env bash
set -u

echo "==> Breakout demo quality checks"

PASS=0
FAIL=0

run_check() {
  local label="$1"
  shift
  echo
  echo "--> $label"
  if "$@"; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
  fi
}

for script in \
  tools/verify_ba28.py \
  tools/verify_ba29.py \
  tools/verify_ba30.py \
  tools/verify_ba31.py \
  tools/verify_ba32.py \
  tools/verify_ba33.py \
  tools/verify_ba34.py
do
  if [ -f "$script" ]; then
    run_check "$script" python3 "$script"
  fi
done

if command -v flutter >/dev/null 2>&1; then
  run_check "flutter analyze --no-fatal-infos" flutter analyze --no-fatal-infos
  run_check "flutter test" flutter test
else
  echo
  echo "--> flutter not found in PATH; skipped analyze/test"
fi

echo
echo "==> Checks complete: PASS=$PASS FAIL=$FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
EOD

chmod +x tools/run_demo_quality_checks.sh
cat > tools/verify_ba34.py <<'EOD'
from pathlib import Path
import sys

REQUIRED = [
    'lib/features/qa/domain/demo_readiness_snapshot.dart',
    'lib/features/qa/data/demo_readiness_repository.dart',
    'lib/features/home/presentation/widgets/demo_readiness_card.dart',
    'lib/features/home/presentation/home_screen.dart',
    'lib/features/support/presentation/support_screen.dart',
    'test/widget_test.dart',
    'tools/run_demo_quality_checks.sh',
]

REQUIRED_TEXT = {
    'lib/features/qa/domain/demo_readiness_snapshot.dart': 'class DemoReadinessSnapshot',
    'lib/features/qa/data/demo_readiness_repository.dart': 'summaryLine = [',
    'lib/features/home/presentation/widgets/demo_readiness_card.dart': 'Demo Readiness',
    'lib/features/home/presentation/home_screen.dart': 'const DemoReadinessCard()',
    'lib/features/support/presentation/support_screen.dart': "label: 'Open AI Recovery Coach'",
    'test/widget_test.dart': 'BreakoutApp renders polished home shell',
    'tools/run_demo_quality_checks.sh': 'flutter analyze --no-fatal-infos',
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

    print('Breakout Addiction BA-34 demo cleanup and test tightening verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
EOD

echo "==> BA-34 demo cleanup scaffold written."
echo "==> Running Python verification..."
python3 tools/verify_ba34.py
