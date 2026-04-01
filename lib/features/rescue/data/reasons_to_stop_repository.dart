import 'package:shared_preferences/shared_preferences.dart';

class ReasonsToStopRepository {
  static const String _storageKey = 'reasons_to_stop';

  static const List<String> _defaultReasons = <String>[
    'Self-respect',
    'Mental clarity',
    'Relationships',
    'Peace',
  ];

  Future<List<String>> getReasons() async {
    final prefs = await SharedPreferences.getInstance();
    final reasons = prefs.getStringList(_storageKey);
    if (reasons == null || reasons.isEmpty) {
      return _defaultReasons;
    }
    return reasons;
  }

  Future<void> saveReasons(List<String> reasons) async {
    final prefs = await SharedPreferences.getInstance();
    final cleaned = reasons
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    await prefs.setStringList(_storageKey, cleaned);
  }
}
