import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/reminder_settings.dart';
import '../domain/risk_window.dart';

class RiskWindowRepository {
  static const String _riskWindowsKey = 'risk_windows';
  static const String _remindersEnabledKey = 'risk_window_reminders_enabled';
  static const String _leadMinutesKey = 'risk_window_lead_minutes';

  Future<List<RiskWindow>> getRiskWindows() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_riskWindowsKey);
    if (raw == null || raw.isEmpty) {
      return <RiskWindow>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => RiskWindow.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> saveRiskWindows(List<RiskWindow> windows) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(windows.map((item) => item.toMap()).toList());
    await prefs.setString(_riskWindowsKey, encoded);
  }

  Future<void> upsertRiskWindow(RiskWindow window) async {
    final existing = await getRiskWindows();
    final index = existing.indexWhere((item) => item.id == window.id);

    if (index >= 0) {
      existing[index] = window;
    } else {
      existing.add(window);
    }

    await saveRiskWindows(existing);
  }

  Future<void> deleteRiskWindow(String id) async {
    final existing = await getRiskWindows();
    existing.removeWhere((item) => item.id == id);
    await saveRiskWindows(existing);
  }

  Future<ReminderSettings> getReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return ReminderSettings(
      remindersEnabled: prefs.getBool(_remindersEnabledKey) ?? true,
      leadMinutes: prefs.getInt(_leadMinutesKey) ?? 10,
    );
  }

  Future<void> saveReminderSettings(ReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_remindersEnabledKey, settings.remindersEnabled);
    await prefs.setInt(_leadMinutesKey, settings.leadMinutes);
  }
}
