import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../data/app_entry_repository.dart';
import '../data/widget_snapshot_repository.dart';
import '../domain/widget_entry_action.dart';
import '../domain/widget_snapshot.dart';

class WidgetPreviewScreen extends StatelessWidget {
  const WidgetPreviewScreen({super.key});

  Widget _actionChip(String label) {
    return Chip(label: Text(label));
  }

  Widget _compactWidgetPreview(WidgetSnapshot snapshot) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF151B23),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF263041)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Breakout', style: AppTypography.section),
          const SizedBox(height: AppSpacing.sm),
          Text(snapshot.dailyFocusTitle, style: AppTypography.body),
          const SizedBox(height: 6),
          Text(snapshot.dailyFocusSubtitle, style: AppTypography.muted),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _actionChip(snapshot.homeLabel),
              _actionChip(snapshot.rescueLabel),
              _actionChip(snapshot.moodLabel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _riskWidgetPreview(WidgetSnapshot snapshot) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF151B23),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF263041)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Risk Snapshot', style: AppTypography.section),
          const SizedBox(height: AppSpacing.sm),
          Chip(label: Text(snapshot.riskLabel)),
          const SizedBox(height: 8),
          Text(
            snapshot.neutralMode
                ? 'Privacy-safe wording is active for widget labels.'
                : 'Standard wording is active for widget labels.',
            style: AppTypography.muted,
          ),
        ],
      ),
    );
  }

  Future<void> _simulateEntry(
    BuildContext context,
    WidgetEntryAction action,
  ) async {
    final repository = AppEntryRepository();
    await repository.stageWidgetEntry(action);

    if (!context.mounted) {
      return;
    }

    Navigator.pushNamed(context, RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    final repository = WidgetSnapshotRepository();

    return Scaffold(
      appBar: AppBar(title: const Text('Widget Preview')),
      body: FutureBuilder<WidgetSnapshot>(
        future: repository.buildSnapshot(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(
              child: Text('Unable to load widget preview.'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text('Home Screen Widget', style: AppTypography.title),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Preview the widget content and simulate a tap path so app entry feels like a real quick-action flow.',
                style: AppTypography.muted,
              ),
              const SizedBox(height: AppSpacing.lg),
              const InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How this works', style: AppTypography.section),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'This screen previews widget content from real app data. The simulate buttons stage a pending app-entry action and reopen the app flow through Home Entry.',
                      style: AppTypography.muted,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _compactWidgetPreview(data),
              const SizedBox(height: AppSpacing.md),
              _riskWidgetPreview(data),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () => _simulateEntry(context, WidgetEntryAction.openHome),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Simulate Widget → Open Breakout'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => _simulateEntry(context, WidgetEntryAction.openRescue),
                icon: const Icon(Icons.health_and_safety_outlined),
                label: const Text('Simulate Widget → Rescue'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => _simulateEntry(context, WidgetEntryAction.openMoodLog),
                icon: const Icon(Icons.mood_outlined),
                label: const Text('Simulate Widget → Log Check-In'),
              ),
            ],
          );
        },
      ),
    );
  }
}
