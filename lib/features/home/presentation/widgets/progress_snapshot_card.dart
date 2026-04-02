import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../log/data/cycle_stage_log_repository.dart';
import '../../../log/data/mood_log_repository.dart';
import '../../../log/data/recovery_event_repository.dart';
import '../../../log/domain/recovery_event_entry.dart';

class ProgressSnapshotCard extends StatelessWidget {
  const ProgressSnapshotCard({super.key});

  Future<Map<String, int>> _load() async {
    final moods = await MoodLogRepository().getEntries();
    final stages = await CycleStageLogRepository().getEntries();
    final events = await RecoveryEventRepository().getEntries();

    final victories = events.where((e) => e.type == RecoveryEventType.victory).length;
    final urges = events.where((e) => e.type == RecoveryEventType.urge).length;

    return <String, int>{
      'moods': moods.length,
      'stages': stages.length,
      'urges': urges,
      'victories': victories,
    };
  }

  Widget _chip(String label) {
    return Chip(label: Text(label));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _load(),
      builder: (context, snapshot) {
        final data = snapshot.data ??
            <String, int>{
              'moods': 0,
              'stages': 0,
              'urges': 0,
              'victories': 0,
            };

        return InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Progress Snapshot', style: AppTypography.section),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Small honest check-ins make the whole app smarter.',
                style: AppTypography.muted,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip('Mood logs: ${data['moods']}'),
                  _chip('Stage logs: ${data['stages']}'),
                  _chip('Urges: ${data['urges']}'),
                  _chip('Victories: ${data['victories']}'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
