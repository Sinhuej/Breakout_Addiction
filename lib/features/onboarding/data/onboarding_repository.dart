import 'package:shared_preferences/shared_preferences.dart';

import '../../quotes/domain/daily_quote.dart';
import '../domain/onboarding_state.dart';

class OnboardingRepository {
  static const String _completedKey = 'onboarding_completed';
  static const String _goalKey = 'onboarding_goal';
  static const String _quoteModeKey = 'onboarding_quote_mode';
  static const String _religionKey = 'onboarding_religion';
  static const String _triggersKey = 'onboarding_triggers';
  static const String _riskyTimesKey = 'onboarding_risky_times';
  static const String _contactNameKey = 'onboarding_contact_name';
  static const String _contactPhoneKey = 'onboarding_contact_phone';

  Future<OnboardingState> getState() async {
    final prefs = await SharedPreferences.getInstance();

    final rawMode = prefs.getString(_quoteModeKey);
    final QuoteMode mode = rawMode == null || rawMode.isEmpty
        ? QuoteMode.recovery
        : QuoteMode.values.byName(rawMode);

    return OnboardingState(
      completed: prefs.getBool(_completedKey) ?? false,
      primaryGoal: prefs.getString(_goalKey) ?? 'Break the cycle earlier',
      quoteMode: mode,
      religionPreference: prefs.getString(_religionKey) ?? 'Christian',
      topTriggers: prefs.getStringList(_triggersKey) ?? <String>[],
      riskyTimes: prefs.getStringList(_riskyTimesKey) ?? <String>[],
      trustedContactName: prefs.getString(_contactNameKey) ?? '',
      trustedContactPhone: prefs.getString(_contactPhoneKey) ?? '',
    );
  }

  Future<void> saveState(OnboardingState state) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_completedKey, state.completed);
    await prefs.setString(_goalKey, state.primaryGoal);
    await prefs.setString(_quoteModeKey, state.quoteMode.name);
    await prefs.setString(_religionKey, state.religionPreference);
    await prefs.setStringList(_triggersKey, state.topTriggers);
    await prefs.setStringList(_riskyTimesKey, state.riskyTimes);
    await prefs.setString(_contactNameKey, state.trustedContactName);
    await prefs.setString(_contactPhoneKey, state.trustedContactPhone);
  }

  Future<bool> isComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }
}
