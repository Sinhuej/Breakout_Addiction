import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/chat_message.dart';

class AiChatRepository {
  static const String _storageKey = 'ai_chat_messages';

  Future<List<ChatMessage>> getMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return <ChatMessage>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (item) => ChatMessage.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<void> saveMessages(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(messages.map((item) => item.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> clearMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
