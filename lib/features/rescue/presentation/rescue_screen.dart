import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';

class RescueScreen extends StatelessWidget {
  const RescueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rescue')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Pause. You still have a choice.', style: AppTypography.title),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Interrupt the cycle before it gains momentum.',
              style: AppTypography.muted,
            ),
            const SizedBox(height: AppSpacing.lg),
            const InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Urge Intensity', style: AppTypography.section),
                  SizedBox(height: AppSpacing.sm),
                  Slider(value: 4, min: 0, max: 10, onChanged: null),
                  Text('A live slider will be wired in next.', style: AppTypography.muted),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            InfoCard(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton(onPressed: () {}, child: const Text('Delay 3 min')),
                  OutlinedButton(onPressed: () {}, child: const Text('Delay 10 min')),
                  OutlinedButton(onPressed: () {}, child: const Text('Delay 15 min')),
                  OutlinedButton(onPressed: () {}, child: const Text('Breathe with me')),
                  OutlinedButton(onPressed: () {}, child: const Text('Leave this room')),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reasons to Stop', style: AppTypography.section),
                  SizedBox(height: AppSpacing.sm),
                  Text('Self-respect • mental clarity • relationships • peace', style: AppTypography.body),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Support Actions', style: AppTypography.section),
                  const SizedBox(height: AppSpacing.sm),
                  PrimaryButton(
                    label: 'Open Support',
                    icon: Icons.support_agent_outlined,
                    onPressed: () => Navigator.pushNamed(context, RouteNames.support),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, RouteNames.home);
              break;
            case 1:
              break;
            case 2:
              Navigator.pushReplacementNamed(context, RouteNames.logHub);
              break;
            case 3:
              Navigator.pushReplacementNamed(context, RouteNames.insights);
              break;
            case 4:
              Navigator.pushReplacementNamed(context, RouteNames.support);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.flash_on_outlined), label: 'Rescue'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_note_outlined), label: 'Log'),
          BottomNavigationBarItem(icon: Icon(Icons.insights_outlined), label: 'Insights'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent_outlined), label: 'Support'),
        ],
      ),
    );
  }
}
