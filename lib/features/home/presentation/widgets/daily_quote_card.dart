import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/info_card.dart';

class DailyQuoteCard extends StatelessWidget {
  const DailyQuoteCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily Focus', style: AppTypography.section),
          SizedBox(height: AppSpacing.sm),
          Text(
            'You are not your last decision.',
            style: AppTypography.body,
          ),
          SizedBox(height: 6),
          Text(
            'Catch the cycle earlier today.',
            style: AppTypography.muted,
          ),
        ],
      ),
    );
  }
}
