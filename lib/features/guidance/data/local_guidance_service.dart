import '../../log/data/mood_log_repository.dart';
import '../../premium/data/premium_access_repository.dart';
import '../../quotes/data/quote_preferences_repository.dart';
import '../../quotes/domain/daily_quote.dart';
import '../../settings/data/feature_control_settings_repository.dart';
import '../domain/local_guidance_snapshot.dart';
import 'local_guidance_repository.dart';

class LocalGuidanceService {
  final PremiumAccessRepository _premiumRepository =
      PremiumAccessRepository();
  final FeatureControlSettingsRepository _featureRepository =
      FeatureControlSettingsRepository();
  final QuotePreferencesRepository _quotePreferences =
      QuotePreferencesRepository();
  final MoodLogRepository _moodRepository = MoodLogRepository();
  final LocalGuidanceRepository _repository = const LocalGuidanceRepository();

  Future<LocalGuidanceSnapshot> buildSnapshot() async {
    final premium = await _premiumRepository.getStatus();
    if (!premium.hasPremium) {
      return LocalGuidanceSnapshot.locked();
    }

    final featureSettings = await _featureRepository.getSettings();
    final quoteMode = await _quotePreferences.getMode();
    final religion = await _quotePreferences.getReligionTag();
    final moods = await _moodRepository.getEntries();

    if (featureSettings.faithLayerEnabled && quoteMode == QuoteMode.faith) {
      return _repository.faithPack(religion);
    }

    if (moods.isEmpty) {
      return _repository.resetPack();
    }

    final recent = moods.first;
    final scores = <String, int>{
      'stress': recent.stress,
      'loneliness': recent.loneliness,
      'boredom': recent.boredom,
    };

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    switch (sorted.first.key) {
      case 'stress':
        return _repository.stressPack();
      case 'loneliness':
        return _repository.lonelinessPack();
      case 'boredom':
        return _repository.boredomPack();
      default:
        return _repository.resetPack();
    }
  }
}
