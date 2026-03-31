import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/cycle_stage_log_entry.dart';

class CycleStageLogRepository {
  static const String _storageKey = 'cycle_stage_logs';

  Future<List<CycleStageLogEntry>> getEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return <CycleStageLogEntry>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (item) => CycleStageLogEntry.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> saveEntry(CycleStageLogEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getEntries();
    final updated = <CycleStageLogEntry>[entry, ...existing];
    final encoded = jsonEncode(updated.map((item) => item.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
