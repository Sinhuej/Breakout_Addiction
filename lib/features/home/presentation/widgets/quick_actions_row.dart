import 'package:flutter/material.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/widgets/info_card.dart';

class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, RouteNames.rescue),
            icon: const Icon(Icons.health_and_safety_outlined),
            label: const Text('I feel an urge'),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, RouteNames.moodLog),
            icon: const Icon(Icons.mood_outlined),
            label: const Text('Log mood'),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, RouteNames.support),
            icon: const Icon(Icons.call_outlined),
            label: const Text('Call support'),
          ),
        ],
      ),
    );
  }
}
