import 'lock_scope.dart';

class LockSettings {
  final bool isEnabled;
  final Set<LockScope> enabledScopes;
  final bool allowRescueWithoutUnlock;
  final bool useBiometrics;
  final bool hasPasscode;
  final bool neutralPrivacyMode;

  const LockSettings({
    required this.isEnabled,
    required this.enabledScopes,
    required this.allowRescueWithoutUnlock,
    required this.useBiometrics,
    required this.hasPasscode,
    required this.neutralPrivacyMode,
  });

  factory LockSettings.disabled() {
    return const LockSettings(
      isEnabled: false,
      enabledScopes: <LockScope>{},
      allowRescueWithoutUnlock: true,
      useBiometrics: false,
      hasPasscode: false,
      neutralPrivacyMode: true,
    );
  }

  bool shouldLock(LockScope scope) {
    return isEnabled && enabledScopes.contains(scope);
  }
}
