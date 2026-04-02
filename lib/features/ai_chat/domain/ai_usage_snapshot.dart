class AiUsageSnapshot {
  final int promptAttempts;
  final int stoppedAttempts;
  final int livePrototypeCalls;
  final int localOrStubReplies;
  final String lastModeLabel;

  const AiUsageSnapshot({
    required this.promptAttempts,
    required this.stoppedAttempts,
    required this.livePrototypeCalls,
    required this.localOrStubReplies,
    required this.lastModeLabel,
  });

  factory AiUsageSnapshot.empty() {
    return const AiUsageSnapshot(
      promptAttempts: 0,
      stoppedAttempts: 0,
      livePrototypeCalls: 0,
      localOrStubReplies: 0,
      lastModeLabel: 'No activity yet',
    );
  }
}
