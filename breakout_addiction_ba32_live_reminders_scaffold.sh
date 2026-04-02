#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

echo "==> Applying Breakout Addiction BA-32 live reminders scaffold in: $ROOT_DIR"

mkdir -p \
  lib/features/notifications/data \
  tools

python3 - <<'EOD'
from pathlib import Path

pubspec = Path('pubspec.yaml')
text = pubspec.read_text(encoding='utf-8')

for needle, replacement in [
    (
        "  url_launcher: ^6.3.0\n",
        "  url_launcher: ^6.3.0\n  flutter_local_notifications: ^21.0.0\n  flutter_timezone: ^5.0.2\n  timezone: ^0.11.0\n",
    ),
]:
    if "flutter_local_notifications:" not in text:
        text = text.replace(needle, replacement)

pubspec.write_text(text, encoding='utf-8')
print('Patched pubspec.yaml')
EOD

cat > lib/features/notifications/data/breakout_notification_service.dart <<'EOD'
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class BreakoutNotificationService {
  BreakoutNotificationService._();

  static final BreakoutNotificationService instance =
      BreakoutNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String riskChannelId = 'breakout_risk_windows';
  static const String riskChannelName = 'Risk Window Reminders';
  static const String riskChannelDescription =
      'Proactive reminders before high-risk windows begin.';

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz.initializeTimeZones();

    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      // Keep timezone defaults if device lookup fails.
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(initSettings);

    const androidChannel = AndroidNotificationChannel(
      riskChannelId,
      riskChannelName,
      description: riskChannelDescription,
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
  }

  Future<void> requestPermissions() async {
    await initialize();

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
        break;
      case TargetPlatform.iOS:
        await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        break;
      case TargetPlatform.macOS:
        await _plugin
            .resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        break;
      default:
        break;
    }
  }

  tz.TZDateTime nextOccurrence({
    required int hour,
    required int minute,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String payload,
  }) async {
    await initialize();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        riskChannelId,
        riskChannelName,
        channelDescription: riskChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      nextOccurrence(hour: hour, minute: minute),
      details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancel(int id) async {
    await initialize();
    await _plugin.cancel(id);
  }
}
EOD
cat > lib/features/notifications/data/risk_window_reminder_sync_service.dart <<'EOD'
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
EOD
cat > lib/features/risk/presentation/risk_windows_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../notifications/data/breakout_notification_service.dart';
import '../../notifications/data/risk_window_reminder_sync_service.dart';
import '../data/risk_window_repository.dart';
import '../domain/reminder_settings.dart';
import '../domain/risk_window.dart';

class RiskWindowsScreen extends StatefulWidget {
  const RiskWindowsScreen({super.key});

  @override
  State<RiskWindowsScreen> createState() => _RiskWindowsScreenState();
}

class _RiskWindowsScreenState extends State<RiskWindowsScreen> {
  final RiskWindowRepository _repository = RiskWindowRepository();
  final RiskWindowReminderSyncService _syncService =
      RiskWindowReminderSyncService();

  List<RiskWindow> _windows = <RiskWindow>[];
  ReminderSettings _settings = ReminderSettings.defaults();
  bool _loading = true;

  static const List<int> _minuteOptions = <int>[0, 15, 30, 45];
  static const List<int> _leadOptions = <int>[5, 10, 15, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final windows = await _repository.getRiskWindows();
    final settings = await _repository.getReminderSettings();

    if (!mounted) {
      return;
    }

    setState(() {
      _windows = windows;
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _requestPermission() async {
    await BreakoutNotificationService.instance.requestPermissions();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification permission request sent.')),
    );
  }

  Future<void> _syncReminders() async {
    final result = await _syncService.sync();
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.remindersEnabled
              ? 'Live reminders synced: ${result.scheduledCount} scheduled, ${result.cancelledCount} cleared.'
              : 'Reminder prep is off. ${result.cancelledCount} reminders cleared.',
        ),
      ),
    );
  }

  Future<void> _saveSettings(ReminderSettings settings) async {
    await _repository.saveReminderSettings(settings);
    if (!mounted) {
      return;
    }
    setState(() => _settings = settings);
    await _syncReminders();
  }

  Future<void> _deleteWindow(String id) async {
    await _repository.deleteRiskWindow(id);
    await _load();
    await _syncReminders();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Risk window removed.')),
    );
  }

  Future<void> _showWindowSheet({RiskWindow? existing}) async {
    final labelController = TextEditingController(
      text: existing?.label ?? '',
    );

    int startHour = existing?.startHour ?? 22;
    int startMinute = existing?.startMinute ?? 0;
    int endHour = existing?.endHour ?? 23;
    int endMinute = existing?.endMinute ?? 0;
    bool enabled = existing?.isEnabled ?? true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existing == null ? 'Add Risk Window' : 'Edit Risk Window',
                    style: AppTypography.title,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: labelController,
                    decoration: const InputDecoration(
                      labelText: 'Label',
                      hintText: 'Example: Late Night',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: startHour,
                          decoration: const InputDecoration(
                            labelText: 'Start Hour',
                          ),
                          items: List.generate(
                            24,
                            (index) => DropdownMenuItem<int>(
                              value: index,
                              child: Text(index.toString().padLeft(2, '0')),
                            ),
                          ),
                          onChanged: (value) {
                            if (value == null) return;
                            setSheetState(() => startHour = value);
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: startMinute,
                          decoration: const InputDecoration(
                            labelText: 'Start Min',
                          ),
                          items: _minuteOptions
                              .map(
                                (value) => DropdownMenuItem<int>(
                                  value: value,
                                  child: Text(value.toString().padLeft(2, '0')),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setSheetState(() => startMinute = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: endHour,
                          decoration: const InputDecoration(
                            labelText: 'End Hour',
                          ),
                          items: List.generate(
                            24,
                            (index) => DropdownMenuItem<int>(
                              value: index,
                              child: Text(index.toString().padLeft(2, '0')),
                            ),
                          ),
                          onChanged: (value) {
                            if (value == null) return;
                            setSheetState(() => endHour = value);
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: endMinute,
                          decoration: const InputDecoration(
                            labelText: 'End Min',
                          ),
                          items: _minuteOptions
                              .map(
                                (value) => DropdownMenuItem<int>(
                                  value: value,
                                  child: Text(value.toString().padLeft(2, '0')),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setSheetState(() => endMinute = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: enabled,
                    onChanged: (value) => setSheetState(() => enabled = value),
                    title: const Text('Enabled'),
                    subtitle: const Text('Use this window for live reminders.'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    label: existing == null ? 'Save Risk Window' : 'Update Risk Window',
                    icon: Icons.schedule_outlined,
                    onPressed: () async {
                      final label = labelController.text.trim();
                      if (label.isEmpty) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          const SnackBar(content: Text('Add a label for this risk window.')),
                        );
                        return;
                      }

                      final window = RiskWindow(
                        id: existing?.id ??
                            DateTime.now().microsecondsSinceEpoch.toString(),
                        label: label,
                        startHour: startHour,
                        startMinute: startMinute,
                        endHour: endHour,
                        endMinute: endMinute,
                        isEnabled: enabled,
                      );

                      await _repository.upsertRiskWindow(window);

                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }

                      await _load();
                      await _syncReminders();

                      if (!mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            existing == null
                                ? 'Risk window saved.'
                                : 'Risk window updated.',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _windowCard(RiskWindow window) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(window.label, style: AppTypography.section),
          const SizedBox(height: AppSpacing.sm),
          Text(window.timeRange, style: AppTypography.body),
          const SizedBox(height: 6),
          Text(
            window.isEnabled ? 'Enabled' : 'Disabled',
            style: AppTypography.muted,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showWindowSheet(existing: window),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deleteWindow(window.id),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Risk Windows')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Risk Windows')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Get ahead of the risky moments.', style: AppTypography.title),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Define the times when you are more vulnerable so the app can become proactive with real local reminders.',
            style: AppTypography.muted,
          ),
          const SizedBox(height: AppSpacing.lg),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Live Reminder Status', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _settings.remindersEnabled
                      ? 'Reminder prep is on.'
                      : 'Reminder prep is off.',
                  style: AppTypography.body,
                ),
                const SizedBox(height: 8),
                Text(
                  'Lead time: ${_settings.leadMinutes} minutes before each enabled risk window.',
                  style: AppTypography.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Request Notification Permission',
                  icon: Icons.notifications_active_outlined,
                  onPressed: _requestPermission,
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _syncReminders,
                    icon: const Icon(Icons.sync_outlined),
                    label: const Text('Sync Live Reminders'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reminder Settings', style: AppTypography.section),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _settings.remindersEnabled,
                  onChanged: (value) {
                    _saveSettings(
                      _settings.copyWith(remindersEnabled: value),
                    );
                  },
                  title: const Text('Enable Live Reminders'),
                  subtitle: const Text(
                    'Schedules local notifications before enabled risk windows.',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<int>(
                  initialValue: _settings.leadMinutes,
                  decoration: const InputDecoration(
                    labelText: 'Lead Time',
                  ),
                  items: _leadOptions
                      .map(
                        (value) => DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value minutes before'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    _saveSettings(
                      _settings.copyWith(leadMinutes: value),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Add Risk Window',
            icon: Icons.add_alert_outlined,
            onPressed: () => _showWindowSheet(),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_windows.isEmpty)
            const InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No Risk Windows Yet', style: AppTypography.section),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Add a few recurring high-risk times like late night, after work, or weekends.',
                    style: AppTypography.muted,
                  ),
                ],
              ),
            )
          else
            for (final window in _windows) ...[
              _windowCard(window),
              const SizedBox(height: AppSpacing.md),
            ],
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, RouteNames.home);
              break;
            case 1:
              Navigator.pushReplacementNamed(context, RouteNames.rescue);
              break;
            case 2:
              Navigator.pushReplacementNamed(context, RouteNames.logHub);
              break;
            case 3:
              Navigator.pushReplacementNamed(context, RouteNames.educate);
              break;
            case 4:
              Navigator.pushReplacementNamed(context, RouteNames.support);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.flash_on_outlined), label: 'Rescue'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_note_outlined), label: 'Log'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: 'Learn'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent_outlined), label: 'Support'),
        ],
      ),
    );
  }
}
EOD
python3 - <<'EOD'
from pathlib import Path

main_path = Path('lib/main.dart')
main_text = main_path.read_text(encoding='utf-8')

if "breakout_notification_service.dart" not in main_text:
    main_text = main_text.replace(
        "import 'app/breakout_app.dart';\n",
        "import 'app/breakout_app.dart';\nimport 'features/notifications/data/breakout_notification_service.dart';\n",
    )

main_text = main_text.replace(
"""void main() {
  runApp(const BreakoutApp());
}
""",
"""Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BreakoutNotificationService.instance.initialize();
  runApp(const BreakoutApp());
}
""",
)

main_path.write_text(main_text, encoding='utf-8')
print('Patched main.dart')

support_path = Path('lib/features/support/presentation/support_screen.dart')
support_text = support_path.read_text(encoding='utf-8')

anchor = "PrimaryButton(\n                  label: 'Open Feature Controls',"
insert = """PrimaryButton(
                  label: 'Open Risk Windows',
                  icon: Icons.schedule_outlined,
                  onPressed: () => Navigator.pushNamed(
                    context,
                    RouteNames.riskWindows,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                PrimaryButton(
                  label: 'Open Feature Controls',"""

if "label: 'Open Risk Windows'" not in support_text and anchor in support_text:
    support_text = support_text.replace(anchor, insert, 1)

support_path.write_text(support_text, encoding='utf-8')
print('Patched support_screen.dart')
EOD
cat > tools/verify_ba32.py <<'EOD'
from pathlib import Path
import sys

REQUIRED = [
    'pubspec.yaml',
    'lib/features/notifications/data/breakout_notification_service.dart',
    'lib/features/notifications/data/risk_window_reminder_sync_service.dart',
    'lib/features/risk/presentation/risk_windows_screen.dart',
    'lib/main.dart',
    'lib/features/support/presentation/support_screen.dart',
]

REQUIRED_TEXT = {
    'pubspec.yaml': 'flutter_local_notifications: ^21.0.0',
    'lib/features/notifications/data/breakout_notification_service.dart': 'scheduleDailyReminder',
    'lib/features/notifications/data/risk_window_reminder_sync_service.dart': 'RiskWindowReminderSyncResult',
    'lib/features/risk/presentation/risk_windows_screen.dart': 'Sync Live Reminders',
    'lib/main.dart': 'await BreakoutNotificationService.instance.initialize();',
    'lib/features/support/presentation/support_screen.dart': "label: 'Open Risk Windows'",
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

    print('Breakout Addiction BA-32 live reminders verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
EOD

echo "==> BA-32 live reminders scaffold written."
echo "==> Running Python verification..."
python3 tools/verify_ba32.py
