enum GuardrailBlockReason {
  none,
  minorSexualContent,
  imminentSelfHarm,
  imminentViolence,
}

extension GuardrailBlockReasonX on GuardrailBlockReason {
  String get label {
    switch (this) {
      case GuardrailBlockReason.none:
        return 'None';
      case GuardrailBlockReason.minorSexualContent:
        return 'Minor sexual content';
      case GuardrailBlockReason.imminentSelfHarm:
        return 'Imminent self-harm';
      case GuardrailBlockReason.imminentViolence:
        return 'Imminent violence';
    }
  }

  String get userMessage {
    switch (this) {
      case GuardrailBlockReason.none:
        return '';
      case GuardrailBlockReason.minorSexualContent:
        return 'This prototype AI coach cannot process sexual content involving minors. Do not continue in chat.';
      case GuardrailBlockReason.imminentSelfHarm:
        return 'This prototype AI coach cannot handle imminent self-harm situations. In the U.S., call or text 988 right now, or call emergency services if you are in immediate danger.';
      case GuardrailBlockReason.imminentViolence:
        return 'This prototype AI coach cannot handle imminent violence situations. Step away from chat and contact emergency services if there is immediate danger.';
    }
  }
}

class GuardrailResult {
  final bool blocked;
  final GuardrailBlockReason reason;
  final String sanitizedText;
  final List<String> scrubbedFlags;

  const GuardrailResult({
    required this.blocked,
    required this.reason,
    required this.sanitizedText,
    required this.scrubbedFlags,
  });

  factory GuardrailResult.allowed({
    required String sanitizedText,
    required List<String> scrubbedFlags,
  }) {
    return GuardrailResult(
      blocked: false,
      reason: GuardrailBlockReason.none,
      sanitizedText: sanitizedText,
      scrubbedFlags: scrubbedFlags,
    );
  }

  factory GuardrailResult.blocked(GuardrailBlockReason reason) {
    return GuardrailResult(
      blocked: true,
      reason: reason,
      sanitizedText: '',
      scrubbedFlags: const <String>[],
    );
  }

  bool get wasSanitized => scrubbedFlags.isNotEmpty;
}
