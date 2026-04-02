class PrivacyStatusSnapshot {
  final bool lockEnabled;
  final bool hasPasscode;
  final int protectedAreaCount;
  final bool rescueBypassEnabled;
  final bool neutralModeEnabled;
  final bool biometricsEnabled;

  const PrivacyStatusSnapshot({
    required this.lockEnabled,
    required this.hasPasscode,
    required this.protectedAreaCount,
    required this.rescueBypassEnabled,
    required this.neutralModeEnabled,
    required this.biometricsEnabled,
  });

  String get lockLabel => lockEnabled ? 'Enabled' : 'Disabled';
  String get passcodeLabel => hasPasscode ? 'Set' : 'Not set';
  String get rescueLabel => rescueBypassEnabled ? 'Allowed' : 'Locked';
  String get neutralLabel => neutralModeEnabled ? 'Neutral labels on' : 'Standard labels on';
}
