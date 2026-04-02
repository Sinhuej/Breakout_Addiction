import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
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

  Future<void> _saveSettings(ReminderSettings settings) async {
    await _repository.saveReminderSettings(settings);
    if (!mounted) {
      return;
    }
    setState(() => _settings = settings);
  }

  Future<void> _deleteWindow(String id) async {
    await _repository.deleteRiskWindow(id);
    await _load();
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
                      border: OutlineInputBorder(),
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
                            border: OutlineInputBorder(),
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
                            border: OutlineInputBorder(),
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
                            border: OutlineInputBorder(),
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
                            border: OutlineInputBorder(),
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
                    subtitle: const Text('Use this window for proactive reminders later.'),
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
                      if (!mounted) {
                        return;
                      }

                      await _load();
                      if (!mounted || !sheetContext.mounted) {
                        return;
                      }

                      Navigator.of(sheetContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(existing == null
                              ? 'Risk window saved.'
                              : 'Risk window updated.'),
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
            'Define the times when you are more vulnerable so the app can become more proactive.',
            style: AppTypography.muted,
          ),
          const SizedBox(height: AppSpacing.lg),
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
                  title: const Text('Enable Reminder Prep'),
                  subtitle: const Text(
                    'Stores your preference now so notification wiring can be added cleanly later.',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<int>(
                  initialValue: _settings.leadMinutes,
                  decoration: const InputDecoration(
                    labelText: 'Lead Time',
                    border: OutlineInputBorder(),
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
