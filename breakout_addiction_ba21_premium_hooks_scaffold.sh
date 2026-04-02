#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

echo "==> Applying Breakout Addiction BA-21 premium hooks scaffold in: $ROOT_DIR"

mkdir -p \
  lib/features/premium/domain \
  lib/features/premium/data \
  lib/features/premium/presentation/widgets \
  lib/features/premium/presentation \
  tools

cat > lib/core/constants/route_names.dart <<'EOD'
class RouteNames {
  static const home = '/';
  static const onboarding = '/onboarding';
  static const rescue = '/rescue';
  static const logHub = '/log';
  static const moodLog = '/log/mood';
  static const cycleStageLog = '/log/cycle-stage';
  static const recoveryEventLog = '/log/recovery-event';
  static const insights = '/insights';
  static const educate = '/educate';
  static const educateLesson = '/educate/lesson';
  static const premium = '/premium';
  static const support = '/support';
  static const riskWindows = '/risk-windows';
  static const recoveryPlan = '/recovery-plan';
  static const widgetPreview = '/widget-preview';
  static const cycle = '/cycle';
  static const privacySettings = '/privacy';
}
EOD

cat > lib/features/premium/domain/premium_status.dart <<'EOD'
class PremiumStatus {
  final bool isUnlocked;
  final bool showUpgradePrompts;

  const PremiumStatus({
    required this.isUnlocked,
    required this.showUpgradePrompts,
  });

  factory PremiumStatus.defaults() {
    return const PremiumStatus(
      isUnlocked: false,
      showUpgradePrompts: true,
    );
  }

  PremiumStatus copyWith({
    bool? isUnlocked,
    bool? showUpgradePrompts,
  }) {
    return PremiumStatus(
      isUnlocked: isUnlocked ?? this.isUnlocked,
      showUpgradePrompts: showUpgradePrompts ?? this.showUpgradePrompts,
    );
  }
}
EOD

cat > lib/features/premium/data/premium_access_repository.dart <<'EOD'
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/premium_status.dart';

class PremiumAccessRepository {
  static const String _premiumUnlockedKey = 'premium_unlocked';
  static const String _upgradePromptsKey = 'premium_upgrade_prompts';

  Future<PremiumStatus> getStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return PremiumStatus(
      isUnlocked: prefs.getBool(_premiumUnlockedKey) ?? false,
      showUpgradePrompts: prefs.getBool(_upgradePromptsKey) ?? true,
    );
  }

  Future<void> saveStatus(PremiumStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumUnlockedKey, status.isUnlocked);
    await prefs.setBool(_upgradePromptsKey, status.showUpgradePrompts);
  }

  Future<void> setUnlocked(bool value) async {
    final current = await getStatus();
    await saveStatus(current.copyWith(isUnlocked: value));
  }

  Future<void> setUpgradePrompts(bool value) async {
    final current = await getStatus();
    await saveStatus(current.copyWith(showUpgradePrompts: value));
  }
}
EOD

cat > lib/features/premium/presentation/widgets/premium_badge.dart <<'EOD'
import 'package:flutter/material.dart';

class PremiumBadge extends StatelessWidget {
  final String label;

  const PremiumBadge({
    super.key,
    this.label = 'Premium',
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
    );
  }
}
EOD
cat > lib/features/premium/presentation/premium_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/premium_access_repository.dart';
import '../domain/premium_status.dart';
import 'widgets/premium_badge.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final PremiumAccessRepository _repository = PremiumAccessRepository();

  PremiumStatus _status = PremiumStatus.defaults();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final status = await _repository.getStatus();
    if (!mounted) {
      return;
    }
    setState(() {
      _status = status;
      _loading = false;
    });
  }

  Future<void> _toggleDemoUnlock(bool value) async {
    await _repository.setUnlocked(value);
    await _load();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value
            ? 'Premium demo unlocked locally.'
            : 'Premium demo returned to locked state.'),
      ),
    );
  }

  Future<void> _togglePrompts(bool value) async {
    await _repository.setUpgradePrompts(value);
    await _load();
  }

  Widget _featureCard({
    required String title,
    required String subtitle,
  }) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: AppTypography.section),
              const SizedBox(width: 8),
              const PremiumBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(subtitle, style: AppTypography.muted),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        appBar: AppBar(title: Text('Premium')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Premium')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Breakout Plus', style: AppTypography.title),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Core recovery help stays free. Premium is for deeper guidance, richer learning, and future advanced tools.',
            style: AppTypography.muted,
          ),
          const SizedBox(height: AppSpacing.lg),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Access', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _status.isUnlocked ? 'Premium unlocked' : 'Premium locked',
                  style: AppTypography.body,
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _status.isUnlocked,
                  onChanged: _toggleDemoUnlock,
                  title: const Text('Local Demo Unlock'),
                  subtitle: const Text(
                    'Safe dev toggle for local testing until real billing is wired later.',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _status.showUpgradePrompts,
                  onChanged: _togglePrompts,
                  title: const Text('Show Upgrade Prompts'),
                  subtitle: const Text(
                    'Controls whether soft premium prompts appear in the app.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _featureCard(
            title: 'Educate Me Plus',
            subtitle:
                'Deeper pattern breakdowns, topic tracks, and richer learning modules.',
          ),
          const SizedBox(height: AppSpacing.md),
          _featureCard(
            title: 'Advanced Insights',
            subtitle:
                'Longer pattern history, stronger summaries, and more detailed behavior trends.',
          ),
          const SizedBox(height: AppSpacing.md),
          _featureCard(
            title: 'Future Coaching Layer',
            subtitle:
                'Reserved space for later premium guidance and expanded support tools.',
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: _status.isUnlocked ? 'Premium Active' : 'Upgrade Hooks Ready',
            icon: Icons.workspace_premium_outlined,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
EOD

python3 - <<'EOD'
from pathlib import Path

educate_path = Path('lib/features/educate/presentation/educate_screen.dart')
educate_text = educate_path.read_text(encoding='utf-8')

if "import '../../premium/data/premium_access_repository.dart';" not in educate_text:
    educate_text = educate_text.replace(
        "import '../../../core/widgets/info_card.dart';\n",
        "import '../../../core/widgets/info_card.dart';\nimport '../../premium/data/premium_access_repository.dart';\nimport '../../premium/presentation/widgets/premium_badge.dart';\n",
    )

old_block = """    final repository = LessonRepository();
    final tracks = repository.getTracks();

    return Scaffold(
"""

new_block = """    final repository = LessonRepository();
    final tracks = repository.getTracks();
    final premiumRepository = PremiumAccessRepository();

    return Scaffold(
"""

if "final premiumRepository = PremiumAccessRepository();" not in educate_text:
    educate_text = educate_text.replace(old_block, new_block)

marker = """          for (final track in tracks) ...[
            _TrackCard(track: track),
            const SizedBox(height: AppSpacing.md),
          ],
"""

insert = """          for (final track in tracks) ...[
            _TrackCard(track: track),
            const SizedBox(height: AppSpacing.md),
          ],
          FutureBuilder(
            future: premiumRepository.getStatus(),
            builder: (context, snapshot) {
              final status = snapshot.data;
              if (status == null || !status.showUpgradePrompts) {
                return const SizedBox.shrink();
              }

              return InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Text('Educate Me Plus', style: AppTypography.section),
                        SizedBox(width: 8),
                        PremiumBadge(),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Go deeper into compulsive patterns, emotional drivers, and advanced learning tracks.',
                      style: AppTypography.muted,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, RouteNames.premium),
                        icon: const Icon(Icons.workspace_premium_outlined),
                        label: Text(status.isUnlocked ? 'Premium Active' : 'Explore Premium'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
"""

if "Text('Educate Me Plus'" not in educate_text:
    educate_text = educate_text.replace(marker, insert)

educate_path.write_text(educate_text, encoding='utf-8')
print('Patched educate_screen.dart')

support_path = Path('lib/features/support/presentation/support_screen.dart')
support_text = support_path.read_text(encoding='utf-8')

marker2 = """          const SizedBox(height: AppSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Privacy & Lock Mode', style: AppTypography.section),
"""

insert2 = """          const SizedBox(height: AppSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Premium', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Premium hooks are ready for deeper learning and future advanced tools without locking core recovery help.',
                  style: AppTypography.muted,
                ),
                const SizedBox(height: AppSpacing.md),
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
          ),
""" + marker2

if "Text('Premium'" not in support_text:
    support_text = support_text.replace(marker2, insert2)

support_path.write_text(support_text, encoding='utf-8')
print('Patched support_screen.dart')
EOD
python3 - <<'EOD'
from pathlib import Path

router_path = Path('lib/app/app_router.dart')
router_text = router_path.read_text(encoding='utf-8')

if "import '../features/premium/presentation/premium_screen.dart';" not in router_text:
    router_text = router_text.replace(
        "import '../features/onboarding/presentation/onboarding_screen.dart';\n",
        "import '../features/onboarding/presentation/onboarding_screen.dart';\nimport '../features/premium/presentation/premium_screen.dart';\n",
    )

if "case RouteNames.premium:" not in router_text:
    router_text = router_text.replace(
        "      case RouteNames.support:\n",
        "      case RouteNames.premium:\n"
        "        return MaterialPageRoute(\n"
        "          builder: (_) => const ProtectedRouteGate(\n"
        "            scope: LockScope.support,\n"
        "            child: PremiumScreen(),\n"
        "          ),\n"
        "        );\n"
        "      case RouteNames.support:\n",
    )

router_path.write_text(router_text, encoding='utf-8')
print('Patched app_router.dart')
EOD

cat > tools/verify_ba21.py <<'EOD'
from pathlib import Path
import sys

REQUIRED = [
    'lib/core/constants/route_names.dart',
    'lib/features/premium/domain/premium_status.dart',
    'lib/features/premium/data/premium_access_repository.dart',
    'lib/features/premium/presentation/widgets/premium_badge.dart',
    'lib/features/premium/presentation/premium_screen.dart',
    'lib/features/educate/presentation/educate_screen.dart',
    'lib/features/support/presentation/support_screen.dart',
    'lib/app/app_router.dart',
]

REQUIRED_TEXT = {
    'lib/core/constants/route_names.dart': "static const premium = '/premium';",
    'lib/features/premium/domain/premium_status.dart': 'class PremiumStatus',
    'lib/features/premium/data/premium_access_repository.dart': 'class PremiumAccessRepository',
    'lib/features/premium/presentation/widgets/premium_badge.dart': 'class PremiumBadge',
    'lib/features/premium/presentation/premium_screen.dart': 'Local Demo Unlock',
    'lib/features/educate/presentation/educate_screen.dart': 'Educate Me Plus',
    'lib/features/support/presentation/support_screen.dart': "Text('Premium'",
    'lib/app/app_router.dart': 'case RouteNames.premium:',
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

    print('Breakout Addiction BA-21 premium hooks verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
EOD

echo "==> BA-21 premium hooks scaffold written."
echo "==> Running Python verification..."
python3 tools/verify_ba21.py
