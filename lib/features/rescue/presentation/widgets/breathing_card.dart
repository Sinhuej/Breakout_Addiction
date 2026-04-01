import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/info_card.dart';

class BreathingCard extends StatelessWidget {
  const BreathingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Breathe With Me', style: AppTypography.section),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Inhale for 4 • hold for 4 • exhale for 6. Repeat 3 times.',
            style: AppTypography.body,
          ),
          SizedBox(height: 8),
          Text(
            'You are trying to slow the cycle down, not solve your whole life in one minute.',
            style: AppTypography.muted,
          ),
        ],
      ),
    );
  }
}
