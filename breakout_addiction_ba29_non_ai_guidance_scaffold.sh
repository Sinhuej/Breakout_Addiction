#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

echo "==> Applying Breakout Addiction BA-29 non-AI premium guidance scaffold in: $ROOT_DIR"

mkdir -p \
  lib/features/guidance/domain \
  lib/features/guidance/data \
  lib/features/home/presentation/widgets \
  tools

cat > lib/features/guidance/domain/local_guidance_snapshot.dart <<'EOD'
class LocalGuidanceSnapshot {
  final bool isUnlocked;
  final String title;
  final String body;
  final String actionLine;
  final String packLabel;
  final String footerLine;

  const LocalGuidanceSnapshot({
    required this.isUnlocked,
    required this.title,
    required this.body,
    required this.actionLine,
    required this.packLabel,
    required this.footerLine,
  });

  factory LocalGuidanceSnapshot.locked() {
    return const LocalGuidanceSnapshot(
      isUnlocked: false,
      title: 'Local Premium Guidance',
      body:
          'Breakout Plus includes curated local guidance and faith-sensitive packs without AI chat.',
      actionLine: 'Upgrade to Breakout Plus to unlock premium local guidance.',
      packLabel: 'Locked',
      footerLine: 'You can still use the core app without AI.',
    );
  }
}
EOD
cat > lib/features/guidance/data/local_guidance_repository.dart <<'EOD'
import '../domain/local_guidance_snapshot.dart';

class LocalGuidanceRepository {
  const LocalGuidanceRepository();

  LocalGuidanceSnapshot resetPack() {
    return const LocalGuidanceSnapshot(
      isUnlocked: true,
      title: 'Reset the Window Earlier',
      body:
          'A premium local pack for the moments when the pattern is just beginning. The goal is not to win a huge battle. The goal is to shorten the window where the ritual can grow.',
      actionLine:
          'Stand up, change rooms, and do one physical interruption before you negotiate with yourself.',
      packLabel: 'Breakout Plus Pack',
      footerLine:
          'Local guidance stays available even if you never use AI.',
    );
  }

  LocalGuidanceSnapshot stressPack() {
    return const LocalGuidanceSnapshot(
      isUnlocked: true,
      title: 'Pressure Is Not the Same as Desire',
      body:
          'When stress is high, the habit can masquerade as relief. This pack helps you treat pressure as pressure instead of mislabeling it as desire.',
      actionLine:
          'Name the pressure honestly, lower stimulation, and do one body-level reset before you make any private decision.',
      packLabel: 'Pressure Reset Pack',
      footerLine:
          'Strong premium guidance does not have to depend on AI.',
    );
  }

  LocalGuidanceSnapshot lonelinessPack() {
    return const LocalGuidanceSnapshot(
      isUnlocked: true,
      title: 'Break Isolation Fast',
      body:
          'Loneliness can make the ritual feel like comfort. This pack is built to move you toward connection, visibility, and interruption before the urge gains speed.',
      actionLine:
          'Use one human-contact move now: text someone, leave the room, or move into a less isolated setting.',
      packLabel: 'Connection Pack',
      footerLine:
          'Local premium packs can still feel personal when they are pattern-aware.',
    );
  }

  LocalGuidanceSnapshot boredomPack() {
    return const LocalGuidanceSnapshot(
      isUnlocked: true,
      title: 'Boredom Loves an Empty Loop',
      body:
          'Boredom often creates the quiet setup that lets the cycle start. This pack helps you replace low-friction drift with structured movement.',
      actionLine:
          'Create friction quickly: leave the phone, switch locations, and choose a short active task with a visible finish line.',
      packLabel: 'Momentum Pack',
      footerLine:
          'Premium local guidance can be simple, direct, and effective.',
    );
  }

  LocalGuidanceSnapshot faithPack(String religion) {
    if (religion == 'Christian') {
      return const LocalGuidanceSnapshot(
        isUnlocked: true,
        title: 'Grace Is Still Here',
        body:
            'Grace is not gone because the day got hard. This pack is built for the moments when shame tries to convince you to withdraw instead of return.',
        actionLine:
            'Come back to honesty, take one clean next step, and remember that falling into shame is not the same as moving toward healing.',
        packLabel: 'Christian Faith Pack',
        footerLine:
            'This is a local faith-sensitive pack. It does not require AI chat.',
      );
    }

    return const LocalGuidanceSnapshot(
      isUnlocked: true,
      title: 'Return to What Is Good',
      body:
          'This faith-sensitive pack is designed to help you slow down, remember your values, and move toward peace instead of secrecy.',
      actionLine:
          'Pause, breathe, and choose the next action that matches the person you want to become.',
      packLabel: 'Faith-Sensitive Pack',
      footerLine:
          'Faith-sensitive premium packs can stay local and private.',
    );
  }
}
EOD

cat > lib/features/guidance/data/local_guidance_service.dart <<'EOD'
import '../../log/data/mood_log_repository.dart';
import '../../premium/data/premium_access_repository.dart';
import '../../quotes/data/quote_preferences_repository.dart';
import '../../quotes/domain/daily_quote.dart';
import '../../settings/data/feature_control_settings_repository.dart';
import '../domain/local_guidance_snapshot.dart';
import 'local_guidance_repository.dart';

class LocalGuidanceService {
  final PremiumAccessRepository _premiumRepository =
      PremiumAccessRepository();
  final FeatureControlSettingsRepository _featureRepository =
      FeatureControlSettingsRepository();
  final QuotePreferencesRepository _quotePreferences =
      QuotePreferencesRepository();
  final MoodLogRepository _moodRepository = MoodLogRepository();
  final LocalGuidanceRepository _repository = const LocalGuidanceRepository();

  Future<LocalGuidanceSnapshot> buildSnapshot() async {
    final premium = await _premiumRepository.getStatus();
    if (!premium.hasPremium) {
      return LocalGuidanceSnapshot.locked();
    }

    final featureSettings = await _featureRepository.getSettings();
    final quoteMode = await _quotePreferences.getMode();
    final religion = await _quotePreferences.getReligionTag();
    final moods = await _moodRepository.getEntries();

    if (featureSettings.faithLayerEnabled && quoteMode == QuoteMode.faith) {
      return _repository.faithPack(religion);
    }

    if (moods.isEmpty) {
      return _repository.resetPack();
    }

    final recent = moods.first;
    final scores = <String, int>{
      'stress': recent.stress,
      'loneliness': recent.loneliness,
      'boredom': recent.boredom,
    };

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    switch (sorted.first.key) {
      case 'stress':
        return _repository.stressPack();
      case 'loneliness':
        return _repository.lonelinessPack();
      case 'boredom':
        return _repository.boredomPack();
      default:
        return _repository.resetPack();
    }
  }
}
EOD
cat > lib/features/home/presentation/widgets/premium_guidance_card.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../guidance/data/local_guidance_service.dart';
import '../../../guidance/domain/local_guidance_snapshot.dart';

class PremiumGuidanceCard extends StatelessWidget {
  const PremiumGuidanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final service = LocalGuidanceService();

    return FutureBuilder<LocalGuidanceSnapshot>(
      future: service.buildSnapshot(),
      builder: (context, snapshot) {
        final guidance = snapshot.data ?? LocalGuidanceSnapshot.locked();

        return InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Local Premium Guidance', style: AppTypography.section),
              const SizedBox(height: AppSpacing.sm),
              Chip(label: Text(guidance.packLabel)),
              const SizedBox(height: AppSpacing.sm),
              Text(guidance.title, style: AppTypography.title),
              const SizedBox(height: 8),
              Text(guidance.body, style: AppTypography.body),
              const SizedBox(height: AppSpacing.sm),
              Text(guidance.actionLine, style: AppTypography.muted),
              const SizedBox(height: AppSpacing.sm),
              Text(guidance.footerLine, style: AppTypography.muted),
              const SizedBox(height: AppSpacing.md),
              if (guidance.isUnlocked)
                PrimaryButton(
                  label: 'Open Support',
                  icon: Icons.support_agent_outlined,
                  onPressed: () => Navigator.pushNamed(
                    context,
                    RouteNames.support,
                  ),
                )
              else
                PrimaryButton(
                  label: 'Open Premium',
                  icon: Icons.workspace_premium_outlined,
                  onPressed: () => Navigator.pushNamed(
                    context,
                    RouteNames.premium,
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
import '../../settings/data/feature_control_settings_repository.dart';
import '../../settings/domain/feature_control_settings.dart';
import 'widgets/daily_quote_card.dart';
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
                    'Use Learn for deeper understanding and Support for your personal plan, privacy settings, premium choices, and feature controls.',
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

premium_path = Path('lib/features/premium/presentation/premium_screen.dart')
premium_text = premium_path.read_text(encoding='utf-8')
premium_text = premium_text.replace(
    "Premium app experience without AI chat. Strong local-first premium path.",
    "Breakout Plus includes local premium guidance, deeper quotes, and faith-sensitive packs without AI chat.",
)
premium_text = premium_text.replace(
    "Everything in Plus, plus optional AI guidance and chat features.",
    "Everything in Plus, plus optional AI guidance, AI quotes, AI faith-sensitive help, and AI chat features.",
)
premium_path.write_text(premium_text, encoding='utf-8')
print("Patched premium_screen.dart")

support_path = Path('lib/features/support/presentation/support_screen.dart')
support_text = support_path.read_text(encoding='utf-8')
support_text = support_text.replace(
    "Breakout Plus gives a premium app experience without AI chat. Breakout Plus AI adds optional AI features.",
    "Breakout Plus gives curated local guidance and faith-sensitive packs without AI chat. Breakout Plus AI adds optional AI features later.",
)
support_path.write_text(support_text, encoding='utf-8')
print("Patched support_screen.dart")
EOD
cat > tools/verify_ba29.py <<'EOD'
from pathlib import Path
import sys

REQUIRED = [
    'lib/features/guidance/domain/local_guidance_snapshot.dart',
    'lib/features/guidance/data/local_guidance_repository.dart',
    'lib/features/guidance/data/local_guidance_service.dart',
    'lib/features/home/presentation/widgets/premium_guidance_card.dart',
    'lib/features/home/presentation/home_screen.dart',
    'lib/features/premium/presentation/premium_screen.dart',
    'lib/features/support/presentation/support_screen.dart',
]

REQUIRED_TEXT = {
    'lib/features/guidance/domain/local_guidance_snapshot.dart': 'class LocalGuidanceSnapshot',
    'lib/features/guidance/data/local_guidance_repository.dart': 'Grace is not gone because the day got hard.',
    'lib/features/guidance/data/local_guidance_service.dart': 'premium.hasPremium',
    'lib/features/home/presentation/widgets/premium_guidance_card.dart': 'Local Premium Guidance',
    'lib/features/home/presentation/home_screen.dart': 'const PremiumGuidanceCard()',
    'lib/features/premium/presentation/premium_screen.dart': 'Breakout Plus includes local premium guidance, deeper quotes, and faith-sensitive packs without AI chat.',
    'lib/features/support/presentation/support_screen.dart': 'Breakout Plus gives curated local guidance and faith-sensitive packs without AI chat.',
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

    print('Breakout Addiction BA-29 non-AI premium guidance verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
EOD

echo "==> BA-29 non-AI premium guidance scaffold written."
echo "==> Running Python verification..."
python3 tools/verify_ba29.py
