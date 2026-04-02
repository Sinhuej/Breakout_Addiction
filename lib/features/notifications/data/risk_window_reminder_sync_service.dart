import '../../risk/data/risk_window_repository.dart';
import '../../risk/domain/risk_window.dart';
import 'breakout_notification_service.dart';

class RiskWindowReminderSyncResult {
  final int scheduledCount;
  final int cancelledCount;
  final bool remindersEnabled;

  const RiskWindowReminderSyncResult({
    required this.scheduledCount,
    required this.cancelledCount,
    required this.remindersEnabled,
  });
}

class RiskWindowReminderSyncService {
  final RiskWindowRepository _repository = RiskWindowRepository();
  final BreakoutNotificationService _notifications =
      BreakoutNotificationService.instance;

  int _stableNotificationId(String rawId) {
    var hash = 17;
    for (final codeUnit in rawId.codeUnits) {
      hash = 37 * hash + codeUnit;
    }
    return 42000 + hash.abs() % 10000;
  }

  ({int hour, int minute}) _subtractLead({
    required int hour,
    required int minute,
    required int leadMinutes,
  }) {
    final totalMinutes = (hour * 60 + minute - leadMinutes) % (24 * 60);
    final normalized = totalMinutes < 0 ? totalMinutes + 24 * 60 : totalMinutes;

    return (
      hour: normalized ~/ 60,
      minute: normalized % 60,
    );
  }

  String _titleFor(RiskWindow window) {
    return 'Breakout check-in: ${window.label}';
  }

  String _bodyFor(int leadMinutes) {
    return 'Your high-risk window starts in $leadMinutes minutes. Open Breakout early and interrupt the pattern sooner.';
  }

  Future<RiskWindowReminderSyncResult> sync() async {
    await _notifications.initialize();

    final windows = await _repository.getRiskWindows();
    final settings = await _repository.getReminderSettings();

    var scheduledCount = 0;
    var cancelledCount = 0;

    for (final window in windows) {
      final id = _stableNotificationId(window.id);

      if (!settings.remindersEnabled || !window.isEnabled) {
        await _notifications.cancel(id);
        cancelledCount++;
        continue;
      }

      final lead = _subtractLead(
        hour: window.startHour,
        minute: window.startMinute,
        leadMinutes: settings.leadMinutes,
      );

      await _notifications.scheduleDailyReminder(
        id: id,
        title: _titleFor(window),
        body: _bodyFor(settings.leadMinutes),
        hour: lead.hour,
        minute: lead.minute,
        payload: 'risk_window:${window.id}',
      );

      scheduledCount++;
    }

    return RiskWindowReminderSyncResult(
      scheduledCount: scheduledCount,
      cancelledCount: cancelledCount,
      remindersEnabled: settings.remindersEnabled,
    );
  }
}
