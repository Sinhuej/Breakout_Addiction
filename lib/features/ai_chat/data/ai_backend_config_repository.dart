import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/ai_backend_config.dart';

class AiBackendConfigRepository {
  static const String _modelNameKey = 'ai_backend_model_name';
  static const String _apiBaseUrlKey = 'ai_backend_api_base_url';
  static const String _allowGroundingKey = 'ai_backend_allow_grounding';
  static const String _allowMapsGroundingKey = 'ai_backend_allow_maps_grounding';
  static const String _allowSessionMemoryKey = 'ai_backend_allow_session_memory';
  static const String _allowFileUploadsKey = 'ai_backend_allow_file_uploads';
  static const String _apiKeyStorageKey = 'ai_backend_api_key';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<AiBackendConfig> getConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = await _secureStorage.read(key: _apiKeyStorageKey);

    return AiBackendConfig(
      modelName: prefs.getString(_modelNameKey) ?? 'gemini-2.5-flash',
      apiBaseUrl: prefs.getString(_apiBaseUrlKey) ??
          'https://us-central1-aiplatform.googleapis.com',
      allowGrounding: prefs.getBool(_allowGroundingKey) ?? false,
      allowMapsGrounding: prefs.getBool(_allowMapsGroundingKey) ?? false,
      allowSessionMemory: prefs.getBool(_allowSessionMemoryKey) ?? false,
      allowFileUploads: prefs.getBool(_allowFileUploadsKey) ?? false,
      hasApiKey: savedKey != null && savedKey.isNotEmpty,
    );
  }

  Future<void> saveConfig(AiBackendConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelNameKey, config.modelName);
    await prefs.setString(_apiBaseUrlKey, config.apiBaseUrl);
    await prefs.setBool(_allowGroundingKey, config.allowGrounding);
    await prefs.setBool(_allowMapsGroundingKey, config.allowMapsGrounding);
    await prefs.setBool(_allowSessionMemoryKey, config.allowSessionMemory);
    await prefs.setBool(_allowFileUploadsKey, config.allowFileUploads);
  }

  Future<void> saveApiKey(String apiKey) async {
    await _secureStorage.write(key: _apiKeyStorageKey, value: apiKey);
  }

  Future<void> clearApiKey() async {
    await _secureStorage.delete(key: _apiKeyStorageKey);
  }
}
