import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/info_card.dart';

class DelayActionsCard extends StatelessWidget {
  const DelayActionsCard({super.key});

  void _announce(BuildContext context, int minutes) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Good call. Delay for $minutes minutes and re-check your state.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Delay Actions', style: AppTypography.section),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton(
                onPressed: () => _announce(context, 3),
                child: const Text('Delay 3 min'),
              ),
              OutlinedButton(
                onPressed: () => _announce(context, 10),
                child: const Text('Delay 10 min'),
              ),
              OutlinedButton(
                onPressed: () => _announce(context, 15),
                child: const Text('Delay 15 min'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
