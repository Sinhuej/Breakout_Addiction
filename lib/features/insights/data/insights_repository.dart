import '../../cycle/domain/cycle_stage.dart';
import '../../log/data/cycle_stage_log_repository.dart';
import '../../log/data/mood_log_repository.dart';
import '../../log/domain/cycle_stage_log_entry.dart';
import '../../log/domain/mood_entry.dart';
import '../domain/insight_summary.dart';

class InsightsRepository {
  final MoodLogRepository _moodRepository = MoodLogRepository();
  final CycleStageLogRepository _stageRepository =
      CycleStageLogRepository();

  Future<InsightSummary> buildSummary() async {
    final List<MoodEntry> moods = await _moodRepository.getEntries();
    final List<CycleStageLogEntry> stages = await _stageRepository.getEntries();

    if (moods.isEmpty && stages.isEmpty) {
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

    final double pressure = averageStress + averageLoneliness + averageBoredom;

    final String recentRiskLabel;
    if (pressure >= 21) {
      recentRiskLabel = 'High Risk';
    } else if (pressure >= 16) {
      recentRiskLabel = 'Elevated';
    } else if (pressure >= 10) {
      recentRiskLabel = 'Guarded';
    } else {
      recentRiskLabel = 'Low Risk';
    }

    final Map<String, int> stageCounts = <String, int>{};
    for (final entry in stages) {
      stageCounts.update(
        entry.stage.title,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    String topStageTitle = 'None yet';
    if (stageCounts.isNotEmpty) {
      final sorted = stageCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topStageTitle = sorted.first.key;
    }

    final String summaryLine;
    if (moods.isEmpty) {
      summaryLine =
          'Stage logs are starting to form a pattern, but mood context is still limited.';
    } else if (stages.isEmpty) {
      summaryLine =
          'Mood logs are building, but cycle-stage logging will sharpen the pattern.';
    } else {
      summaryLine =
          'Your recent pattern points most strongly toward $topStageTitle with a $recentRiskLabel pressure level.';
    }

    final String recommendationLine;
    if (recentRiskLabel == 'High Risk') {
      recommendationLine =
          'Use Rescue sooner, especially during times when stress, loneliness, or boredom are stacking together.';
    } else if (recentRiskLabel == 'Elevated') {
      recommendationLine =
          'Try logging earlier in the cycle so you can catch warning signs before they turn into actions.';
    } else {
      recommendationLine =
          'Keep stacking honest check-ins. Earlier awareness is helping reduce pressure.';
    }

    return InsightSummary(
      moodLogCount: moods.length,
      stageLogCount: stages.length,
      recentRiskLabel: recentRiskLabel,
      averageStress: averageStress,
      averageLoneliness: averageLoneliness,
      averageBoredom: averageBoredom,
      topStageTitle: topStageTitle,
      summaryLine: summaryLine,
      recommendationLine: recommendationLine,
    );
  }
}
