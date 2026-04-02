enum RecoveryEventType {
  urge,
  relapse,
  victory,
}

extension RecoveryEventTypeX on RecoveryEventType {
  String get label {
    switch (this) {
      case RecoveryEventType.urge:
        return 'Urge';
      case RecoveryEventType.relapse:
        return 'Relapse';
      case RecoveryEventType.victory:
        return 'Victory';
    }
  }
}

class RecoveryEventEntry {
  final DateTime timestamp;
  final RecoveryEventType type;
  final int intensity;
  final String context;
  final String note;

  const RecoveryEventEntry({
    required this.timestamp,
    required this.type,
    required this.intensity,
    required this.context,
    required this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'intensity': intensity,
      'context': context,
      'note': note,
    };
  }

  factory RecoveryEventEntry.fromMap(Map<String, dynamic> map) {
    return RecoveryEventEntry(
      timestamp: DateTime.tryParse((map['timestamp'] as String?) ?? '') ??
          DateTime.now(),
      type: (map['type'] as String?) != null
          ? RecoveryEventType.values.byName(map['type'] as String)
          : RecoveryEventType.urge,
      intensity: (map['intensity'] as num?)?.toInt() ?? 5,
      context: (map['context'] as String?) ?? '',
      note: (map['note'] as String?) ?? '',
    );
  }
}
