import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';

class LockGateScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onUnlockSuccess;

  const LockGateScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onUnlockSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Protected')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: InfoCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.title),
                  const SizedBox(height: AppSpacing.sm),
                  Text(subtitle, style: AppTypography.muted),
                  const SizedBox(height: AppSpacing.lg),
                  const TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Passcode',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    label: 'Unlock',
                    icon: Icons.lock_open,
                    onPressed: onUnlockSuccess,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
