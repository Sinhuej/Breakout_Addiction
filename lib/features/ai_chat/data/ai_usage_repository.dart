import 'package:shared_preferences/shared_preferences.dart';

import '../domain/ai_usage_snapshot.dart';

class AiUsageRepository {
  static const String _promptAttemptsKey = 'ai_usage_prompt_attempts';
  static const String _stoppedAttemptsKey = 'ai_usage_stopped_attempts';
  static const String _livePrototypeCallsKey = 'ai_usage_live_prototype_calls';
  static const String _localOrStubRepliesKey = 'ai_usage_local_or_stub_replies';
  static const String _lastModeLabelKey = 'ai_usage_last_mode_label';

  Future<AiUsageSnapshot> getSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    return AiUsageSnapshot(
      promptAttempts: prefs.getInt(_promptAttemptsKey) ?? 0,
      stoppedAttempts: prefs.getInt(_stoppedAttemptsKey) ?? 0,
      livePrototypeCalls: prefs.getInt(_livePrototypeCallsKey) ?? 0,
      localOrStubReplies: prefs.getInt(_localOrStubRepliesKey) ?? 0,
      lastModeLabel: prefs.getString(_lastModeLabelKey) ?? 'No activity yet',
    );
  }

  Future<void> recordStoppedAttempt({
    required String modeLabel,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _promptAttemptsKey,
      (prefs.getInt(_promptAttemptsKey) ?? 0) + 1,
    );
    await prefs.setInt(
      _stoppedAttemptsKey,
      (prefs.getInt(_stoppedAttemptsKey) ?? 0) + 1,
    );
    await prefs.setString(_lastModeLabelKey, modeLabel);
  }

  Future<void> recordSuccessfulReply({
    required String modeLabel,
    required bool livePrototype,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _promptAttemptsKey,
      (prefs.getInt(_promptAttemptsKey) ?? 0) + 1,
    );

    if (livePrototype) {
      await prefs.setInt(
        _livePrototypeCallsKey,
        (prefs.getInt(_livePrototypeCallsKey) ?? 0) + 1,
      );
    } else {
      await prefs.setInt(
        _localOrStubRepliesKey,
        (prefs.getInt(_localOrStubRepliesKey) ?? 0) + 1,
      );
    }

    await prefs.setString(_lastModeLabelKey, modeLabel);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_promptAttemptsKey);
    await prefs.remove(_stoppedAttemptsKey);
    await prefs.remove(_livePrototypeCallsKey);
    await prefs.remove(_localOrStubRepliesKey);
    await prefs.remove(_lastModeLabelKey);
  }
}
