import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/info_card.dart';
import '../../domain/ai_usage_snapshot.dart';

class AiUsageMeterCard extends StatelessWidget {
  final AiUsageSnapshot snapshot;
  final VoidCallback onReset;

  const AiUsageMeterCard({
    super.key,
    required this.snapshot,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AI Usage Meter', style: AppTypography.section),
          const SizedBox(height: AppSpacing.sm),
          Text('Prompt attempts: ${snapshot.promptAttempts}', style: AppTypography.body),
          const SizedBox(height: 4),
          Text('Stopped attempts: ${snapshot.stoppedAttempts}', style: AppTypography.body),
          const SizedBox(height: 4),
          Text('Live prototype calls: ${snapshot.livePrototypeCalls}', style: AppTypography.body),
          const SizedBox(height: 4),
          Text('Local or stub replies: ${snapshot.localOrStubReplies}', style: AppTypography.body),
          const SizedBox(height: 4),
          Text('Last mode: ${snapshot.lastModeLabel}', style: AppTypography.muted),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh_outlined),
              label: const Text('Reset Usage Meter'),
            ),
          ),
        ],
      ),
    );
  }
}
