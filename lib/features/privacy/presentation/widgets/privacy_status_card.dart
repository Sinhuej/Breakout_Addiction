import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/info_card.dart';
import '../../data/lock_settings_repository.dart';
import '../../domain/privacy_status_snapshot.dart';

class PrivacyStatusCard extends StatelessWidget {
  const PrivacyStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = LockSettingsRepository();

    return FutureBuilder(
      future: repository.getSettings(),
      builder: (context, snapshot) {
        final settings = snapshot.data;
        if (settings == null) {
          return const InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Privacy Status', style: AppTypography.section),
                SizedBox(height: AppSpacing.sm),
                Text('Loading privacy status...', style: AppTypography.muted),
              ],
            ),
          );
        }

        final status = PrivacyStatusSnapshot(
          lockEnabled: settings.isEnabled,
          hasPasscode: settings.hasPasscode,
          protectedAreaCount: settings.enabledScopes.length,
          rescueBypassEnabled: settings.allowRescueWithoutUnlock,
          neutralModeEnabled: settings.neutralPrivacyMode,
          biometricsEnabled: settings.useBiometrics,
        );

        return InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Privacy Status', style: AppTypography.section),
              const SizedBox(height: AppSpacing.sm),
              Text('Lock: ${status.lockLabel}', style: AppTypography.body),
              const SizedBox(height: 4),
              Text('Passcode: ${status.passcodeLabel}', style: AppTypography.body),
              const SizedBox(height: 4),
              Text(
                'Protected areas: ${status.protectedAreaCount}',
                style: AppTypography.body,
              ),
              const SizedBox(height: 4),
              Text('Rescue access: ${status.rescueLabel}', style: AppTypography.body),
              const SizedBox(height: 4),
              Text(status.neutralLabel, style: AppTypography.muted),
            ],
          ),
        );
      },
    );
  }
}
