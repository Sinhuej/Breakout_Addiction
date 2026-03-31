import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/privacy/neutral_labels.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../log/data/mood_log_repository.dart';
import '../../../log/domain/mood_entry.dart';
import '../../../privacy/data/privacy_label_repository.dart';

class RiskStatusCard extends StatelessWidget {
  const RiskStatusCard({super.key});

  String _riskLabel(List<MoodEntry> entries) {
    if (entries.isEmpty) {
      return 'Guarded';
    }

    final recent = entries.take(3).toList();
    final averageStress =
        recent.map((e) => e.stress).reduce((a, b) => a + b) / recent.length;
    final averageLoneliness =
        recent.map((e) => e.loneliness).reduce((a, b) => a + b) / recent.length;
    final averageBoredom =
        recent.map((e) => e.boredom).reduce((a, b) => a + b) / recent.length;

    final pressure = averageStress + averageLoneliness + averageBoredom;

    if (pressure >= 21) {
      return 'High Risk';
    }
    if (pressure >= 16) {
      return 'Elevated';
    }
    if (pressure >= 10) {
      return 'Guarded';
    }
    return 'Low Risk';
  }

  String _supportText(List<MoodEntry> entries) {
    if (entries.isEmpty) {
      return 'Log your mood to help Breakout estimate risk more accurately.';
    }

    final recent = entries.first;
    return 'Most recent mood: ${recent.moodLabel}. '
        'Stress ${recent.stress}/10 • Loneliness ${recent.loneliness}/10 • '
        'Boredom ${recent.boredom}/10.';
  }

  @override
  Widget build(BuildContext context) {
    final moodRepository = MoodLogRepository();
    final labelRepository = PrivacyLabelRepository();

    return FutureBuilder<List<dynamic>>(
      future: Future.wait<dynamic>([
        moodRepository.getEntries(),
        labelRepository.isNeutralModeEnabled(),
      ]),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final entries =
            data != null && data.isNotEmpty ? data[0] as List<MoodEntry> : <MoodEntry>[];
        final neutralMode =
            data != null && data.length > 1 ? data[1] as bool : true;

        final label = _riskLabel(entries);
        final detail = _supportText(entries);

        return InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Risk Status', style: AppTypography.section),
              const SizedBox(height: AppSpacing.sm),
              Chip(label: Text(label)),
              const SizedBox(height: 8),
              Text(detail, style: AppTypography.muted),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: NeutralLabels.riskCardAction(neutralMode),
                icon: Icons.mood_outlined,
                onPressed: () => Navigator.pushNamed(context, RouteNames.moodLog),
              ),
            ],
          ),
        );
      },
    );
  }
}
