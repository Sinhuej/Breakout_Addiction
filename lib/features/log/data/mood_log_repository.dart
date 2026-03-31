import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/mood_entry.dart';

class MoodLogRepository {
  static const String _storageKey = 'mood_logs';

  Future<List<MoodEntry>> getEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return <MoodEntry>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (item) => MoodEntry.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> saveEntry(MoodEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getEntries();
    final updated = <MoodEntry>[entry, ...existing];
    final encoded = jsonEncode(updated.map((item) => item.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
