import 'package:shared_preferences/shared_preferences.dart';

class AiRuntimeGateRepository {
  static const String _remotePathEnabledKey = 'ai_remote_path_enabled';

  Future<bool> getRemotePathEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_remotePathEnabledKey) ?? false;
  }

  Future<void> setRemotePathEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_remotePathEnabledKey, value);
  }
}
