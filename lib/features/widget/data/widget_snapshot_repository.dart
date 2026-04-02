import '../../../core/privacy/neutral_labels.dart';
import '../../log/data/mood_log_repository.dart';
import '../../log/domain/mood_entry.dart';
import '../../privacy/data/privacy_label_repository.dart';
import '../../quotes/data/daily_quote_repository.dart';
import '../domain/widget_snapshot.dart';

class WidgetSnapshotRepository {
  final PrivacyLabelRepository _privacyRepository = PrivacyLabelRepository();
  final DailyQuoteRepository _quoteRepository = DailyQuoteRepository();
  final MoodLogRepository _moodRepository = MoodLogRepository();

  String _riskLabel(List<MoodEntry> entries) {
    if (entries.isEmpty) {
      return 'Guarded';
    }

    final recent = entries.take(3).toList();
    final averageStress =
        recent.map((e) => e.stress).reduce((a, b) => a + b) / recent.length;
    final averageLoneliness =
        recent.map((e) => e.loneliness).reduce((a, b) => a + b) / recent.length;
    final averageBoredom =
        recent.map((e) => e.boredom).reduce((a, b) => a + b) / recent.length;

    final pressure = averageStress + averageLoneliness + averageBoredom;
    if (pressure >= 21) return 'High Risk';
    if (pressure >= 16) return 'Elevated';
    if (pressure >= 10) return 'Guarded';
    return 'Low Risk';
  }

  Future<WidgetSnapshot> buildSnapshot() async {
    final neutralMode = await _privacyRepository.isNeutralModeEnabled();
    final quote = await _quoteRepository.getTodayQuote();
    final moods = await _moodRepository.getEntries();

    return WidgetSnapshot(
      neutralMode: neutralMode,
      homeLabel: NeutralLabels.widgetHome(neutralMode),
      rescueLabel: NeutralLabels.widgetRescue(neutralMode),
      moodLabel: NeutralLabels.widgetMood(neutralMode),
      dailyFocusTitle: quote.text,
      dailyFocusSubtitle: quote.focusLine,
      riskLabel: _riskLabel(moods),
    );
  }
}
