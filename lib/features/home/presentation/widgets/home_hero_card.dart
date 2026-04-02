import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/privacy/neutral_labels.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../privacy/data/privacy_label_repository.dart';

class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = PrivacyLabelRepository();

    return FutureBuilder<bool>(
      future: repository.isNeutralModeEnabled(),
      builder: (context, snapshot) {
        final neutralMode = snapshot.data ?? true;

        return InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Break the cycle earlier.', style: AppTypography.title),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'The goal is not perfection. The goal is to recognize the pattern sooner and interrupt it faster.',
                style: AppTypography.muted,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  Chip(label: Text('Private')),
                  Chip(label: Text('Action-focused')),
                  Chip(label: Text('Recovery-first')),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: NeutralLabels.rescuePrimary(neutralMode),
                icon: Icons.health_and_safety_outlined,
                onPressed: () => Navigator.pushNamed(context, RouteNames.rescue),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, RouteNames.cycle),
                  icon: const Icon(Icons.donut_large_outlined),
                  label: const Text('Open Cycle Wheel'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
