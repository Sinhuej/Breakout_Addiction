import '../domain/guardrail_result.dart';

class AiInputGuardrailService {
  GuardrailResult review(String input) {
    final lowered = input.toLowerCase();

    if (_containsMinorSexualContent(lowered)) {
      return GuardrailResult.blocked(GuardrailBlockReason.minorSexualContent);
    }

    if (_containsImminentSelfHarm(lowered)) {
      return GuardrailResult.blocked(GuardrailBlockReason.imminentSelfHarm);
    }

    if (_containsImminentViolence(lowered)) {
      return GuardrailResult.blocked(GuardrailBlockReason.imminentViolence);
    }

    final flags = <String>[];
    var sanitized = input;

    final emailPattern = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b');
    if (emailPattern.hasMatch(sanitized)) {
      sanitized = sanitized.replaceAll(emailPattern, '[email removed]');
      flags.add('email');
    }

    final phonePattern = RegExp(r'(\+?1[\s\-\.]?)?(\(?\d{3}\)?[\s\-\.]?)\d{3}[\s\-\.]?\d{4}');
    if (phonePattern.hasMatch(sanitized)) {
      sanitized = sanitized.replaceAll(phonePattern, '[phone removed]');
      flags.add('phone');
    }

    final addressPattern = RegExp(
      r'\b\d{1,5}\s+[A-Za-z0-9.\- ]+\s(?:street|st|road|rd|avenue|ave|lane|ln|drive|dr|boulevard|blvd|court|ct)\b',
      caseSensitive: false,
    );
    if (addressPattern.hasMatch(sanitized)) {
      sanitized = sanitized.replaceAll(addressPattern, '[address removed]');
      flags.add('address');
    }

    final fullNamePattern = RegExp(
      r'\bmy name is\s+[A-Z][a-z]+\s+[A-Z][a-z]+\b',
      caseSensitive: false,
    );
    if (fullNamePattern.hasMatch(sanitized)) {
      sanitized = sanitized.replaceAll(fullNamePattern, 'my name is [name removed]');
      flags.add('name');
    }

    final exactLocationPattern = RegExp(
      r'\bi live in\s+[A-Za-z .,-]{3,}\b',
      caseSensitive: false,
    );
    if (exactLocationPattern.hasMatch(sanitized)) {
      sanitized = sanitized.replaceAll(exactLocationPattern, 'I live in [location removed]');
      flags.add('location');
    }

    return GuardrailResult.allowed(
      sanitizedText: sanitized.trim(),
      scrubbedFlags: flags,
    );
  }

  bool _containsMinorSexualContent(String text) {
    final hasMinorWord = text.contains('minor') ||
        text.contains('underage') ||
        text.contains('child') ||
        text.contains('kid') ||
        text.contains('teen') ||
        text.contains('teenager') ||
        text.contains('13 year old') ||
        text.contains('14 year old') ||
        text.contains('15 year old') ||
        text.contains('16 year old') ||
        text.contains('17 year old');

    final hasSexualWord = text.contains('sex') ||
        text.contains('sexual') ||
        text.contains('porn') ||
        text.contains('nude') ||
        text.contains('naked') ||
        text.contains('explicit');

    return hasMinorWord && hasSexualWord;
  }

  bool _containsImminentSelfHarm(String text) {
    return text.contains('kill myself') ||
        text.contains('suicide') ||
        text.contains('end my life') ||
        text.contains('hurt myself tonight') ||
        text.contains('harm myself tonight') ||
        text.contains('i am going to hurt myself') ||
        text.contains('i am going to kill myself');
  }

  bool _containsImminentViolence(String text) {
    return text.contains('kill him') ||
        text.contains('kill her') ||
        text.contains('kill them') ||
        text.contains('shoot him') ||
        text.contains('shoot her') ||
        text.contains('hurt them tonight') ||
        text.contains('i am going to hurt someone') ||
        text.contains('i am going to kill someone');
  }
}
