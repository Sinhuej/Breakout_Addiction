#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

echo "==> Applying Breakout Addiction BA-16 recovery plan scaffold in: $ROOT_DIR"

mkdir -p \
  lib/features/support/domain \
  lib/features/support/data \
  lib/features/support/presentation \
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
  static const cycle = '/cycle';
  static const privacySettings = '/privacy';
}
EOD

cat > lib/features/support/domain/recovery_plan.dart <<'EOD'
class RecoveryPlan {
  final List<String> riskyPlaces;
  final String firstAction;
  final String secondAction;
  final String groundingAction;
  final String supportPerson;
  final String fallbackPlan;

  const RecoveryPlan({
    required this.riskyPlaces,
    required this.firstAction,
    required this.secondAction,
    required this.groundingAction,
    required this.supportPerson,
    required this.fallbackPlan,
  });

  factory RecoveryPlan.defaults() {
    return const RecoveryPlan(
      riskyPlaces: <String>[],
      firstAction: '',
      secondAction: '',
      groundingAction: '',
      supportPerson: '',
      fallbackPlan: '',
    );
  }

  RecoveryPlan copyWith({
    List<String>? riskyPlaces,
    String? firstAction,
    String? secondAction,
    String? groundingAction,
    String? supportPerson,
    String? fallbackPlan,
  }) {
    return RecoveryPlan(
      riskyPlaces: riskyPlaces ?? this.riskyPlaces,
      firstAction: firstAction ?? this.firstAction,
      secondAction: secondAction ?? this.secondAction,
      groundingAction: groundingAction ?? this.groundingAction,
      supportPerson: supportPerson ?? this.supportPerson,
      fallbackPlan: fallbackPlan ?? this.fallbackPlan,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'riskyPlaces': riskyPlaces,
      'firstAction': firstAction,
      'secondAction': secondAction,
      'groundingAction': groundingAction,
      'supportPerson': supportPerson,
      'fallbackPlan': fallbackPlan,
    };
  }

  factory RecoveryPlan.fromMap(Map<String, dynamic> map) {
    return RecoveryPlan(
      riskyPlaces: (map['riskyPlaces'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(),
      firstAction: (map['firstAction'] as String?) ?? '',
      secondAction: (map['secondAction'] as String?) ?? '',
      groundingAction: (map['groundingAction'] as String?) ?? '',
      supportPerson: (map['supportPerson'] as String?) ?? '',
      fallbackPlan: (map['fallbackPlan'] as String?) ?? '',
    );
  }
}
EOD

cat > lib/features/support/data/recovery_plan_repository.dart <<'EOD'
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/recovery_plan.dart';

class RecoveryPlanRepository {
  static const String _storageKey = 'support_recovery_plan';

  Future<RecoveryPlan> getPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return RecoveryPlan.defaults();
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return RecoveryPlan.fromMap(decoded);
  }

  Future<void> savePlan(RecoveryPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(plan.toMap()));
  }
}
EOD
cat > lib/features/support/presentation/recovery_plan_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/recovery_plan_repository.dart';
import '../domain/recovery_plan.dart';

class RecoveryPlanScreen extends StatefulWidget {
  const RecoveryPlanScreen({super.key});

  @override
  State<RecoveryPlanScreen> createState() => _RecoveryPlanScreenState();
}

class _RecoveryPlanScreenState extends State<RecoveryPlanScreen> {
  final RecoveryPlanRepository _repository = RecoveryPlanRepository();

  final TextEditingController _riskyPlacesController = TextEditingController();
  final TextEditingController _firstActionController = TextEditingController();
  final TextEditingController _secondActionController = TextEditingController();
  final TextEditingController _groundingActionController = TextEditingController();
  final TextEditingController _supportPersonController = TextEditingController();
  final TextEditingController _fallbackPlanController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _riskyPlacesController.dispose();
    _firstActionController.dispose();
    _secondActionController.dispose();
    _groundingActionController.dispose();
    _supportPersonController.dispose();
    _fallbackPlanController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final plan = await _repository.getPlan();
    if (!mounted) {
      return;
    }

    _riskyPlacesController.text = plan.riskyPlaces.join(', ');
    _firstActionController.text = plan.firstAction;
    _secondActionController.text = plan.secondAction;
    _groundingActionController.text = plan.groundingAction;
    _supportPersonController.text = plan.supportPerson;
    _fallbackPlanController.text = plan.fallbackPlan;

    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final riskyPlaces = _riskyPlacesController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    final plan = RecoveryPlan(
      riskyPlaces: riskyPlaces,
      firstAction: _firstActionController.text.trim(),
      secondAction: _secondActionController.text.trim(),
      groundingAction: _groundingActionController.text.trim(),
      supportPerson: _supportPersonController.text.trim(),
      fallbackPlan: _fallbackPlanController.text.trim(),
    );

    await _repository.savePlan(plan);

    if (!mounted) {
      return;
    }

    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recovery plan saved.')),
    );
  }

  Widget _field({
    required String title,
    required String hint,
    required TextEditingController controller,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.section),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: controller,
            minLines: minLines,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recovery Plan')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Recovery Plan')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Make the next right step obvious.', style: AppTypography.title),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'This plan should tell you what to do before you start negotiating with the urge.',
            style: AppTypography.muted,
          ),
          const SizedBox(height: AppSpacing.lg),
          _field(
            title: 'Risky Places',
            hint: 'Example: bedroom alone at night, parked car, bathroom, couch after midnight',
            controller: _riskyPlacesController,
            minLines: 2,
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.md),
          _field(
            title: 'What do I do first?',
            hint: 'Example: leave the room, put the phone away, stand up immediately',
            controller: _firstActionController,
            minLines: 2,
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.md),
          _field(
            title: 'What is my backup step?',
            hint: 'Example: text someone, open Rescue, go outside for 5 minutes',
            controller: _secondActionController,
            minLines: 2,
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.md),
          _field(
            title: 'Grounding Action',
            hint: 'Example: breathe 4-4-6, cold water, 20 pushups, short walk',
            controller: _groundingActionController,
            minLines: 2,
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.md),
          _field(
            title: 'Support Person',
            hint: 'Who should I contact when I am slipping?',
            controller: _supportPersonController,
          ),
          const SizedBox(height: AppSpacing.md),
          _field(
            title: 'Fallback Plan',
            hint: 'If I still feel unstable, what do I do next?',
            controller: _fallbackPlanController,
            minLines: 3,
            maxLines: 5,
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: _saving ? 'Saving...' : 'Save Recovery Plan',
            icon: Icons.save_outlined,
            onPressed: _saving ? () {} : _save,
          ),
        ],
      ),
    );
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
                Text('Personal Recovery Plan', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Write down your risky places, your first move, your backup move, and your fallback plan.',
                  style: AppTypography.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Open Recovery Plan',
                  icon: Icons.assignment_outlined,
                  onPressed: () => Navigator.pushNamed(
                    context,
                    RouteNames.recoveryPlan,
                  ),
                ),
              ],
            ),
          ),
""" + marker

if "Text('Personal Recovery Plan'" not in support_text:
    support_text = support_text.replace(marker, insert)

support_path.write_text(support_text, encoding='utf-8')
print('Patched support_screen.dart')
EOD
python3 - <<'EOD'
from pathlib import Path

router_path = Path('lib/app/app_router.dart')
router_text = router_path.read_text(encoding='utf-8')

if "import '../features/support/presentation/recovery_plan_screen.dart';" not in router_text:
    router_text = router_text.replace(
        "import '../features/support/presentation/support_screen.dart';\n",
        "import '../features/support/presentation/support_screen.dart';\nimport '../features/support/presentation/recovery_plan_screen.dart';\n",
    )

if "case RouteNames.recoveryPlan:" not in router_text:
    router_text = router_text.replace(
        "      case RouteNames.support:\n",
        "      case RouteNames.recoveryPlan:\n"
        "        return MaterialPageRoute(\n"
        "          builder: (_) => const ProtectedRouteGate(\n"
        "            scope: LockScope.support,\n"
        "            child: RecoveryPlanScreen(),\n"
        "          ),\n"
        "        );\n"
        "      case RouteNames.support:\n",
    )

router_path.write_text(router_text, encoding='utf-8')
print('Patched app_router.dart')
EOD

cat > tools/verify_ba16.py <<'EOD'
from pathlib import Path
import sys

REQUIRED = [
    'lib/core/constants/route_names.dart',
    'lib/features/support/domain/recovery_plan.dart',
    'lib/features/support/data/recovery_plan_repository.dart',
    'lib/features/support/presentation/recovery_plan_screen.dart',
    'lib/features/support/presentation/support_screen.dart',
    'lib/app/app_router.dart',
]

REQUIRED_TEXT = {
    'lib/core/constants/route_names.dart': "static const recoveryPlan = '/recovery-plan';",
    'lib/features/support/domain/recovery_plan.dart': 'class RecoveryPlan',
    'lib/features/support/data/recovery_plan_repository.dart': 'class RecoveryPlanRepository',
    'lib/features/support/presentation/recovery_plan_screen.dart': 'Save Recovery Plan',
    'lib/features/support/presentation/support_screen.dart': 'Personal Recovery Plan',
    'lib/app/app_router.dart': 'case RouteNames.recoveryPlan:',
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

    print('Breakout Addiction BA-16 recovery plan verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
EOD

echo "==> BA-16 recovery plan scaffold written."
echo "==> Running Python verification..."
python3 tools/verify_ba16.py
