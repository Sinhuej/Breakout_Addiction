class MoodEntry {
  final DateTime timestamp;
  final String moodLabel;
  final int stress;
  final int loneliness;
  final int boredom;
  final int energy;
  final String note;

  const MoodEntry({
    required this.timestamp,
    required this.moodLabel,
    required this.stress,
    required this.loneliness,
    required this.boredom,
    required this.energy,
    required this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'moodLabel': moodLabel,
      'stress': stress,
      'loneliness': loneliness,
      'boredom': boredom,
      'energy': energy,
      'note': note,
    };
  }

  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      timestamp: DateTime.parse(map['timestamp'] as String),
      moodLabel: (map['moodLabel'] as String?) ?? 'Neutral',
      stress: (map['stress'] as num).toInt(),
      loneliness: (map['loneliness'] as num).toInt(),
      boredom: (map['boredom'] as num).toInt(),
      energy: (map['energy'] as num).toInt(),
      note: (map['note'] as String?) ?? '',
    );
  }
}
