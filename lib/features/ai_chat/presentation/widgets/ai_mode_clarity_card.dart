import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/info_card.dart';

class AiModeClarityCard extends StatelessWidget {
  final String modeLabel;
  final String summaryLine;
  final List<String> blockers;

  const AiModeClarityCard({
    super.key,
    required this.modeLabel,
    required this.summaryLine,
    required this.blockers,
  });

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current AI State', style: AppTypography.section),
          const SizedBox(height: AppSpacing.sm),
          Chip(label: Text(modeLabel)),
          const SizedBox(height: AppSpacing.sm),
          Text(summaryLine, style: AppTypography.muted),
          if (blockers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            for (final line in blockers)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $line', style: AppTypography.body),
              ),
          ],
        ],
      ),
    );
  }
}
