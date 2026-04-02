class InsightSummary {
  final int moodLogCount;
  final int stageLogCount;
  final int urgeCount;
  final int relapseCount;
  final int victoryCount;
  final String recentRiskLabel;
  final double averageStress;
  final double averageLoneliness;
  final double averageBoredom;
  final String topStageTitle;
  final String mostCommonMoodLabel;
  final String strongestPressureDriver;
  final String summaryLine;
  final String recommendationLine;
  final String nextBestAction;

  const InsightSummary({
    required this.moodLogCount,
    required this.stageLogCount,
    required this.urgeCount,
    required this.relapseCount,
    required this.victoryCount,
    required this.recentRiskLabel,
    required this.averageStress,
    required this.averageLoneliness,
    required this.averageBoredom,
    required this.topStageTitle,
    required this.mostCommonMoodLabel,
    required this.strongestPressureDriver,
    required this.summaryLine,
    required this.recommendationLine,
    required this.nextBestAction,
  });

  factory InsightSummary.empty() {
    return const InsightSummary(
      moodLogCount: 0,
      stageLogCount: 0,
      urgeCount: 0,
      relapseCount: 0,
      victoryCount: 0,
      recentRiskLabel: 'Not enough data',
      averageStress: 0,
      averageLoneliness: 0,
      averageBoredom: 0,
      topStageTitle: 'None yet',
      mostCommonMoodLabel: 'Unknown',
      strongestPressureDriver: 'Unknown',
      summaryLine: 'Start logging mood, stages, and recovery events to unlock stronger insights.',
      recommendationLine: 'A few honest check-ins will make this screen much smarter.',
      nextBestAction: 'Log a mood or cycle stage today.',
    );
  }
}
