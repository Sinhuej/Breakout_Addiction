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

  LockSettings copyWith({
    bool? isEnabled,
    Set<LockScope>? enabledScopes,
    bool? allowRescueWithoutUnlock,
    bool? useBiometrics,
    bool? hasPasscode,
    bool? neutralPrivacyMode,
  }) {
    return LockSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      enabledScopes: enabledScopes ?? this.enabledScopes,
      allowRescueWithoutUnlock:
          allowRescueWithoutUnlock ?? this.allowRescueWithoutUnlock,
      useBiometrics: useBiometrics ?? this.useBiometrics,
      hasPasscode: hasPasscode ?? this.hasPasscode,
      neutralPrivacyMode: neutralPrivacyMode ?? this.neutralPrivacyMode,
    );
  }

  bool shouldLock(LockScope scope) {
    return isEnabled &&
        (enabledScopes.contains(LockScope.app) || enabledScopes.contains(scope));
  }
}
