#!/usr/bin/env bash
set -euo pipefail

mkdir -p \
  lib/features/about/domain \
  lib/features/about/data \
  lib/features/about/presentation \
  docs \
  tools

cat > lib/features/about/domain/demo_showcase_item.dart <<'EOD'
class DemoShowcaseItem {
  final String title;
  final String subtitle;
  final List<String> bullets;

  const DemoShowcaseItem({
    required this.title,
    required this.subtitle,
    required this.bullets,
  });
}
EOD

cat > lib/features/about/data/demo_showcase_repository.dart <<'EOD'
import '../domain/demo_showcase_item.dart';

class DemoShowcaseRepository {
  const DemoShowcaseRepository();

  List<DemoShowcaseItem> getItems() {
    return const <DemoShowcaseItem>[
      DemoShowcaseItem(
        title: 'Private Recovery Core',
        subtitle:
            'The app is useful even with AI turned off and premium disabled.',
        bullets: <String>[
          'Cycle wheel, Rescue, logs, insights, support, and privacy are all real.',
          'The user can keep the app simple and local.',
          'Startup messaging lowers shame instead of increasing it.',
        ],
      ),
      DemoShowcaseItem(
        title: 'Breakout Plus Without AI',
        subtitle:
            'Premium stands on its own through local guidance and faith-sensitive packs.',
        bullets: <String>[
          'Local premium guidance is unlocked without AI chat.',
          'Faith-sensitive packs can stay local and private.',
          'Plus is valuable even for users who never want AI.',
        ],
      ),
      DemoShowcaseItem(
        title: 'Optional AI Layer',
        subtitle:
            'AI is clearly separated into Breakout Plus AI and can be turned off.',
        bullets: <String>[
          'AI mode clarity is visible on-screen.',
          'Usage meter shows local/stub/live activity honestly.',
          'Emergency fallback pushes users toward human help, not more chat.',
        ],
      ),
      DemoShowcaseItem(
        title: 'Proactive Interruption',
        subtitle:
            'The app can now actively help before risky moments begin.',
        bullets: <String>[
          'Risk windows are configurable.',
          'Live local reminders can be synced.',
          'Widget entry paths and quick actions support earlier interruption.',
        ],
      ),
    ];
  }
}
EOD

cat > lib/features/about/presentation/about_breakout_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/info_card.dart';
import '../data/demo_showcase_repository.dart';
import '../domain/demo_showcase_item.dart';

class AboutBreakoutScreen extends StatelessWidget {
  const AboutBreakoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const DemoShowcaseRepository().getItems();

    return Scaffold(
      appBar: AppBar(title: const Text('About Breakout')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('What Breakout is built to do.', style: AppTypography.title),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Breakout is designed to help users interrupt compulsive patterns earlier, reduce shame, and choose the level of privacy and support that feels safe to them.',
            style: AppTypography.muted,
          ),
          const SizedBox(height: AppSpacing.lg),
          const InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Core product direction', style: AppTypography.section),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'The product is private-first, action-focused, and recovery-first. AI is optional. Premium is useful with or without AI.',
                  style: AppTypography.muted,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final item in items) ...[
            _ShowcaseCard(item: item),
            const SizedBox(height: AppSpacing.md),
          ],
          const InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Demo framing', style: AppTypography.section),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'A strong demo starts on Home, opens Rescue, shows Risk Windows + reminders, opens Support, then shows the premium split between Breakout Plus and Breakout Plus AI.',
                  style: AppTypography.muted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShowcaseCard extends StatelessWidget {
  final DemoShowcaseItem item;

  const _ShowcaseCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: AppTypography.section),
          const SizedBox(height: AppSpacing.sm),
          Text(item.subtitle, style: AppTypography.muted),
          const SizedBox(height: AppSpacing.sm),
          for (final bullet in item.bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('• $bullet', style: AppTypography.body),
            ),
        ],
      ),
    );
  }
}
EOD

cat > docs/DEMO_HANDOFF.md <<'EOD'
# Breakout Addiction — Demo Handoff

## What to show first
1. Open **Home**
2. Point out the calm startup framing and privacy-first tone
3. Show **Demo Readiness**
4. Open **Rescue**
5. Open **Support**
6. Open **Risk Windows**
7. Open **Widget Preview**
8. Show **Premium**
9. Show **AI Recovery Coach**
10. Open **About Breakout**

## What makes the build strong
- Useful without AI
- Premium works without AI chat
- AI is optional and clearly labeled
- Reminders are real
- Widget quick-entry flow is staged and testable
- Human-support fallback is built in

## Premium story
- **Breakout Plus** = premium without AI chat
- **Breakout Plus AI** = optional AI guidance/chat layer

## AI story
- Local/mock path exists
- Gemini prototype path is guarded
- AI mode clarity is visible
- Usage meter is visible
- Emergencies should leave chat and go to human support

## Suggested Sparkles demo script
“Breakout is built to help people interrupt the pattern earlier without making them feel worse. It works as a private recovery app even with AI turned off. Premium does not depend on AI. AI is optional, visible, and gated.”

## Final confidence commands
```bash
python3 tools/verify_ba35.py
bash tools/run_final_demo_readiness.sh
