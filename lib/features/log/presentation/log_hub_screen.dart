import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../cycle/domain/cycle_stage.dart';
import '../data/cycle_stage_log_repository.dart';
import '../domain/cycle_stage_log_entry.dart';

class LogHubScreen extends StatelessWidget {
  const LogHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = CycleStageLogRepository();

    return Scaffold(
      appBar: AppBar(title: const Text('Log')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Private Logs', style: AppTypography.section),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Mood log, urge log, relapse log, and victory log grow from here. '
                  'This pass adds cycle-stage logging first.',
                  style: AppTypography.muted,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick Log Actions', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                PrimaryButton(
                  label: 'Log Cycle Stage',
                  icon: Icons.add_chart_outlined,
                  onPressed: () => Navigator.pushNamed(
                    context,
                    RouteNames.cycleStageLog,
                    arguments: CycleStage.triggers,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FutureBuilder<List<CycleStageLogEntry>>(
            future: repository.getEntries(),
            builder: (context, snapshot) {
              final entries = snapshot.data ?? <CycleStageLogEntry>[];

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const InfoCard(
                  child: Text('Loading recent logs...', style: AppTypography.muted),
                );
              }

              if (entries.isEmpty) {
                return const InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recent Stage Logs', style: AppTypography.section),
                      SizedBox(height: AppSpacing.sm),
                      Text('No saved stage logs yet.', style: AppTypography.muted),
                    ],
                  ),
                );
              }

              return InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent Stage Logs', style: AppTypography.section),
                    const SizedBox(height: AppSpacing.sm),
                    for (final entry in entries.take(5)) ...[
                      _LogRow(entry: entry),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, RouteNames.home);
              break;
            case 1:
              Navigator.pushReplacementNamed(context, RouteNames.rescue);
              break;
            case 2:
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

class _LogRow extends StatelessWidget {
  final CycleStageLogEntry entry;

  const _LogRow({
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final note = entry.note.isEmpty ? 'No note added.' : entry.note;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF263041)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.stage.title, style: AppTypography.section),
          const SizedBox(height: 4),
          Text('Intensity: ${entry.intensity}/10', style: AppTypography.muted),
          const SizedBox(height: 4),
          Text(note, style: AppTypography.body),
        ],
      ),
    );
  }
}
