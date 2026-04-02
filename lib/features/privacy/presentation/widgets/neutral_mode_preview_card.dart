import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/privacy/neutral_labels.dart';
import '../../../../core/widgets/info_card.dart';

class NeutralModePreviewCard extends StatelessWidget {
  final bool neutralMode;

  const NeutralModePreviewCard({
    super.key,
    required this.neutralMode,
  });

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Neutral Label Preview', style: AppTypography.section),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(NeutralLabels.rescuePrimary(neutralMode))),
              Chip(label: Text(NeutralLabels.moodLog(neutralMode))),
              Chip(label: Text(NeutralLabels.supportAction(neutralMode))),
              Chip(label: Text(NeutralLabels.cycleWheelTitle(neutralMode))),
            ],
          ),
        ],
      ),
    );
  }
}
