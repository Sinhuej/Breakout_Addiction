class FeatureControlSettings {
  final bool aiChatEnabled;
  final bool aiGuidanceEnabled;
  final bool faithLayerEnabled;
  final bool showStartupNotice;
  final bool remoteAiFeaturesEnabled;

  const FeatureControlSettings({
    required this.aiChatEnabled,
    required this.aiGuidanceEnabled,
    required this.faithLayerEnabled,
    required this.showStartupNotice,
    required this.remoteAiFeaturesEnabled,
  });

  factory FeatureControlSettings.defaults() {
    return const FeatureControlSettings(
      aiChatEnabled: true,
      aiGuidanceEnabled: true,
      faithLayerEnabled: true,
      showStartupNotice: true,
      remoteAiFeaturesEnabled: false,
    );
  }

  FeatureControlSettings copyWith({
    bool? aiChatEnabled,
    bool? aiGuidanceEnabled,
    bool? faithLayerEnabled,
    bool? showStartupNotice,
    bool? remoteAiFeaturesEnabled,
  }) {
    return FeatureControlSettings(
      aiChatEnabled: aiChatEnabled ?? this.aiChatEnabled,
      aiGuidanceEnabled: aiGuidanceEnabled ?? this.aiGuidanceEnabled,
      faithLayerEnabled: faithLayerEnabled ?? this.faithLayerEnabled,
      showStartupNotice: showStartupNotice ?? this.showStartupNotice,
      remoteAiFeaturesEnabled:
          remoteAiFeaturesEnabled ?? this.remoteAiFeaturesEnabled,
    );
  }
}
