class AiGuardrailStatus {
  final bool piiScrubbingEnabled;
  final bool minorContentBlockingEnabled;
  final bool imminentSelfHarmBlockingEnabled;
  final bool imminentViolenceBlockingEnabled;

  const AiGuardrailStatus({
    required this.piiScrubbingEnabled,
    required this.minorContentBlockingEnabled,
    required this.imminentSelfHarmBlockingEnabled,
    required this.imminentViolenceBlockingEnabled,
  });

  factory AiGuardrailStatus.defaults() {
    return const AiGuardrailStatus(
      piiScrubbingEnabled: true,
      minorContentBlockingEnabled: true,
      imminentSelfHarmBlockingEnabled: true,
      imminentViolenceBlockingEnabled: true,
    );
  }
}
