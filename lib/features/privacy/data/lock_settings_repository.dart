import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/lock_scope.dart';
import '../domain/lock_settings.dart';

class LockSettingsRepository {
  static const String _enabledKey = 'privacy_enabled';
  static const String _scopesKey = 'privacy_scopes';
  static const String _rescueBypassKey = 'privacy_rescue_bypass';
  static const String _biometricKey = 'privacy_biometrics';
  static const String _neutralModeKey = 'privacy_neutral_mode';
  static const String _passcodeKey = 'privacy_passcode';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<LockSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final scopeNames = prefs.getStringList(_scopesKey) ?? <String>[];
    final hasPasscode = await _secureStorage.read(key: _passcodeKey) != null;

    return LockSettings(
      isEnabled: prefs.getBool(_enabledKey) ?? false,
      enabledScopes: scopeNames
          .map((name) => LockScope.values.byName(name))
          .toSet(),
      allowRescueWithoutUnlock: prefs.getBool(_rescueBypassKey) ?? true,
      useBiometrics: prefs.getBool(_biometricKey) ?? false,
      hasPasscode: hasPasscode,
      neutralPrivacyMode: prefs.getBool(_neutralModeKey) ?? true,
    );
  }

  Future<void> saveSettings(LockSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, settings.isEnabled);
    await prefs.setStringList(
      _scopesKey,
      settings.enabledScopes.map((scope) => scope.name).toList(),
    );
    await prefs.setBool(_rescueBypassKey, settings.allowRescueWithoutUnlock);
    await prefs.setBool(_biometricKey, settings.useBiometrics);
    await prefs.setBool(_neutralModeKey, settings.neutralPrivacyMode);
  }

  Future<void> savePasscode(String passcode) async {
    await _secureStorage.write(key: _passcodeKey, value: passcode);
  }

  Future<bool> verifyPasscode(String passcode) async {
    final saved = await _secureStorage.read(key: _passcodeKey);
    return saved != null && saved == passcode;
  }

  Future<void> clearPasscode() async {
    await _secureStorage.delete(key: _passcodeKey);
  }
}
