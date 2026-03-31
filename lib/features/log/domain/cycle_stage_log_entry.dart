import '../../cycle/domain/cycle_stage.dart';

class CycleStageLogEntry {
  final DateTime timestamp;
  final CycleStage stage;
  final int intensity;
  final String note;

  const CycleStageLogEntry({
    required this.timestamp,
    required this.stage,
    required this.intensity,
    required this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'stage': stage.name,
      'intensity': intensity,
      'note': note,
    };
  }

  factory CycleStageLogEntry.fromMap(Map<String, dynamic> map) {
    return CycleStageLogEntry(
      timestamp: DateTime.parse(map['timestamp'] as String),
      stage: CycleStage.values.byName(map['stage'] as String),
      intensity: (map['intensity'] as num).toInt(),
      note: (map['note'] as String?) ?? '',
    );
  }
}
