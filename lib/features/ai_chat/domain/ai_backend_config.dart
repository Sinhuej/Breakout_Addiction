class AiBackendConfig {
  final String modelName;
  final String apiBaseUrl;
  final bool allowGrounding;
  final bool allowMapsGrounding;
  final bool allowSessionMemory;
  final bool allowFileUploads;
  final bool hasApiKey;

  const AiBackendConfig({
    required this.modelName,
    required this.apiBaseUrl,
    required this.allowGrounding,
    required this.allowMapsGrounding,
    required this.allowSessionMemory,
    required this.allowFileUploads,
    required this.hasApiKey,
  });

  factory AiBackendConfig.defaults() {
    return const AiBackendConfig(
      modelName: 'gemini-2.5-flash',
      apiBaseUrl: 'https://us-central1-aiplatform.googleapis.com',
      allowGrounding: false,
      allowMapsGrounding: false,
      allowSessionMemory: false,
      allowFileUploads: false,
      hasApiKey: false,
    );
  }

  AiBackendConfig copyWith({
    String? modelName,
    String? apiBaseUrl,
    bool? allowGrounding,
    bool? allowMapsGrounding,
    bool? allowSessionMemory,
    bool? allowFileUploads,
    bool? hasApiKey,
  }) {
    return AiBackendConfig(
      modelName: modelName ?? this.modelName,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      allowGrounding: allowGrounding ?? this.allowGrounding,
      allowMapsGrounding: allowMapsGrounding ?? this.allowMapsGrounding,
      allowSessionMemory: allowSessionMemory ?? this.allowSessionMemory,
      allowFileUploads: allowFileUploads ?? this.allowFileUploads,
      hasApiKey: hasApiKey ?? this.hasApiKey,
    );
  }
}
