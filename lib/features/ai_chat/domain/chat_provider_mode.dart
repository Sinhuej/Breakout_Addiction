enum ChatProviderMode {
  mock,
  geminiPrototype,
}

extension ChatProviderModeX on ChatProviderMode {
  String get label {
    switch (this) {
      case ChatProviderMode.mock:
        return 'Mock';
      case ChatProviderMode.geminiPrototype:
        return 'Gemini Prototype';
    }
  }

  String get description {
    switch (this) {
      case ChatProviderMode.mock:
        return 'Local prototype replies only. No cloud calls.';
      case ChatProviderMode.geminiPrototype:
        return 'Cloud-ready prototype mode placeholder. Keep using sanitized dummy prompts only.';
    }
  }
}
