import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../log/data/cycle_stage_log_repository.dart';
import '../../../log/domain/cycle_stage_log_entry.dart';

class StageAwareSuggestionCard extends StatelessWidget {
  const StageAwareSuggestionCard({super.key});

  String _messageForStage(CycleStageLogEntry? entry) {
    if (entry == null) {
      return 'Log a cycle stage to get smarter rescue suggestions here.';
    }

    final title = entry.stage.title;

    if (title == 'Triggers') {
      return 'You are early enough to change location, put the phone down, or text someone now.';
    }
    if (title == 'High Risk') {
      return 'This is a strong moment to leave the current setting and reduce privacy or isolation fast.';
    }
    if (title == 'Warning Signs') {
      return 'Your best move is to interrupt the ritual early: stand up, move rooms, and shorten the decision window.';
    }
    if (title == 'Fantasies') {
      return 'Shift your attention physically. Do not keep negotiating mentally with the urge.';
    }
    if (title == 'Actions / Behaviors') {
      return 'Stop the sequence. Close the app, change environments, and create friction immediately.';
    }
    if (title == 'Short-Lived Pleasure') {
      return 'This is a good time to reflect honestly, log what happened, and keep the spiral from deepening.';
    }
    if (title == 'Short-Lived Guilt & Fear') {
      return 'Do not waste energy hiding. Use honesty and a small reset step right now.';
    }
    if (title == 'Justifying / Making It Okay') {
      return 'Watch permission-giving thoughts closely. Delay, breathe, and do not trust “just once” logic.';
    }

    return 'Use Rescue early and keep the next action simple.';
  }

  @override
  Widget build(BuildContext context) {
    final repository = CycleStageLogRepository();

    return FutureBuilder<List<CycleStageLogEntry>>(
      future: repository.getEntries(),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? <CycleStageLogEntry>[];
        final latest = entries.isEmpty ? null : entries.first;

        return InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stage-Aware Suggestion', style: AppTypography.section),
              const SizedBox(height: AppSpacing.sm),
              if (latest != null) ...[
                Text('Latest stage: ${latest.stage.title}', style: AppTypography.body),
                const SizedBox(height: 8),
              ],
              Text(
                _messageForStage(latest),
                style: AppTypography.muted,
              ),
            ],
          ),
        );
      },
    );
  }
}
