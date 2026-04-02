import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../data/insights_repository.dart';
import '../domain/insight_summary.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  Widget _metricCard({
    required String title,
    required String value,
    required String subtitle,
  }) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.section),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTypography.title),
          const SizedBox(height: 6),
          Text(subtitle, style: AppTypography.muted),
        ],
      ),
    );
  }

  Widget _eventCard({
    required String title,
    required int count,
    required String subtitle,
  }) {
    return Expanded(
      child: InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.section),
            const SizedBox(height: AppSpacing.sm),
            Text('$count', style: AppTypography.title),
            const SizedBox(height: 6),
            Text(subtitle, style: AppTypography.muted),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(InsightSummary summary) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('Insights', style: AppTypography.title),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Patterns become easier to interrupt when they are easier to read.',
          style: AppTypography.muted,
        ),
        const SizedBox(height: AppSpacing.lg),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recent Risk Summary', style: AppTypography.section),
              const SizedBox(height: AppSpacing.sm),
              Chip(label: Text(summary.recentRiskLabel)),
              const SizedBox(height: AppSpacing.sm),
              Text(summary.summaryLine, style: AppTypography.body),
              const SizedBox(height: AppSpacing.sm),
              Text(summary.recommendationLine, style: AppTypography.muted),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            _eventCard(
              title: 'Urges',
              count: summary.urgeCount,
              subtitle: 'Logged urge events',
            ),
            const SizedBox(width: AppSpacing.md),
            _eventCard(
              title: 'Relapses',
              count: summary.relapseCount,
              subtitle: 'Logged slips',
            ),
            const SizedBox(width: AppSpacing.md),
            _eventCard(
              title: 'Victories',
              count: summary.victoryCount,
              subtitle: 'Logged wins',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _metricCard(
          title: 'Top Recent Stage',
          value: summary.topStageTitle,
          subtitle: 'Where the cycle most often shows up in your logs.',
        ),
        const SizedBox(height: AppSpacing.md),
        _metricCard(
          title: 'Most Common Mood',
          value: summary.mostCommonMoodLabel,
          subtitle: 'The mood label you log most often.',
        ),
        const SizedBox(height: AppSpacing.md),
        _metricCard(
          title: 'Strongest Pressure Driver',
          value: summary.strongestPressureDriver,
          subtitle: 'The heaviest average pressure in recent mood logs.',
        ),
        const SizedBox(height: AppSpacing.md),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mood Pressure Averages', style: AppTypography.section),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Stress: ${summary.averageStress.toStringAsFixed(1)}/10',
                style: AppTypography.body,
              ),
              const SizedBox(height: 6),
              Text(
                'Loneliness: ${summary.averageLoneliness.toStringAsFixed(1)}/10',
                style: AppTypography.body,
              ),
              const SizedBox(height: 6),
              Text(
                'Boredom: ${summary.averageBoredom.toStringAsFixed(1)}/10',
                style: AppTypography.body,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Next Best Action', style: AppTypography.section),
              const SizedBox(height: AppSpacing.sm),
              Text(summary.nextBestAction, style: AppTypography.body),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = InsightsRepository();

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: FutureBuilder<InsightSummary>(
        future: repository.buildSummary(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final summary = snapshot.data ?? InsightSummary.empty();
          return _buildBody(summary);
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, RouteNames.home);
              break;
            case 1:
              Navigator.pushReplacementNamed(context, RouteNames.rescue);
              break;
            case 2:
              Navigator.pushReplacementNamed(context, RouteNames.logHub);
              break;
            case 3:
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
