class ReminderSettings {
  final bool remindersEnabled;
  final int leadMinutes;

  const ReminderSettings({
    required this.remindersEnabled,
    required this.leadMinutes,
  });

  factory ReminderSettings.defaults() {
    return const ReminderSettings(
      remindersEnabled: true,
      leadMinutes: 10,
    );
  }

  ReminderSettings copyWith({
    bool? remindersEnabled,
    int? leadMinutes,
  }) {
    return ReminderSettings(
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      leadMinutes: leadMinutes ?? this.leadMinutes,
    );
  }
}
