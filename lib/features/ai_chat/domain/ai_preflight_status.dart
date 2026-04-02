class AiPreflightStatus {
  final bool premiumUnlocked;
  final String providerModeLabel;
  final bool providerIsVertexPrivateReady;
  final bool remotePathEnabled;
  final bool apiKeyPresent;
  final bool riskyFeaturesForcedOff;
  final bool readyForRemoteStub;
  final String summaryLine;
  final List<String> blockerLines;

  const AiPreflightStatus({
    required this.premiumUnlocked,
    required this.providerModeLabel,
    required this.providerIsVertexPrivateReady,
    required this.remotePathEnabled,
    required this.apiKeyPresent,
    required this.riskyFeaturesForcedOff,
    required this.readyForRemoteStub,
    required this.summaryLine,
    required this.blockerLines,
  });

  factory AiPreflightStatus.initial() {
    return const AiPreflightStatus(
      premiumUnlocked: false,
      providerModeLabel: 'Mock',
      providerIsVertexPrivateReady: false,
      remotePathEnabled: false,
      apiKeyPresent: false,
      riskyFeaturesForcedOff: true,
      readyForRemoteStub: false,
      summaryLine: 'Preflight not loaded yet.',
      blockerLines: <String>[],
    );
  }
}
