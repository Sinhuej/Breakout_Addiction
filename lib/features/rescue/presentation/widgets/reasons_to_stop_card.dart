import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/info_card.dart';
import '../../data/reasons_to_stop_repository.dart';

class ReasonsToStopCard extends StatelessWidget {
  const ReasonsToStopCard({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = ReasonsToStopRepository();

    return FutureBuilder<List<String>>(
      future: repository.getReasons(),
      builder: (context, snapshot) {
        final reasons = snapshot.data ?? <String>[];

        return InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reasons to Stop', style: AppTypography.section),
              const SizedBox(height: AppSpacing.sm),
              if (reasons.isEmpty)
                const Text(
                  'No reasons saved yet.',
                  style: AppTypography.muted,
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: reasons.map((item) => Chip(label: Text(item))).toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}
