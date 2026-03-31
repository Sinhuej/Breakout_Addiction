import 'package:flutter/material.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/privacy/neutral_labels.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../privacy/data/privacy_label_repository.dart';

class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = PrivacyLabelRepository();

    return FutureBuilder<bool>(
      future: repository.isNeutralModeEnabled(),
      builder: (context, snapshot) {
        final neutralMode = snapshot.data ?? true;

        return InfoCard(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, RouteNames.rescue),
                icon: const Icon(Icons.health_and_safety_outlined),
                label: Text(NeutralLabels.rescuePrimary(neutralMode)),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, RouteNames.moodLog),
                icon: const Icon(Icons.mood_outlined),
                label: Text(NeutralLabels.moodLog(neutralMode)),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, RouteNames.support),
                icon: const Icon(Icons.call_outlined),
                label: Text(NeutralLabels.supportAction(neutralMode)),
              ),
            ],
          ),
        );
      },
    );
  }
}
