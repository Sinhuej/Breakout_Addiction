enum ChatProviderMode {
  mock,
  geminiPrototype,
  vertexPrivateReady,
}

extension ChatProviderModeX on ChatProviderMode {
  String get label {
    switch (this) {
      case ChatProviderMode.mock:
        return 'Mock';
      case ChatProviderMode.geminiPrototype:
        return 'Gemini Prototype';
      case ChatProviderMode.vertexPrivateReady:
        return 'Vertex Private Ready';
    }
  }

  String get description {
    switch (this) {
      case ChatProviderMode.mock:
        return 'Local prototype replies only. No cloud calls.';
      case ChatProviderMode.geminiPrototype:
        return 'Cloud-ready prototype placeholder. Use sanitized dummy prompts only.';
      case ChatProviderMode.vertexPrivateReady:
        return 'Paid privacy-first configuration placeholder for later Vertex cutover. No live API call yet.';
    }
  }
}
