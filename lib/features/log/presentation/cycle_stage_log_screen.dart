import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../cycle/domain/cycle_stage.dart';
import '../data/cycle_stage_log_repository.dart';
import '../domain/cycle_stage_log_entry.dart';

class CycleStageLogScreen extends StatefulWidget {
  final CycleStage initialStage;

  const CycleStageLogScreen({
    super.key,
    required this.initialStage,
  });

  @override
  State<CycleStageLogScreen> createState() => _CycleStageLogScreenState();
}

class _CycleStageLogScreenState extends State<CycleStageLogScreen> {
  late CycleStage _selectedStage;
  double _intensity = 5;
  final TextEditingController _noteController = TextEditingController();
  final CycleStageLogRepository _repository = CycleStageLogRepository();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedStage = widget.initialStage;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveLog() async {
    setState(() => _isSaving = true);

    final entry = CycleStageLogEntry(
      timestamp: DateTime.now(),
      stage: _selectedStage,
      intensity: _intensity.round(),
      note: _noteController.text.trim(),
    );

    await _repository.saveEntry(entry);

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Saved ${entry.stage.title} log at intensity ${entry.intensity}.',
        ),
      ),
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
      appBar: AppBar(title: const Text('Cycle Stage Log')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Name the moment clearly.', style: AppTypography.title),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'The goal is not perfection. The goal is to catch the pattern earlier.',
              style: AppTypography.muted,
            ),
            const SizedBox(height: AppSpacing.lg),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Stage', style: AppTypography.section),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<CycleStage>(
                    value: _selectedStage,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: CycleStage.values.map((stage) {
                      return DropdownMenuItem<CycleStage>(
                        value: stage,
                        child: Text(stage.title),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedStage = value);
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
                  Text('Urge Intensity', style: AppTypography.section),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${_intensity.round()} / 10',
                    style: AppTypography.body,
                  ),
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
                  Text('What is happening right now?', style: AppTypography.section),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _noteController,
                    minLines: 4,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText: 'Example: late-night scrolling, stressed, starting to rationalize, feeling isolated...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: _isSaving ? 'Saving...' : 'Save Stage Log',
              icon: Icons.save_outlined,
              onPressed: _isSaving ? () {} : _saveLog,
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, RouteNames.rescue),
                icon: const Icon(Icons.health_and_safety_outlined),
                label: const Text('Open Rescue Instead'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
