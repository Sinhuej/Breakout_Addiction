import '../../cycle/domain/cycle_stage.dart';
import '../../log/data/cycle_stage_log_repository.dart';
import '../../log/data/mood_log_repository.dart';
import '../../log/data/recovery_event_repository.dart';
import '../../log/domain/cycle_stage_log_entry.dart';
import '../../log/domain/mood_entry.dart';
import '../../log/domain/recovery_event_entry.dart';
import '../domain/insight_summary.dart';

class InsightsRepository {
  final MoodLogRepository _moodRepository = MoodLogRepository();
  final CycleStageLogRepository _stageRepository =
      CycleStageLogRepository();
  final RecoveryEventRepository _eventRepository =
      RecoveryEventRepository();

  String _recentRiskLabel(
    double averageStress,
    double averageLoneliness,
    double averageBoredom,
  ) {
    final pressure = averageStress + averageLoneliness + averageBoredom;
    if (pressure >= 21) return 'High Risk';
    if (pressure >= 16) return 'Elevated';
    if (pressure >= 10) return 'Guarded';
    return 'Low Risk';
  }

  String _strongestDriver(
    double averageStress,
    double averageLoneliness,
    double averageBoredom,
  ) {
    final values = <String, double>{
      'Stress': averageStress,
      'Loneliness': averageLoneliness,
      'Boredom': averageBoredom,
    };

    final sorted = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.isEmpty ? 'Unknown' : sorted.first.key;
  }

  String _mostCommonMood(List<MoodEntry> moods) {
    if (moods.isEmpty) return 'Unknown';

    final counts = <String, int>{};
    for (final mood in moods) {
      counts.update(mood.moodLabel, (value) => value + 1, ifAbsent: () => 1);
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.key;
  }

  String _topStage(List<CycleStageLogEntry> stages) {
    if (stages.isEmpty) return 'None yet';

    final counts = <String, int>{};
    for (final entry in stages) {
      counts.update(entry.stage.title, (value) => value + 1, ifAbsent: () => 1);
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.key;
  }

  int _countEvents(List<RecoveryEventEntry> entries, RecoveryEventType type) {
    return entries.where((entry) => entry.type == type).length;
  }

  String _summaryLine({
    required bool hasMoods,
    required bool hasStages,
    required bool hasEvents,
    required String topStageTitle,
    required String recentRiskLabel,
    required String strongestPressureDriver,
  }) {
    if (!hasMoods && !hasStages && !hasEvents) {
      return 'You need a little more logging before clear patterns can emerge.';
    }
    if (!hasMoods) {
      return 'Stage and recovery event logs are forming a pattern, but mood context is still limited.';
    }
    if (!hasStages) {
      return 'Mood logs are building, but stage logging will sharpen where the cycle speeds up.';
    }
    return 'Your recent pattern points most strongly toward $topStageTitle with $strongestPressureDriver as the biggest pressure driver and a $recentRiskLabel overall level.';
  }

  String _recommendationLine({
    required String recentRiskLabel,
    required String strongestPressureDriver,
    required int victoryCount,
    required int relapseCount,
  }) {
    if (recentRiskLabel == 'High Risk') {
      return 'Reduce friction fast around $strongestPressureDriver-heavy moments and use Rescue earlier.';
    }
    if (relapseCount > victoryCount && relapseCount >= 2) {
      return 'Review your recovery plan and tighten your first-action step so it is easier to do automatically.';
    }
    if (victoryCount >= relapseCount && victoryCount > 0) {
      return 'Your wins show that interruption is working. Study what happened before those better moments.';
    }
    return 'Keep logging earlier in the cycle so your patterns become easier to interrupt.';
  }

  String _nextBestAction({
    required String strongestPressureDriver,
    required String topStageTitle,
    required String recentRiskLabel,
  }) {
    if (recentRiskLabel == 'High Risk') {
      return 'Set up a risk window around your most vulnerable time and prepare your first action in advance.';
    }
    if (topStageTitle == 'Warning Signs' || topStageTitle == 'Fantasies') {
      return 'Focus on faster interruption when you notice mental drift or early ritual behavior.';
    }
    if (strongestPressureDriver == 'Loneliness') {
      return 'Build one human-contact action into your plan before high-risk windows start.';
    }
    if (strongestPressureDriver == 'Stress') {
      return 'Use a grounding action before the urge has time to turn into a ritual.';
    }
    return 'Keep building early awareness with mood and stage logging.';
  }

  Future<InsightSummary> buildSummary() async {
    final List<MoodEntry> moods = await _moodRepository.getEntries();
    final List<CycleStageLogEntry> stages = await _stageRepository.getEntries();
    final List<RecoveryEventEntry> events = await _eventRepository.getEntries();

    if (moods.isEmpty && stages.isEmpty && events.isEmpty) {
      return InsightSummary.empty();
    }

    final List<MoodEntry> recentMoods = moods.take(7).toList();

    final double averageStress = recentMoods.isEmpty
        ? 0
        : recentMoods.map((e) => e.stress).reduce((a, b) => a + b) /
            recentMoods.length;

    final double averageLoneliness = recentMoods.isEmpty
        ? 0
        : recentMoods
                .map((e) => e.loneliness)
                .reduce((a, b) => a + b) /
            recentMoods.length;

    final double averageBoredom = recentMoods.isEmpty
        ? 0
        : recentMoods.map((e) => e.boredom).reduce((a, b) => a + b) /
            recentMoods.length;

    final recentRiskLabel = _recentRiskLabel(
      averageStress,
      averageLoneliness,
      averageBoredom,
    );

    final topStageTitle = _topStage(stages);
    final mostCommonMoodLabel = _mostCommonMood(moods);
    final strongestPressureDriver = _strongestDriver(
      averageStress,
      averageLoneliness,
      averageBoredom,
    );

    final urgeCount = _countEvents(events, RecoveryEventType.urge);
    final relapseCount = _countEvents(events, RecoveryEventType.relapse);
    final victoryCount = _countEvents(events, RecoveryEventType.victory);

    final summaryLine = _summaryLine(
      hasMoods: moods.isNotEmpty,
      hasStages: stages.isNotEmpty,
      hasEvents: events.isNotEmpty,
      topStageTitle: topStageTitle,
      recentRiskLabel: recentRiskLabel,
      strongestPressureDriver: strongestPressureDriver,
    );

    final recommendationLine = _recommendationLine(
      recentRiskLabel: recentRiskLabel,
      strongestPressureDriver: strongestPressureDriver,
      victoryCount: victoryCount,
      relapseCount: relapseCount,
    );

    final nextBestAction = _nextBestAction(
      strongestPressureDriver: strongestPressureDriver,
      topStageTitle: topStageTitle,
      recentRiskLabel: recentRiskLabel,
    );

    return InsightSummary(
      moodLogCount: moods.length,
      stageLogCount: stages.length,
      urgeCount: urgeCount,
      relapseCount: relapseCount,
      victoryCount: victoryCount,
      recentRiskLabel: recentRiskLabel,
      averageStress: averageStress,
      averageLoneliness: averageLoneliness,
      averageBoredom: averageBoredom,
      topStageTitle: topStageTitle,
      mostCommonMoodLabel: mostCommonMoodLabel,
      strongestPressureDriver: strongestPressureDriver,
      summaryLine: summaryLine,
      recommendationLine: recommendationLine,
      nextBestAction: nextBestAction,
    );
  }
}
