import 'package:shared_preferences/shared_preferences.dart';

import '../domain/daily_quote.dart';

class QuotePreferencesRepository {
  static const String _modeKey = 'quote_mode';
  static const String _religionKey = 'quote_religion';

  Future<QuoteMode> getMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_modeKey);
    if (raw == null || raw.isEmpty) {
      return QuoteMode.recovery;
    }
    return QuoteMode.values.byName(raw);
  }

  Future<void> saveMode(QuoteMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.name);
  }

  Future<String> getReligionTag() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_religionKey) ?? 'Christian';
  }

  Future<void> saveReligionTag(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_religionKey, value);
  }
}
