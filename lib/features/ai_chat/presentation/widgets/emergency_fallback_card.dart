import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../../core/widgets/primary_button.dart';

class EmergencyFallbackCard extends StatelessWidget {
  final VoidCallback onCall988;
  final VoidCallback onText988;
  final VoidCallback onOpenSupport;

  const EmergencyFallbackCard({
    super.key,
    required this.onCall988,
    required this.onText988,
    required this.onOpenSupport,
  });

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Emergency Fallback', style: AppTypography.section),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'AI chat is not the right tool for emergencies. If you might hurt yourself or someone else, leave chat and get human support now.',
            style: AppTypography.muted,
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Call 988',
            icon: Icons.call_outlined,
            onPressed: onCall988,
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onText988,
              icon: const Icon(Icons.sms_outlined),
              label: const Text('Text 988'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpenSupport,
              icon: const Icon(Icons.support_agent_outlined),
              label: const Text('Open Support'),
            ),
          ),
        ],
      ),
    );
  }
}
