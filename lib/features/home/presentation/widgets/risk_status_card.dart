import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/info_card.dart';

class RiskStatusCard extends StatelessWidget {
  const RiskStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current Risk Status', style: AppTypography.section),
          SizedBox(height: AppSpacing.sm),
          Chip(label: Text('Guarded')),
          SizedBox(height: 8),
          Text(
            'This is where high-risk time windows, mood patterns, and '
            'recent urges will surface later.',
            style: AppTypography.muted,
          ),
        ],
      ),
    );
  }
}
