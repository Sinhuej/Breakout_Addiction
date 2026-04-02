import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/recovery_plan_repository.dart';
import '../domain/recovery_plan.dart';

class RecoveryPlanScreen extends StatefulWidget {
  const RecoveryPlanScreen({super.key});

  @override
  State<RecoveryPlanScreen> createState() => _RecoveryPlanScreenState();
}

class _RecoveryPlanScreenState extends State<RecoveryPlanScreen> {
  final RecoveryPlanRepository _repository = RecoveryPlanRepository();

  final TextEditingController _riskyPlacesController = TextEditingController();
  final TextEditingController _firstActionController = TextEditingController();
  final TextEditingController _secondActionController = TextEditingController();
  final TextEditingController _groundingActionController = TextEditingController();
  final TextEditingController _supportPersonController = TextEditingController();
  final TextEditingController _fallbackPlanController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _riskyPlacesController.dispose();
    _firstActionController.dispose();
    _secondActionController.dispose();
    _groundingActionController.dispose();
    _supportPersonController.dispose();
    _fallbackPlanController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final plan = await _repository.getPlan();
    if (!mounted) {
      return;
    }

    _riskyPlacesController.text = plan.riskyPlaces.join(', ');
    _firstActionController.text = plan.firstAction;
    _secondActionController.text = plan.secondAction;
    _groundingActionController.text = plan.groundingAction;
    _supportPersonController.text = plan.supportPerson;
    _fallbackPlanController.text = plan.fallbackPlan;

    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final riskyPlaces = _riskyPlacesController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    final plan = RecoveryPlan(
      riskyPlaces: riskyPlaces,
      firstAction: _firstActionController.text.trim(),
      secondAction: _secondActionController.text.trim(),
      groundingAction: _groundingActionController.text.trim(),
      supportPerson: _supportPersonController.text.trim(),
      fallbackPlan: _fallbackPlanController.text.trim(),
    );

    await _repository.savePlan(plan);

    if (!mounted) {
      return;
    }

    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recovery plan saved.')),
    );
  }

  Widget _field({
    required String title,
    required String hint,
    required TextEditingController controller,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.section),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: controller,
            minLines: minLines,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recovery Plan')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Recovery Plan')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Make the next right step obvious.', style: AppTypography.title),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'This plan should tell you what to do before you start negotiating with the urge.',
            style: AppTypography.muted,
          ),
          const SizedBox(height: AppSpacing.lg),
          _field(
            title: 'Risky Places',
            hint: 'Example: bedroom alone at night, parked car, bathroom, couch after midnight',
            controller: _riskyPlacesController,
            minLines: 2,
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.md),
          _field(
            title: 'What do I do first?',
            hint: 'Example: leave the room, put the phone away, stand up immediately',
            controller: _firstActionController,
            minLines: 2,
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.md),
          _field(
            title: 'What is my backup step?',
            hint: 'Example: text someone, open Rescue, go outside for 5 minutes',
            controller: _secondActionController,
            minLines: 2,
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.md),
          _field(
            title: 'Grounding Action',
            hint: 'Example: breathe 4-4-6, cold water, 20 pushups, short walk',
            controller: _groundingActionController,
            minLines: 2,
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.md),
          _field(
            title: 'Support Person',
            hint: 'Who should I contact when I am slipping?',
            controller: _supportPersonController,
          ),
          const SizedBox(height: AppSpacing.md),
          _field(
            title: 'Fallback Plan',
            hint: 'If I still feel unstable, what do I do next?',
            controller: _fallbackPlanController,
            minLines: 3,
            maxLines: 5,
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: _saving ? 'Saving...' : 'Save Recovery Plan',
            icon: Icons.save_outlined,
            onPressed: _saving ? () {} : _save,
          ),
        ],
      ),
    );
  }
}
