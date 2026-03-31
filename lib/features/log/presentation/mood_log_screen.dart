import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/mood_log_repository.dart';
import '../domain/mood_entry.dart';

class MoodLogScreen extends StatefulWidget {
  const MoodLogScreen({super.key});

  @override
  State<MoodLogScreen> createState() => _MoodLogScreenState();
}

class _MoodLogScreenState extends State<MoodLogScreen> {
  final MoodLogRepository _repository = MoodLogRepository();
  final TextEditingController _noteController = TextEditingController();

  String _moodLabel = 'Neutral';
  double _stress = 4;
  double _loneliness = 4;
  double _boredom = 4;
  double _energy = 5;
  bool _isSaving = false;

  static const List<String> _moods = <String>[
    'Calm',
    'Neutral',
    'Stressed',
    'Lonely',
    'Bored',
    'Frustrated',
    'Hopeful',
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveMood() async {
    setState(() => _isSaving = true);

    final entry = MoodEntry(
      timestamp: DateTime.now(),
      moodLabel: _moodLabel,
      stress: _stress.round(),
      loneliness: _loneliness.round(),
      boredom: _boredom.round(),
      energy: _energy.round(),
      note: _noteController.text.trim(),
    );

    await _repository.saveEntry(entry);

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved mood log: ${entry.moodLabel}.')),
    );

    Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.home,
      (route) => route.isFirst,
    );
  }

  Widget _buildSlider({
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.section),
          const SizedBox(height: AppSpacing.sm),
          Text('${value.round()} / 10', style: AppTypography.body),
          Slider(
            value: value,
            min: 0,
            max: 10,
            divisions: 10,
            label: value.round().toString(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mood Log')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Check in honestly.', style: AppTypography.title),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Mood logs help the app understand when your risk is rising.',
              style: AppTypography.muted,
            ),
            const SizedBox(height: AppSpacing.lg),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How would you label this moment?', style: AppTypography.section),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: _moodLabel,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: _moods
                        .map(
                          (mood) => DropdownMenuItem<String>(
                            value: mood,
                            child: Text(mood),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _moodLabel = value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildSlider(
              title: 'Stress',
              value: _stress,
              onChanged: (value) => setState(() => _stress = value),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildSlider(
              title: 'Loneliness',
              value: _loneliness,
              onChanged: (value) => setState(() => _loneliness = value),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildSlider(
              title: 'Boredom',
              value: _boredom,
              onChanged: (value) => setState(() => _boredom = value),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildSlider(
              title: 'Energy',
              value: _energy,
              onChanged: (value) => setState(() => _energy = value),
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
                      hintText: 'What is going on right now?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: _isSaving ? 'Saving...' : 'Save Mood Log',
              icon: Icons.mood_outlined,
              onPressed: _isSaving ? () {} : _saveMood,
            ),
          ],
        ),
      ),
    );
  }
}
