import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import 'widgets/daily_quote_card.dart';
import 'widgets/quick_actions_row.dart';
import 'widgets/risk_status_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Breakout Addiction'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, RouteNames.support),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Break the cycle earlier.', style: AppTypography.title),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Catch the urge before it becomes behavior.',
              style: AppTypography.muted,
            ),
            const SizedBox(height: AppSpacing.lg),
            const DailyQuoteCard(),
            const SizedBox(height: AppSpacing.md),
            const RiskStatusCard(),
            const SizedBox(height: AppSpacing.md),
            const QuickActionsRow(),
            const SizedBox(height: AppSpacing.md),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recovery Cycle Wheel', style: AppTypography.section),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Triggers → High Risk → Warning Signs → Fantasies → '
                    'Actions / Behaviors → Short-Lived Pleasure → '
                    'Short-Lived Guilt & Fear → Justifying / Making It Okay',
                    style: AppTypography.muted,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pushNamed(context, RouteNames.cycle),
                      icon: const Icon(Icons.donut_large_outlined),
                      label: const Text('Open Cycle Wheel'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, RouteNames.rescue),
                      icon: const Icon(Icons.health_and_safety_outlined),
                      label: const Text('Open Rescue Now'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Progress Snapshot', style: AppTypography.section),
                  SizedBox(height: AppSpacing.sm),
                  Text('Current streak: 0 days', style: AppTypography.body),
                  SizedBox(height: 6),
                  Text('Urges this week: 0', style: AppTypography.body),
                  SizedBox(height: 6),
                  Text('Rescues completed: 0', style: AppTypography.body),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.pushReplacementNamed(context, RouteNames.rescue);
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
