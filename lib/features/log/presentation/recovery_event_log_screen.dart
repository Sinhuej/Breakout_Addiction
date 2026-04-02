import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/recovery_event_repository.dart';
import '../domain/recovery_event_entry.dart';

class RecoveryEventLogScreen extends StatefulWidget {
  const RecoveryEventLogScreen({super.key});

  @override
  State<RecoveryEventLogScreen> createState() => _RecoveryEventLogScreenState();
}

class _RecoveryEventLogScreenState extends State<RecoveryEventLogScreen> {
  final RecoveryEventRepository _repository = RecoveryEventRepository();
  final TextEditingController _contextController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  RecoveryEventType _type = RecoveryEventType.urge;
  double _intensity = 5;
  bool _saving = false;

  @override
  void dispose() {
    _contextController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final entry = RecoveryEventEntry(
      timestamp: DateTime.now(),
      type: _type,
      intensity: _intensity.round(),
      context: _contextController.text.trim(),
      note: _noteController.text.trim(),
    );

    await _repository.saveEntry(entry);

    if (!mounted) {
      return;
    }

    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved ${entry.type.label.toLowerCase()} log.')),
    );

    Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.logHub,
      (route) => route.settings.name == RouteNames.home || route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recovery Event Log')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Capture the moment honestly.', style: AppTypography.title),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Urges, slips, and wins all teach you something if you name them clearly.',
              style: AppTypography.muted,
            ),
            const SizedBox(height: AppSpacing.lg),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Event Type', style: AppTypography.section),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<RecoveryEventType>(
                    initialValue: _type,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: RecoveryEventType.values
                        .map(
                          (item) => DropdownMenuItem<RecoveryEventType>(
                            value: item,
                            child: Text(item.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _type = value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Intensity', style: AppTypography.section),
                  const SizedBox(height: AppSpacing.sm),
                  Text('${_intensity.round()} / 10', style: AppTypography.body),
                  Slider(
                    value: _intensity,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: _intensity.round().toString(),
                    onChanged: (value) {
                      setState(() => _intensity = value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Context', style: AppTypography.section),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _contextController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Example: alone late at night, stressed after work, bored on couch...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notes', style: AppTypography.section),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _noteController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'What happened? What did you notice? What helped or failed?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: _saving ? 'Saving...' : 'Save Recovery Event',
              icon: Icons.save_outlined,
              onPressed: _saving ? () {} : _save,
            ),
          ],
        ),
      ),
    );
  }
}
