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
