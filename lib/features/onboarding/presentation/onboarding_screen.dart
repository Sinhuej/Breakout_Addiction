import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../quotes/data/quote_preferences_repository.dart';
import '../../quotes/domain/daily_quote.dart';
import '../../support/data/support_contact_repository.dart';
import '../../support/domain/support_contact.dart';
import '../data/onboarding_repository.dart';
import '../domain/onboarding_state.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final OnboardingRepository _repository = OnboardingRepository();
  final QuotePreferencesRepository _quotePrefs = QuotePreferencesRepository();
  final SupportContactRepository _contactRepository = SupportContactRepository();

  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();

  int _stepIndex = 0;
  bool _isSaving = false;

  String _goal = 'Break the cycle earlier';
  QuoteMode _quoteMode = QuoteMode.recovery;
  String _religion = 'Christian';

  final Set<String> _selectedTriggers = <String>{};
  final Set<String> _selectedRiskTimes = <String>{};

  static const List<String> _goals = <String>[
    'Break the cycle earlier',
    'Reduce secrecy and shame',
    'Strengthen self-control',
    'Protect my relationships',
  ];

  static const List<String> _triggers = <String>[
    'Stress',
    'Loneliness',
    'Boredom',
    'Late-night phone use',
    'Arguments',
    'Scrolling social apps',
  ];

  static const List<String> _riskTimes = <String>[
    'Late night',
    'Right after waking up',
    'After work',
    'When home alone',
    'Weekends',
    'After conflict',
  ];

  static const List<String> _religions = <String>[
    'Christian',
    'General Faith',
    'Secular',
  ];

  @override
  void dispose() {
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_stepIndex < 5) {
      setState(() => _stepIndex += 1);
    }
  }

  void _previousStep() {
    if (_stepIndex > 0) {
      setState(() => _stepIndex -= 1);
    }
  }

  Future<void> _finish() async {
    setState(() => _isSaving = true);

    final state = OnboardingState(
      completed: true,
      primaryGoal: _goal,
      quoteMode: _quoteMode,
      religionPreference: _religion,
      topTriggers: _selectedTriggers.toList(),
      riskyTimes: _selectedRiskTimes.toList(),
      trustedContactName: _contactNameController.text.trim(),
      trustedContactPhone: _contactPhoneController.text.trim(),
    );

    await _repository.saveState(state);
    await _quotePrefs.saveMode(_quoteMode);
    await _quotePrefs.saveReligionTag(_religion);

    final contact = SupportContact(
      name: _contactNameController.text.trim(),
      phone: _contactPhoneController.text.trim(),
    );

    if (contact.isValid) {
      await _contactRepository.saveContact(contact);
    }

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);

    Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.home,
      (route) => false,
    );
  }

  Widget _buildChipSet({
    required List<String> options,
    required Set<String> selected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((item) {
        final active = selected.contains(item);
        return FilterChip(
          selected: active,
          label: Text(item),
          onSelected: (value) {
            setState(() {
              if (value) {
                selected.add(item);
              } else {
                selected.remove(item);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _stepBody() {
    switch (_stepIndex) {
      case 0:
        return InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome to Breakout Addiction', style: AppTypography.title),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'This short setup helps tailor support, privacy, and encouragement to you.',
                style: AppTypography.muted,
              ),
            ],
          ),
        );
      case 1:
        return InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What is your main goal?', style: AppTypography.section),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: _goal,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: _goals
                    .map((item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _goal = value);
                },
              ),
            ],
          ),
        );
      case 2:
        return InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose your encouragement style', style: AppTypography.section),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<QuoteMode>(
                initialValue: _quoteMode,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: QuoteMode.values
                    .map((item) => DropdownMenuItem<QuoteMode>(
                          value: item,
                          child: Text(item.name),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _quoteMode = value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _religion,
                decoration: const InputDecoration(
                  labelText: 'Faith / Religion',
                  border: OutlineInputBorder(),
                ),
                items: _religions
                    .map((item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _religion = value);
                },
              ),
            ],
          ),
        );
      case 3:
        return InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What tends to trigger you?', style: AppTypography.section),
              const SizedBox(height: AppSpacing.sm),
              _buildChipSet(
                options: _triggers,
                selected: _selectedTriggers,
              ),
            ],
          ),
        );
      case 4:
        return InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('When are you most at risk?', style: AppTypography.section),
              const SizedBox(height: AppSpacing.sm),
              _buildChipSet(
                options: _riskTimes,
                selected: _selectedRiskTimes,
              ),
            ],
          ),
        );
      case 5:
        return InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Optional trusted contact', style: AppTypography.section),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _contactNameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _contactPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = _stepIndex == 5;

    return Scaffold(
      appBar: AppBar(title: const Text('Get Started')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Step ${_stepIndex + 1} of 6', style: AppTypography.muted),
            const SizedBox(height: AppSpacing.sm),
            _stepBody(),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                if (_stepIndex > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _previousStep,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                    ),
                  ),
                if (_stepIndex > 0) const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: isLastStep
                        ? (_isSaving ? 'Saving...' : 'Finish Setup')
                        : 'Next',
                    icon: isLastStep
                        ? Icons.check_circle_outline
                        : Icons.arrow_forward,
                    onPressed: isLastStep
                        ? (_isSaving ? () {} : _finish)
                        : _nextStep,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
