import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../guidance/data/local_guidance_service.dart';
import '../../../guidance/domain/local_guidance_snapshot.dart';

class PremiumGuidanceCard extends StatelessWidget {
  const PremiumGuidanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final service = LocalGuidanceService();

    return FutureBuilder<LocalGuidanceSnapshot>(
      future: service.buildSnapshot(),
      builder: (context, snapshot) {
        final guidance = snapshot.data ?? LocalGuidanceSnapshot.locked();

        return InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Local Premium Guidance', style: AppTypography.section),
              const SizedBox(height: AppSpacing.sm),
              Chip(label: Text(guidance.packLabel)),
              const SizedBox(height: AppSpacing.sm),
              Text(guidance.title, style: AppTypography.title),
              const SizedBox(height: 8),
              Text(guidance.body, style: AppTypography.body),
              const SizedBox(height: AppSpacing.sm),
              Text(guidance.actionLine, style: AppTypography.muted),
              const SizedBox(height: AppSpacing.sm),
              Text(guidance.footerLine, style: AppTypography.muted),
              const SizedBox(height: AppSpacing.md),
              if (guidance.isUnlocked)
                PrimaryButton(
                  label: 'Open Support',
                  icon: Icons.support_agent_outlined,
                  onPressed: () => Navigator.pushNamed(
                    context,
                    RouteNames.support,
                  ),
                )
              else
                PrimaryButton(
                  label: 'Open Premium',
                  icon: Icons.workspace_premium_outlined,
                  onPressed: () => Navigator.pushNamed(
                    context,
                    RouteNames.premium,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
