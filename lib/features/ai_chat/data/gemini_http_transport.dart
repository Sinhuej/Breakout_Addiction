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
