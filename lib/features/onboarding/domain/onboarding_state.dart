import '../../quotes/domain/daily_quote.dart';

class OnboardingState {
  final bool completed;
  final String primaryGoal;
  final QuoteMode quoteMode;
  final String religionPreference;
  final List<String> topTriggers;
  final List<String> riskyTimes;
  final String trustedContactName;
  final String trustedContactPhone;

  const OnboardingState({
    required this.completed,
    required this.primaryGoal,
    required this.quoteMode,
    required this.religionPreference,
    required this.topTriggers,
    required this.riskyTimes,
    required this.trustedContactName,
    required this.trustedContactPhone,
  });

  factory OnboardingState.initial() {
    return const OnboardingState(
      completed: false,
      primaryGoal: 'Break the cycle earlier',
      quoteMode: QuoteMode.recovery,
      religionPreference: 'Christian',
      topTriggers: <String>[],
      riskyTimes: <String>[],
      trustedContactName: '',
      trustedContactPhone: '',
    );
  }
}
