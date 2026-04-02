#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

echo "==> Applying Breakout Addiction BA-30 Gemini prototype transport scaffold in: $ROOT_DIR"

mkdir -p \
  lib/features/ai_chat/data \
  tools

python3 - <<'EOD'
from pathlib import Path

pubspec = Path('pubspec.yaml')
text = pubspec.read_text(encoding='utf-8')
if '\n  http:' not in text:
    text = text.replace(
        "  url_launcher: ^6.3.0\n",
        "  url_launcher: ^6.3.0\n  http: ^1.2.2\n",
    )
pubspec.write_text(text, encoding='utf-8')
print('Patched pubspec.yaml')

repo_path = Path('lib/features/ai_chat/data/ai_backend_config_repository.dart')
repo_text = repo_path.read_text(encoding='utf-8')

if 'Future<String?> getApiKey() async {' not in repo_text:
    repo_text = repo_text.replace(
        "  Future<void> clearApiKey() async {\n    await _secureStorage.delete(key: _apiKeyStorageKey);\n  }\n}",
        "  Future<String?> getApiKey() async {\n    return _secureStorage.read(key: _apiKeyStorageKey);\n  }\n\n  Future<void> clearApiKey() async {\n    await _secureStorage.delete(key: _apiKeyStorageKey);\n  }\n}",
    )

repo_path.write_text(repo_text, encoding='utf-8')
print('Patched ai_backend_config_repository.dart')
EOD

cat > lib/features/ai_chat/data/gemini_http_transport.dart <<'EOD'
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/ai_backend_config.dart';
import '../domain/chat_message.dart';
import 'ai_backend_config_repository.dart';
import 'ai_remote_transport.dart';

class GeminiHttpTransport implements AiRemoteTransport {
  static const String _defaultBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  final AiBackendConfigRepository _configRepository =
      AiBackendConfigRepository();

  String _effectiveBaseUrl(String configured) {
    final trimmed = configured.trim();
    if (trimmed.isEmpty || trimmed.contains('aiplatform.googleapis.com')) {
      return _defaultBaseUrl;
    }
    return trimmed;
  }

  List<Map<String, dynamic>> _buildContents(List<ChatMessage> messages) {
    final recent = messages.length > 8
        ? messages.sublist(messages.length - 8)
        : messages;

    return recent
        .map(
          (message) => <String, dynamic>{
            'role': message.role == ChatRole.user ? 'user' : 'model',
            'parts': <Map<String, dynamic>>[
              <String, dynamic>{'text': message.text},
            ],
          },
        )
        .toList();
  }

  String _extractText(Map<String, dynamic> decoded) {
    final candidates = decoded['candidates'];
    if (candidates is List && candidates.isNotEmpty) {
      final first = candidates.first;
      if (first is Map<String, dynamic>) {
        final content = first['content'];
        if (content is Map<String, dynamic>) {
          final parts = content['parts'];
          if (parts is List) {
            final texts = <String>[];
            for (final part in parts) {
              if (part is Map<String, dynamic>) {
                final text = part['text'];
                if (text is String && text.trim().isNotEmpty) {
                  texts.add(text.trim());
                }
              }
            }
            if (texts.isNotEmpty) {
              return texts.join('\n\n');
            }
          }
        }
      }
    }

    final promptFeedback = decoded['promptFeedback'];
    if (promptFeedback is Map<String, dynamic>) {
      final blockReason = promptFeedback['blockReason'];
      if (blockReason is String && blockReason.isNotEmpty) {
        return 'Gemini prototype call was blocked by the API: $blockReason.';
      }
    }

    return 'Gemini prototype returned no text.';
  }

  @override
  Future<String> send({
    required List<ChatMessage> messages,
    required String userInput,
    required AiBackendConfig config,
  }) async {
    final apiKey = await _configRepository.getApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      return 'Gemini prototype path is selected, but no API key is saved.';
    }

    final baseUrl = _effectiveBaseUrl(config.apiBaseUrl);
    final normalizedBase =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

    final uri = Uri.parse(
      '$normalizedBase/models/${config.modelName}:generateContent',
    );

    final body = <String, dynamic>{
      'contents': _buildContents(messages),
      'generationConfig': <String, dynamic>{
        'temperature': 0.6,
        'maxOutputTokens': 240,
      },
    };

    try {
      final response = await http
          .post(
            uri,
            headers: <String, String>{
              'Content-Type': 'application/json',
              'x-goog-api-key': apiKey.trim(),
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return 'Gemini prototype remote call failed (${response.statusCode}). Keep using sanitized prompts only.';
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return 'Gemini prototype returned an unreadable response.';
      }

      final text = _extractText(decoded);
      return 'Gemini prototype reply:\n\n$text';
    } on TimeoutException {
      return 'Gemini prototype remote call timed out. Keep using sanitized prompts only.';
    } catch (_) {
      return 'Gemini prototype remote call could not complete. Keep using sanitized prompts only.';
    }
  }
}
EOD
cat > lib/features/ai_chat/data/gemini_prototype_provider.dart <<'EOD'
import '../domain/chat_message.dart';
import '../domain/chat_provider.dart';
import 'ai_backend_config_repository.dart';
import 'ai_backend_preflight_service.dart';
import 'ai_remote_transport.dart';

class GeminiPrototypeProvider implements ChatProvider {
  final AiRemoteTransport transport;
  final AiBackendPreflightService _preflightService =
      AiBackendPreflightService();
  final AiBackendConfigRepository _configRepository =
      AiBackendConfigRepository();

  GeminiPrototypeProvider({
    required this.transport,
  });

  @override
  Future<ChatMessage> generateReply({
    required List<ChatMessage> messages,
    required String userInput,
  }) async {
    final preflight = await _preflightService.run();

    if (!preflight.readyForRemoteStub) {
      final blockers = preflight.blockerLines.isEmpty
          ? ''
          : ' ${preflight.blockerLines.join(' ')}';

      return ChatMessage(
        role: ChatRole.assistant,
        text:
            'Gemini prototype mode is selected, but the live prototype path is not armed yet. ${preflight.summaryLine}$blockers',
        timestamp: DateTime.now(),
      );
    }

    final config = await _configRepository.getConfig();

    final text = await transport.send(
      messages: messages,
      userInput: userInput,
      config: config,
    );

    return ChatMessage(
      role: ChatRole.assistant,
      text: text,
      timestamp: DateTime.now(),
    );
  }
}
EOD

python3 - <<'EOD'
from pathlib import Path

factory_path = Path('lib/features/ai_chat/data/chat_provider_factory.dart')
text = factory_path.read_text(encoding='utf-8')

if "import 'gemini_http_transport.dart';" not in text:
    text = text.replace(
        "import 'gemini_prototype_provider.dart';\n",
        "import 'gemini_prototype_provider.dart';\nimport 'gemini_http_transport.dart';\n",
    )

text = text.replace(
"""      case ChatProviderMode.geminiPrototype:
        return GeminiPrototypeProvider();
""",
"""      case ChatProviderMode.geminiPrototype:
        return GeminiPrototypeProvider(
          transport: GeminiHttpTransport(),
        );
""")

factory_path.write_text(text, encoding='utf-8')
print('Patched chat_provider_factory.dart')
EOD
cat > lib/features/ai_chat/data/ai_backend_preflight_service.dart <<'EOD'
import '../../premium/data/premium_access_repository.dart';
import '../../settings/data/feature_control_settings_repository.dart';
import '../domain/ai_preflight_status.dart';
import '../domain/chat_provider_mode.dart';
import 'ai_backend_config_repository.dart';
import 'ai_chat_settings_repository.dart';
import 'ai_runtime_gate_repository.dart';

class AiBackendPreflightService {
  final PremiumAccessRepository _premiumRepository =
      PremiumAccessRepository();
  final AiChatSettingsRepository _settingsRepository =
      AiChatSettingsRepository();
  final AiBackendConfigRepository _backendRepository =
      AiBackendConfigRepository();
  final AiRuntimeGateRepository _runtimeGateRepository =
      AiRuntimeGateRepository();
  final FeatureControlSettingsRepository _featureRepository =
      FeatureControlSettingsRepository();

  Future<AiPreflightStatus> run() async {
    final premium = await _premiumRepository.getStatus();
    final settings = await _settingsRepository.getSettings();
    final backend = await _backendRepository.getConfig();
    final remoteEnabled = await _runtimeGateRepository.getRemotePathEnabled();
    final featureSettings = await _featureRepository.getSettings();

    final providerSupportsRemotePath =
        settings.providerMode == ChatProviderMode.geminiPrototype ||
            settings.providerMode == ChatProviderMode.vertexPrivateReady;

    final providerIsVertex =
        settings.providerMode == ChatProviderMode.vertexPrivateReady;
    final providerIsGemini =
        settings.providerMode == ChatProviderMode.geminiPrototype;

    final riskyFeaturesForcedOff = !backend.allowGrounding &&
        !backend.allowMapsGrounding &&
        !backend.allowSessionMemory &&
        !backend.allowFileUploads;

    final blockers = <String>[];

    if (!premium.hasAiPremium) {
      blockers.add('Breakout Plus AI is not active.');
    }
    if (!featureSettings.aiChatEnabled) {
      blockers.add('AI chat is disabled in Feature Controls.');
    }
    if (!featureSettings.remoteAiFeaturesEnabled) {
      blockers.add('Remote AI features are disabled in Feature Controls.');
    }
    if (!providerSupportsRemotePath) {
      blockers.add('Selected provider does not use a remote path.');
    }
    if (!remoteEnabled) {
      blockers.add('Remote backend path is disabled.');
    }
    if (!backend.hasApiKey) {
      blockers.add('No API key is saved.');
    }
    if (!riskyFeaturesForcedOff) {
      blockers.add('One or more risky features are enabled.');
    }

    final readyForRemoteStub = premium.hasAiPremium &&
        featureSettings.aiChatEnabled &&
        featureSettings.remoteAiFeaturesEnabled &&
        providerSupportsRemotePath &&
        remoteEnabled &&
        backend.hasApiKey &&
        riskyFeaturesForcedOff;

    String summaryLine;
    if (readyForRemoteStub && providerIsGemini) {
      summaryLine =
          'Gemini prototype remote path is armed. Not confidential. Only sanitized prompts should be used.';
    } else if (readyForRemoteStub && providerIsVertex) {
      summaryLine =
          'Remote paid path is armed, but it is still routed to a stub transport until the live cutover is built.';
    } else if (settings.providerMode == ChatProviderMode.mock) {
      summaryLine = 'Local mock mode is active. No cloud path is armed.';
    } else if (providerIsGemini) {
      summaryLine =
          'Gemini prototype mode is selected, but the real remote call path is still blocked by one or more preflight checks.';
    } else {
      summaryLine =
          'Vertex private-ready mode is selected, but the paid path is still blocked by one or more preflight checks.';
    }

    return AiPreflightStatus(
      premiumUnlocked: premium.hasAiPremium,
      providerModeLabel: settings.providerMode.label,
      providerIsVertexPrivateReady: providerIsVertex,
      remotePathEnabled: remoteEnabled,
      apiKeyPresent: backend.hasApiKey,
      riskyFeaturesForcedOff: riskyFeaturesForcedOff,
      readyForRemoteStub: readyForRemoteStub,
      summaryLine: summaryLine,
      blockerLines: blockers,
    );
  }
}
EOD
python3 - <<'EOD'
from pathlib import Path

ai_chat_path = Path('lib/features/ai_chat/presentation/ai_chat_screen.dart')
ai_text = ai_chat_path.read_text(encoding='utf-8')

old_banner = """            Text(
              'Gemini prototype placeholder mode is active. Not confidential. Use sanitized dummy prompts only.',
              style: AppTypography.muted,
            ),
"""
new_banner = """            Text(
              'Gemini prototype mode is active. Not confidential. Only sanitized prompts should be used. When Plus AI, Feature Controls, API key, and the remote gate are all enabled, this mode can send a real prototype cloud request.',
              style: AppTypography.muted,
            ),
"""
if old_banner in ai_text:
    ai_text = ai_text.replace(old_banner, new_banner)

ai_chat_path.write_text(ai_text, encoding='utf-8')
print('Patched ai_chat_screen.dart')

premium_path = Path('lib/features/premium/presentation/premium_screen.dart')
premium_text = premium_path.read_text(encoding='utf-8')

old_text = """                  'Choose the prototype provider path. Keep using sanitized dummy prompts only until the real privacy-safe backend is ready.',
"""
new_text = """                  'Choose the prototype provider path. Gemini Prototype can make a real cloud prototype call only when Plus AI, feature toggles, API key, and the remote gate are all enabled. It is still not confidential.',
"""
if old_text in premium_text:
    premium_text = premium_text.replace(old_text, new_text)

premium_path.write_text(premium_text, encoding='utf-8')
print('Patched premium_screen.dart')
EOD
cat > tools/verify_ba30.py <<'EOD'
from pathlib import Path
import sys

REQUIRED = [
    'pubspec.yaml',
    'lib/features/ai_chat/data/ai_backend_config_repository.dart',
    'lib/features/ai_chat/data/gemini_http_transport.dart',
    'lib/features/ai_chat/data/gemini_prototype_provider.dart',
    'lib/features/ai_chat/data/chat_provider_factory.dart',
    'lib/features/ai_chat/data/ai_backend_preflight_service.dart',
    'lib/features/ai_chat/presentation/ai_chat_screen.dart',
    'lib/features/premium/presentation/premium_screen.dart',
]

REQUIRED_TEXT = {
    'pubspec.yaml': 'http: ^1.2.2',
    'lib/features/ai_chat/data/ai_backend_config_repository.dart': 'Future<String?> getApiKey() async',
    'lib/features/ai_chat/data/gemini_http_transport.dart': 'x-goog-api-key',
    'lib/features/ai_chat/data/gemini_prototype_provider.dart': 'live prototype path is not armed yet',
    'lib/features/ai_chat/data/chat_provider_factory.dart': 'transport: GeminiHttpTransport()',
    'lib/features/ai_chat/data/ai_backend_preflight_service.dart': 'Gemini prototype remote path is armed.',
    'lib/features/ai_chat/presentation/ai_chat_screen.dart': 'this mode can send a real prototype cloud request',
    'lib/features/premium/presentation/premium_screen.dart': 'Gemini Prototype can make a real cloud prototype call',
}

def main() -> int:
    root = Path.cwd()

    missing = [path for path in REQUIRED if not (root / path).exists()]
    if missing:
        print('Missing files:')
        for item in missing:
            print(f' - {item}')
        return 1

    bad = []
    for path, needle in REQUIRED_TEXT.items():
        text = (root / path).read_text(encoding='utf-8')
        if needle not in text:
            bad.append((path, needle))

    if bad:
        print('Content checks failed:')
        for path, needle in bad:
            print(f' - {path} missing: {needle}')
        return 1

    print('Breakout Addiction BA-30 Gemini prototype transport verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
EOD

echo "==> BA-30 Gemini prototype transport scaffold written."
echo "==> Running Python verification..."
python3 tools/verify_ba30.py
