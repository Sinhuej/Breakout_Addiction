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
