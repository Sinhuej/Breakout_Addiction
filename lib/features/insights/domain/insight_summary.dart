class InsightSummary {
  final int moodLogCount;
  final int stageLogCount;
  final String recentRiskLabel;
  final double averageStress;
  final double averageLoneliness;
  final double averageBoredom;
  final String topStageTitle;
  final String summaryLine;
  final String recommendationLine;

  const InsightSummary({
    required this.moodLogCount,
    required this.stageLogCount,
    required this.recentRiskLabel,
    required this.averageStress,
    required this.averageLoneliness,
    required this.averageBoredom,
    required this.topStageTitle,
    required this.summaryLine,
    required this.recommendationLine,
  });

  factory InsightSummary.empty() {
    return const InsightSummary(
      moodLogCount: 0,
      stageLogCount: 0,
      recentRiskLabel: 'Not enough data',
      averageStress: 0,
      averageLoneliness: 0,
      averageBoredom: 0,
      topStageTitle: 'None yet',
      summaryLine: 'Start logging mood and cycle stages to unlock insights.',
      recommendationLine:
          'A few honest check-ins will make this screen useful very quickly.',
    );
  }
}
